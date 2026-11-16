import "server-only";
import { query, quoteName } from "./db";
import { parseDomain } from "./domains";
import { PROCEDURES } from "./procedures";
import type { Option } from "./types";

export type ColumnMeta = {
  name: string;
  type: string;
  nullable: boolean;
  identity: boolean;
  isPk: boolean;
  /** Valores permitidos si un CHECK de una sola columna define un dominio cerrado. */
  domain?: string[];
  /** Columna padre de la clave foránea (se prefiere la FK simple sobre la compuesta). */
  fk?: { table: string; column: string };
};

export type TableMeta = { name: string; columns: ColumnMeta[] };

export { TABLE_GROUPS } from "./groups";

type MetaRow = {
  tabla: string;
  columna: string;
  tipo: string;
  nullable: boolean;
  identidad: boolean;
  es_pk: boolean;
};
type FkRow = { tabla: string; columna: string; padre: string; col_padre: string; n: number };
type CheckRow = { tabla: string; definicion: string };

/** Metadatos de todas las tablas de usuario, leídos de la propia base. */
export async function loadSchema(): Promise<TableMeta[]> {
  const [rows, fks, checks] = await Promise.all([
    query<MetaRow>(`
      SELECT t.name AS tabla, c.name AS columna, ty.name AS tipo,
             c.is_nullable AS nullable, c.is_identity AS identidad,
             CAST(CASE WHEN EXISTS (
               SELECT 1 FROM sys.indexes i
               JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
               WHERE i.object_id = t.object_id AND i.is_primary_key = 1 AND ic.column_id = c.column_id
             ) THEN 1 ELSE 0 END AS BIT) AS es_pk
      FROM sys.tables t
      JOIN sys.columns c ON c.object_id = t.object_id
      JOIN sys.types ty ON ty.user_type_id = c.user_type_id
      ORDER BY t.name, c.column_id`),
    query<FkRow>(`
      SELECT OBJECT_NAME(fkc.parent_object_id) AS tabla, pc.name AS columna,
             OBJECT_NAME(fkc.referenced_object_id) AS padre, rc.name AS col_padre,
             (SELECT COUNT(*) FROM sys.foreign_key_columns x
              WHERE x.constraint_object_id = fkc.constraint_object_id) AS n
      FROM sys.foreign_key_columns fkc
      JOIN sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
      JOIN sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id`),
    query<CheckRow>(`SELECT OBJECT_NAME(parent_object_id) AS tabla, definition AS definicion FROM sys.check_constraints`),
  ]);

  const domains = new Map<string, string[]>();
  for (const ck of checks) {
    const domain = parseDomain(ck.definicion);
    if (domain) domains.set(`${ck.tabla}.${domain.column}`, domain.values);
  }

  const fkByColumn = new Map<string, FkRow>();
  for (const fk of [...fks].sort((a, b) => b.n - a.n)) fkByColumn.set(`${fk.tabla}.${fk.columna}`, fk); // la FK simple (n = 1) queda última y gana

  const byTable = new Map<string, ColumnMeta[]>();
  for (const r of rows) {
    const key = `${r.tabla}.${r.columna}`;
    const fk = fkByColumn.get(key);
    const cols = byTable.get(r.tabla) ?? [];
    cols.push({
      name: r.columna,
      type: r.tipo,
      nullable: r.nullable,
      identity: r.identidad,
      isPk: r.es_pk,
      domain: domains.get(key),
      fk: fk ? { table: fk.padre, column: fk.col_padre } : undefined,
    });
    byTable.set(r.tabla, cols);
  }
  return [...byTable.entries()].map(([name, columns]) => ({ name, columns }));
}

/** Devuelve la tabla sólo si existe en la base (lista blanca para nombres dinámicos). */
export async function getTable(name: string): Promise<TableMeta | null> {
  const tables = await loadSchema();
  return tables.find((t) => t.name === name) ?? null;
}

