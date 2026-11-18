"use client";

import { useState, useTransition } from "react";
import { executeProcedure, type ActionResult } from "@/app/actions";
import type { ProcDef } from "@/lib/procedures";
import { DataTable } from "./DataTable";
import { ResultBanner } from "./ResultBanner";
import { SuggestInput } from "./SuggestInput";
import type { Option } from "@/lib/types";

/** Calendario y selector de hora nativos; el resto, texto libre (sin validar). */
const inputType = (t: string): string => (t === "date" || t === "time" ? t : "text");

export function ProcedureForm({ proc, options }: { proc: ProcDef; options: Record<string, Option[]> }) {
  const [values, setValues] = useState<Record<string, string>>({});
  const [result, setResult] = useState<ActionResult | null>(null);
  const [pending, startTransition] = useTransition();

  return (
    <section className="rounded-xl border border-line bg-card p-4 shadow-sm">
      <h2 className="font-semibold">{proc.title}</h2>
      <p className="font-mono text-xs text-muted">{proc.name}</p>
      <p className="mt-1 text-sm text-muted">{proc.description}</p>
      <form
        className="mt-3"
        onSubmit={(e) => {
          e.preventDefault();
          startTransition(async () => setResult(await executeProcedure(proc.name, values)));
        }}
      >
        <div className="grid gap-3 sm:grid-cols-2">
          {proc.params.filter((p) => !p.output).map((p) => (
            <label key={p.name} className="text-xs font-medium text-muted">
              {p.label}
              {p.optional && <span className="ml-1 font-normal">(opcional)</span>}
              <SuggestInput
                id={`${proc.name}-${p.name}`}
                type={inputType(p.type)}
                value={values[p.name] ?? ""}
                onChange={(v) => setValues({ ...values, [p.name]: v })}
                placeholder={p.placeholder ?? p.type}
                options={options[p.name]}
              />
            </label>
          ))}
        </div>
        <button disabled={pending} className="mt-4 rounded-md bg-brand px-4 py-1.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50">
          {pending ? "Ejecutando…" : "Ejecutar"}
        </button>
      </form>
      <div className="mt-3 space-y-3">
        <ResultBanner result={result} />
        {result?.ok && result.outputs && (
          <p className="text-sm">
            Valores de salida:{" "}
            {Object.entries(result.outputs).map(([k, v]) => (
              <code key={k} className="mr-2 rounded bg-brand-soft px-1.5 py-0.5">{k} = {String(v)}</code>
            ))}
          </p>
        )}
        {result?.ok &&
          result.recordsets?.map((rs, i) => (
            <DataTable key={i} columns={rs[0] ? Object.keys(rs[0]) : []} rows={rs} />
          ))}
      </div>
    </section>
  );
}
