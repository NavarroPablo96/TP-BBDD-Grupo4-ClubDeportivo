import { notFound } from "next/navigation";
import { connection } from "next/server";
import { query, quoteName, toDbError } from "@/lib/db";
import { getTable, selectExpr } from "@/lib/schema";
import { TableManager } from "@/components/TableManager";

const ROW_LIMIT = 500;

export default async function TablePage({ params }: { params: Promise<{ tabla: string }> }) {
  await connection();
  const { tabla } = await params;
  const table = await getTable(decodeURIComponent(tabla));
  if (!table) notFound();

  const order = table.columns.filter((c) => c.isPk).map((c) => quoteName(c.name)).join(", ") || "(SELECT NULL)";
  let rows: Record<string, unknown>[] = [];
  let error: string | null = null;
  try {
    rows = await query(
      `SELECT TOP ${ROW_LIMIT} ${table.columns.map(selectExpr).join(", ")} FROM ${quoteName(table.name)} ORDER BY ${order}`,
    );
  } catch (e) {
    error = toDbError(e).message;
  }

  return (
    <div className="mx-auto max-w-7xl space-y-4">
      <header>
        <h1 className="font-mono text-xl font-bold">{table.name}</h1>
        <p className="text-sm text-muted">
          {rows.length} filas{rows.length === ROW_LIMIT ? ` (mostrando las primeras ${ROW_LIMIT})` : ""} ·
          PK: {table.columns.filter((c) => c.isPk).map((c) => c.name).join(", ") || "—"}
        </p>
      </header>
      {error && <p role="alert" className="rounded-lg bg-red-50 p-3 font-mono text-xs text-red-800">{error}</p>}
      <TableManager table={table.name} columns={table.columns} rows={rows} />
    </div>
  );
}
