import "server-only";
import sql from "mssql/msnodesqlv8";

const DEFAULT_CONNECTION_STRING =
  "Driver={ODBC Driver 17 for SQL Server};Data Source=(localdb)\\MSSQLLocalDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False";

type Row = Record<string, unknown>;

const globalForDb = globalThis as unknown as { __clubPool?: Promise<sql.ConnectionPool> };

function getPool(): Promise<sql.ConnectionPool> {
  if (!globalForDb.__clubPool) {
    const pool = new sql.ConnectionPool({
      connectionString: process.env.DB_CONNECTION_STRING ?? DEFAULT_CONNECTION_STRING,
    } as unknown as sql.config);
    globalForDb.__clubPool = pool.connect().catch((err) => {
      globalForDb.__clubPool = undefined;
      throw err;
    });
  }
  return globalForDb.__clubPool;
}

/** Ejecuta un lote T-SQL con parámetros nombrados (`@nombre`). */
export async function runBatch(
  text: string,
  params: Record<string, unknown> = {},
): Promise<{ recordsets: Row[][]; messages: string[] }> {
  const pool = await getPool();
  const request = pool.request();
  const messages: string[] = [];
  request.on("info", (info: { message: string }) => messages.push(cleanSqlMessage(info.message)));
  for (const [name, value] of Object.entries(params)) request.input(name, value);
  const result = await request.query(text);
  return { recordsets: result.recordsets as unknown as Row[][], messages };
}

export type BatchOutput = { recordsets: Row[][]; messages: string[]; rowsAffected: number[] };

/**
 * Ejecuta lotes en orden y corta en el primer error. Con `rollback` corre todo en una
 * transacción que siempre se deshace (permite probar triggers sin dejar datos).
 */
export async function runScript(
  batches: string[],
  rollback: boolean,
): Promise<{ outputs: BatchOutput[]; error?: DbError; failedBatch?: number }> {
  const pool = await getPool();
  const tx = rollback ? new sql.Transaction(pool) : null;
  if (tx) await tx.begin();
  const outputs: BatchOutput[] = [];
  let failure: { error: DbError; failedBatch: number } | undefined;
  for (const [i, text] of batches.entries()) {
    const request = tx ? tx.request() : pool.request();
    const messages: string[] = [];
    request.on("info", (info: { message: string }) => messages.push(cleanSqlMessage(info.message)));
    try {
      const result = await request.query(text);
      outputs.push({
        recordsets: result.recordsets as unknown as Row[][],
        messages,
        rowsAffected: result.rowsAffected,
      });
    } catch (err) {
      outputs.push({ recordsets: [], messages, rowsAffected: [] });
      failure = { error: toDbError(err), failedBatch: i };
      break;
    }
  }
  // Si el script ya cerró la transacción por su cuenta, el rollback puede fallar: se ignora.
  if (tx) await tx.rollback().catch(() => undefined);
  return { outputs, ...failure };
}

export async function query<T extends Row = Row>(
  text: string,
  params: Record<string, unknown> = {},
): Promise<T[]> {
  const { recordsets } = await runBatch(text, params);
  return (recordsets[0] ?? []) as T[];
}

/** Quita el prefijo `[Microsoft][ODBC Driver ...][SQL Server]` del mensaje. */
export function cleanSqlMessage(message: string): string {
  return message.replace(/^(\[[^\]]*\])+\s*/, "");
}

export type DbError = { number: number | null; message: string };

/** Normaliza un error de SQL Server (THROW, CHECK, FK, conversión...) para mostrarlo tal cual. */
export function toDbError(err: unknown): DbError {
  const e = err as { number?: number; message?: string; originalError?: { info?: { number?: number } } };
  const number = e.number ?? e.originalError?.info?.number ?? null;
  return { number, message: cleanSqlMessage(e.message ?? String(err)) };
}

/** Identificador entre corchetes; sólo para nombres que vienen de los metadatos de la base. */
export function quoteName(name: string): string {
  return `[${name.replace(/]/g, "]]")}]`;
}
