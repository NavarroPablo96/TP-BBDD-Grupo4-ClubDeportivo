import Link from "next/link";
import { connection } from "next/server";
import { query } from "@/lib/db";
import { TABLE_GROUPS } from "@/lib/groups";
import { toDbError } from "@/lib/db";

type Count = { tabla: string; filas: number };

export default async function Home() {
  await connection();
  let counts = new Map<string, number>();
  let error: string | null = null;
  try {
    const rows = await query<Count>(`
      SELECT t.name AS tabla, CAST(SUM(p.rows) AS INT) AS filas
      FROM sys.tables t JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
      GROUP BY t.name`);
    counts = new Map(rows.map((r) => [r.tabla, r.filas]));
  } catch (e) {
    error = toDbError(e).message;
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <header className="rounded-2xl bg-gradient-to-r from-indigo-600 to-fuchsia-600 p-6 text-white shadow-lg">
        <h1 className="text-2xl font-bold">Club Deportivo</h1>
        <p className="mt-1 max-w-2xl text-sm text-indigo-100">
          Host para operar la base <code className="rounded bg-white/20 px-1">ClubDeportivo</code> en SQL Server.
          Los formularios no validan: lo que se carga llega a la base y los triggers, constraints y SP deciden.
        </p>
        <div className="mt-4 flex flex-wrap gap-2 text-sm font-semibold">
          <Link href="/consultas" className="rounded-lg bg-white px-3 py-1.5 text-indigo-700 hover:bg-indigo-50">Consultas y vistas</Link>
          <Link href="/procedimientos" className="rounded-lg bg-white/20 px-3 py-1.5 hover:bg-white/30">Procedimientos</Link>
        </div>
      </header>

      {error && (
        <div role="alert" className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
          No se pudo conectar a la base: <span className="font-mono text-xs">{error}</span>
        </div>
      )}

      {TABLE_GROUPS.map((g) => (
        <section key={g.title}>
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wide text-muted">{g.title}</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {g.tables.map((t) => (
              <Link
                key={t}
                href={`/tablas/${t}`}
                className="group rounded-xl border border-line bg-card p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-brand hover:shadow-md"
              >
                <p className="font-mono text-sm font-semibold group-hover:text-brand">{t}</p>
                <p className="mt-1 text-2xl font-bold">{counts.get(t) ?? "–"}<span className="ml-1 text-xs font-normal text-muted">filas</span></p>
              </Link>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