/** Expresión SELECT que deja fechas y horas como texto ISO para el formulario. */
export function selectExpr(col: ColumnMeta): string {
  const q = quoteName(col.name);
  if (col.type === "date") return `CONVERT(VARCHAR(10), ${q}, 23) AS ${q}`;
  if (col.type === "time") return `CONVERT(VARCHAR(8), ${q}, 108) AS ${q}`;
  if (col.type === "datetime" || col.type === "datetime2") return `CONVERT(VARCHAR(19), ${q}, 120) AS ${q}`;
  return q;
}

// --- Sugerencias (datalist) ---------------------------------------------------------------

const OPTION_LIMIT = 200;

/** Etiqueta descriptiva según el nombre de la columna padre (`p` es la tabla padre). */
const LABEL_BY_COLUMN: Record<string, string> = {
  nro_socio_base: `(SELECT TOP 1 s.nombre FROM SOCIO s WHERE s.nro_socio_base = p.nro_socio_base AND s.nro_orden = 0)`,
  cod_actividad: `(SELECT TOP 1 a.nombre FROM ACTIVIDAD a WHERE a.cod_actividad = p.cod_actividad)`,
  dni: `(SELECT TOP 1 pr.nombre FROM PROFESIONAL pr WHERE pr.dni = p.dni)`,
  cod_area: `(SELECT TOP 1 ar.ubicacion FROM AREA ar WHERE ar.cod_area = p.cod_area)`,
  cod_dictado: `(SELECT TOP 1 a.nombre FROM DICTADO d JOIN ACTIVIDAD a ON a.cod_actividad = d.cod_actividad WHERE d.cod_dictado = p.cod_dictado)`,
};

const text = (v: unknown): string => (v instanceof Date ? v.toISOString().slice(0, 10) : String(v));

/** Opciones sugeridas para una columna: su dominio cerrado o los valores de la tabla padre. */
export async function optionsForColumn(col: ColumnMeta): Promise<Option[]> {
  if (col.type === "date" || col.type === "time") return []; // ya usan calendario / selector de hora
  if (col.domain) return col.domain.map((value) => ({ value }));
  if (!col.fk) return [];
  const parentCol = quoteName(col.fk.column);
  const label = LABEL_BY_COLUMN[col.fk.column] ?? "NULL";
  const rows = await query<{ v: unknown; label: string | null }>(`
    SELECT TOP ${OPTION_LIMIT} v, label FROM (
      SELECT DISTINCT p.${parentCol} AS v, ${label} AS label FROM ${quoteName(col.fk.table)} p
    ) x ORDER BY v`);
  return rows.map((r) => ({ value: text(r.v), label: r.label ?? undefined }));
}

/** Sugerencias de cada columna editable de una tabla, por nombre de columna. */
export async function loadTableOptions(table: TableMeta): Promise<Record<string, Option[]>> {
  const cols = table.columns.filter((c) => !c.identity && (c.domain || c.fk));
  const entries = await Promise.all(cols.map(async (c) => [c.name, await optionsForColumn(c)] as const));
  return Object.fromEntries(entries.filter(([, opts]) => opts.length > 0));
}

/** Sugerencias de los parámetros de cada SP (según `source` en lib/procedures.ts). */
export async function loadProcedureOptions(): Promise<Record<string, Record<string, Option[]>>> {
  const tables = await loadSchema();
  const result: Record<string, Record<string, Option[]>> = {};
  for (const proc of PROCEDURES) {
    const entries = await Promise.all(
      proc.params
        .filter((p) => p.source)
        .map(async (p) => {
          const col = tables.find((t) => t.name === p.source!.table)?.columns.find((c) => c.name === p.source!.column);
          return [p.name, col ? await optionsForColumn(col) : []] as const;
        }),
    );
    result[proc.name] = Object.fromEntries(entries.filter(([, opts]) => opts.length > 0));
  }
  return result;
}
