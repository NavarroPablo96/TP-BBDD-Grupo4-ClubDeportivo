import { connection } from "next/server";
import { query, toDbError } from "@/lib/db";
import { VIEWS } from "@/lib/procedures";
import { DataTable } from "@/components/DataTable";

export default async function ConsultasPage() {
  await connection();
  const results = await Promise.all(
    VIEWS.map(async (v) => {
      try {
        const rows = await query(`SELECT * FROM ${v.name}`);
        return { ...v, rows, error: null as string | null };
      } catch (e) {
        return { ...v, rows: [], error: toDbError(e).message };
      }
    }),
  );

  return (
    <div className="mx-auto max-w-5xl space-y-8">
      <header>
        <h1 className="text-xl font-bold">Consultas y vistas</h1>
        <p className="text-sm text-muted">Resultado actual de las vistas del enunciado.</p>
      </header>
      {results.map((r) => (
        <section key={r.name} className="space-y-2">
          <div>
            <h2 className="font-semibold">{r.title}</h2>
            <p className="font-mono text-xs text-muted">{r.name}</p>
            <p className="text-sm text-muted">{r.description}</p>
          </div>
          {r.error ? (
            <p role="alert" className="rounded-lg bg-red-50 p-3 font-mono text-xs text-red-800">{r.error}</p>
          ) : (
            <DataTable
              columns={r.rows[0] ? Object.keys(r.rows[0]) : []}
              rows={r.rows}
              empty="La vista no devuelve filas con los datos actuales."
            />
          )}
        </section>
      ))}
    </div>
  );
}
