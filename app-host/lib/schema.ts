import "server-only";
import { query, quoteName } from "./db";

export type ColumnMeta = {
  name: string;
  type: string;
  nullable: boolean;
  identity: boolean;
  isPk: boolean;
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

/** Metadatos de todas las tablas de usuario, leídos de la propia base. */
export async function loadSchema(): Promise<TableMeta[]> {
  const rows = await query<MetaRow>(`
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
    ORDER BY t.name, c.column_id`);
  const byTable = new Map<string, ColumnMeta[]>();
  for (const r of rows) {
    const cols = byTable.get(r.tabla) ?? [];
    cols.push({ name: r.columna, type: r.tipo, nullable: r.nullable, identity: r.identidad, isPk: r.es_pk });
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
