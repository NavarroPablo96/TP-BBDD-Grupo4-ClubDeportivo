"use client";

import { useState, useTransition } from "react";
import { executeSql, type SqlConsoleResult } from "@/app/actions";
import { DataTable } from "./DataTable";

const EXAMPLE = `-- Probá un trigger sin dejar datos (modo rollback):
EXEC SP_ALTA_GRUPO_FAMILIAR
  @telefono = '2235550000', @domicilio = 'Calle 1', @nombre_titular = 'Prueba',
  @fecha_nacimiento = '2015-01-01', @nombre_categoria = 'infantiles', @nro_socio_base = NULL;
GO
SELECT * FROM VW_TITULARES_DEUDA_ANIO_ACTUAL;`;

export function SqlConsole() {
  const [script, setScript] = useState("");
  const [rollback, setRollback] = useState(true);
  const [result, setResult] = useState<SqlConsoleResult | null>(null);
  const [pending, startTransition] = useTransition();

  function run() {
    if (!script.trim()) return;
    if (!rollback && !confirm("Modo con persistencia: los cambios se guardan en la base. ¿Ejecutar?")) return;
    startTransition(async () => setResult(await executeSql(script, rollback)));
  }

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-line bg-card p-4 shadow-sm">
        <textarea
          value={script}
          onChange={(e) => setScript(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();
              run();
            }
          }}
          spellCheck={false}
          rows={12}
          placeholder="Escribí T-SQL. Podés usar GO para separar lotes. Ctrl+Enter ejecuta."
          aria-label="Script T-SQL"
          className="w-full rounded-md border border-line bg-slate-50 p-3 font-mono text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        />
        <div className="mt-3 flex flex-wrap items-center gap-4">
          <button
            onClick={run}
            disabled={pending}
            className="rounded-md bg-brand px-4 py-1.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50"
          >
            {pending ? "Ejecutando…" : "Ejecutar (Ctrl+Enter)"}
          </button>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={rollback} onChange={(e) => setRollback(e.target.checked)} />
            Deshacer al terminar (transacción con ROLLBACK)
          </label>
          <button onClick={() => setScript(EXAMPLE)} className="text-xs font-semibold text-brand hover:underline">
            Cargar ejemplo
          </button>
        </div>
        {!rollback && (
          <p className="mt-2 text-xs font-semibold text-amber-700">
            Persistencia activada: INSERT, UPDATE, DELETE y DDL quedan guardados.
          </p>
        )}
      </div>

      {result && (
        <div className="space-y-3">
          {result.error && (
            <div role="alert" className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
              <p className="font-semibold">
                Rechazado por la base{result.error.number ? ` · error ${result.error.number}` : ""}
                {result.failedBatch !== undefined && ` · lote ${result.failedBatch + 1} de ${result.totalBatches}`}
              </p>
              <p className="mt-1 whitespace-pre-wrap font-mono text-xs">{result.error.message}</p>
            </div>
          )}
          {!result.error && (
            <p role="status" className="rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">
              ✓ {result.totalBatches} lote(s) ejecutado(s)
              {result.rolledBack ? " · cambios deshechos (ROLLBACK)" : ""}
            </p>
          )}
          {result.outputs.map((o, i) => (
            <div key={i} className="space-y-2">
              {result.totalBatches > 1 && <p className="text-xs font-semibold text-muted">Lote {i + 1}</p>}
              {o.messages.map((m, j) => (
                <p key={j} className="font-mono text-xs text-muted">{m}</p>
              ))}
              {o.recordsets.map((rs, j) => (
                <DataTable key={j} columns={rs[0] ? Object.keys(rs[0]) : []} rows={rs} empty="Sin filas." />
              ))}
              {o.recordsets.length === 0 && o.rowsAffected.length > 0 && (
                <p className="text-xs text-muted">Filas afectadas: {o.rowsAffected.join(", ")}</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
