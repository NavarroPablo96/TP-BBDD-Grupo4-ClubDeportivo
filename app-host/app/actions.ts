"use server";

import { revalidatePath } from "next/cache";
import { quoteName, runBatch, runScript, toDbError, type DbError } from "@/lib/db";
import { getTable } from "@/lib/schema";
import { PROCEDURES } from "@/lib/procedures";

type Values = Record<string, string>;
type Row = Record<string, unknown>;

export type ActionResult = {
  ok: boolean;
  message?: string;
  error?: DbError;
  /** Mensajes informativos (PRINT) que devolvió el motor. */
  messages?: string[];
  /** Result sets devueltos por un SP. */
  recordsets?: Row[][];
  /** Valores de parámetros OUTPUT. */
  outputs?: Row;
};

/** Sin validación en la app: todo valor vacío viaja como NULL y decide la base. */
const toParam = (value: string | undefined): string | null =>
  value === undefined || value === "" ? null : value;

function plain(rows: Row[]): Row[] {
  return rows.map((row) =>
    Object.fromEntries(
      Object.entries(row).map(([k, v]) => [k, v instanceof Date ? v.toISOString().slice(0, 10) : v]),
    ),
  );
}

async function attempt(
  work: () => Promise<Omit<ActionResult, "ok" | "error">>,
  revalidate?: string,
): Promise<ActionResult> {
  try {
    const result = await work();
    if (revalidate) revalidatePath(revalidate);
    return { ok: true, ...result };
  } catch (err) {
    return { ok: false, error: toDbError(err) };
  }
}

export type SqlConsoleResult = {
  outputs: { recordsets: Row[][]; messages: string[]; rowsAffected: number[] }[];
  error?: DbError;
  failedBatch?: number;
  rolledBack: boolean;
  totalBatches: number;
};

/** Separa el script en lotes por líneas que sólo contienen GO (como SSMS). */
function splitBatches(script: string): string[] {
  return script
    .split(/^\s*GO\s*(?:--.*)?$/gim)
    .map((b) => b.trim())
    .filter((b) => b.length > 0);
}

function plainAny(value: unknown): unknown {
  if (!(value instanceof Date)) return value;
  const iso = value.toISOString();
  if (iso.startsWith("1970-01-01")) return iso.slice(11, 19);
  return iso.endsWith("T00:00:00.000Z") ? iso.slice(0, 10) : iso.slice(0, 19).replace("T", " ");
}

/** Consola SQL libre: ejecuta lo que se escriba, sin ningún control de la app. */
export async function executeSql(script: string, rollback: boolean): Promise<SqlConsoleResult> {
  const batches = splitBatches(script);
  try {
    const res = await runScript(batches, rollback);
    if (!rollback) revalidatePath("/", "layout");
    return {
      outputs: res.outputs.map((o) => ({
        ...o,
        recordsets: o.recordsets.map((rs) =>
          rs.map((row) => Object.fromEntries(Object.entries(row).map(([k, v]) => [k, plainAny(v)]))),
        ),
      })),
      error: res.error,
      failedBatch: res.failedBatch,
      rolledBack: rollback,
      totalBatches: batches.length,
    };
  } catch (err) {
    return { outputs: [], error: toDbError(err), rolledBack: rollback, totalBatches: batches.length };
  }
}

export async function insertRow(tableName: string, values: Values): Promise<ActionResult> {
  return attempt(async () => {
    const table = await getTable(tableName);
    if (!table) throw new Error(`La tabla ${tableName} no existe.`);
    const cols = table.columns.filter((c) => !c.identity);
    const params = Object.fromEntries(cols.map((c, i) => [`v${i}`, toParam(values[c.name])]));
    const sqlText = `INSERT INTO ${quoteName(table.name)} (${cols.map((c) => quoteName(c.name)).join(", ")})
      VALUES (${cols.map((_, i) => `@v${i}`).join(", ")})`;
    await runBatch(sqlText, params);
    return { message: `Fila insertada en ${table.name}.` };
  }, `/tablas/${tableName}`);
}

function pkWhere(pk: Values, offset = 0): { clause: string; params: Record<string, unknown> } {
  const entries = Object.entries(pk);
  if (entries.length === 0) throw new Error("La tabla no tiene clave primaria.");
  return {
    clause: entries.map(([col], i) => `${quoteName(col)} = @w${i + offset}`).join(" AND "),
    params: Object.fromEntries(entries.map(([, v], i) => [`w${i + offset}`, v])),
  };
}

export async function updateRow(tableName: string, pk: Values, values: Values): Promise<ActionResult> {
  return attempt(async () => {
    const table = await getTable(tableName);
    if (!table) throw new Error(`La tabla ${tableName} no existe.`);
    const pkCols = table.columns.filter((c) => c.isPk).map((c) => c.name);
    const safePk = Object.fromEntries(pkCols.map((c) => [c, pk[c]]));
    const cols = table.columns.filter((c) => !c.identity);
    const sets = cols.map((c, i) => `${quoteName(c.name)} = @v${i}`).join(", ");
    const params: Record<string, unknown> = Object.fromEntries(cols.map((c, i) => [`v${i}`, toParam(values[c.name])]));
    const where = pkWhere(safePk);
    const res = await runBatch(`UPDATE ${quoteName(table.name)} SET ${sets} WHERE ${where.clause}`, {
      ...params,
      ...where.params,
    });
    return { message: `Fila actualizada en ${table.name}.`, messages: res.messages };
  }, `/tablas/${tableName}`);
}

export async function deleteRow(tableName: string, pk: Values): Promise<ActionResult> {
  return attempt(async () => {
    const table = await getTable(tableName);
    if (!table) throw new Error(`La tabla ${tableName} no existe.`);
    const pkCols = table.columns.filter((c) => c.isPk).map((c) => c.name);
    const where = pkWhere(Object.fromEntries(pkCols.map((c) => [c, pk[c]])));
    const res = await runBatch(`DELETE FROM ${quoteName(table.name)} WHERE ${where.clause}`, where.params);
    return { message: `Fila eliminada de ${table.name}.`, messages: res.messages };
  }, `/tablas/${tableName}`);
}

export async function executeProcedure(procName: string, values: Values): Promise<ActionResult> {
  return attempt(async () => {
    const proc = PROCEDURES.find((p) => p.name === procName);
    if (!proc) throw new Error(`Procedimiento desconocido: ${procName}`);
    const inputs = proc.params.filter((p) => !p.output);
    const outputs = proc.params.filter((p) => p.output);
    const declare = outputs.map((p) => `DECLARE @o_${p.name} INT;`).join("\n");
    const args = [
      ...inputs.map((p) => `@${p.name} = @i_${p.name}`),
      ...outputs.map((p) => `@${p.name} = @o_${p.name} OUTPUT`),
    ].join(", ");
    const select = outputs.length
      ? `SELECT ${outputs.map((p) => `@o_${p.name} AS ${p.name}`).join(", ")};`
      : "";
    const params = Object.fromEntries(inputs.map((p) => [`i_${p.name}`, toParam(values[p.name])]));
    const res = await runBatch(`${declare}\nEXEC ${proc.name} ${args};\n${select}`, params);
    const sets = res.recordsets.map(plain);
    const outputRow = outputs.length ? sets.pop()?.[0] : undefined;
    return {
      message: `${proc.name} ejecutado correctamente.`,
      messages: res.messages,
      recordsets: sets,
      outputs: outputRow,
    };
  }, "/");
}
