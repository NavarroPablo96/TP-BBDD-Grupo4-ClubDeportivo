"use client";

import { useState, useTransition } from "react";
import { deleteRow, insertRow, updateRow, type ActionResult } from "@/app/actions";
import { DataTable } from "./DataTable";
import { ResultBanner } from "./ResultBanner";
import { SuggestInput } from "./SuggestInput";
import type { Option } from "@/lib/types";

type Column = { name: string; type: string; nullable: boolean; identity: boolean; isPk: boolean };
type Row = Record<string, unknown>;

const toText = (v: unknown): string => (v === null || v === undefined ? "" : String(v));

function inputHint(c: Column): string {
  return c.type;
}

/** Calendario y selector de hora nativos para date/time; el resto, texto libre. */
function inputKind(c: Column): "date" | "time" | "text" {
  return c.type === "date" || c.type === "time" ? c.type : "text";
}

export function TableManager({
  table,
  columns,
  rows,
  options,
}: {
  table: string;
  columns: Column[];
  rows: Row[];
  options: Record<string, Option[]>;
}) {
  const [values, setValues] = useState<Record<string, string>>({});
  const [editing, setEditing] = useState<Record<string, string> | null>(null);
  const [result, setResult] = useState<ActionResult | null>(null);
  const [pending, startTransition] = useTransition();

  const pkOf = (row: Row) => Object.fromEntries(columns.filter((c) => c.isPk).map((c) => [c.name, toText(row[c.name])]));
  const formCols = columns.filter((c) => !c.identity);

  function run(action: () => Promise<ActionResult>, onOk?: () => void) {
    startTransition(async () => {
      const res = await action();
      setResult(res);
      if (res.ok) onOk?.();
    });
  }

  function startEdit(row: Row) {
    setEditing(pkOf(row));
    setValues(Object.fromEntries(columns.map((c) => [c.name, toText(row[c.name])])));
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function reset() {
    setEditing(null);
    setValues({});
  }

  return (
    <div className="space-y-4">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          run(() => (editing ? updateRow(table, editing, values) : insertRow(table, values)), reset);
        }}
        className="rounded-xl border border-line bg-card p-4 shadow-sm"
      >
        <h2 className="mb-3 text-sm font-semibold">
          {editing ? "Editar fila" : "Nueva fila"}
        </h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {formCols.map((c) => (
            <label key={c.name} className="text-xs font-medium text-muted">
              <span className="flex items-center gap-1">
                {c.name}
                {c.isPk && <span className="rounded bg-amber-100 px-1 text-[10px] text-amber-800">PK</span>}
              </span>
              <SuggestInput
                id={`${table}-${c.name}`}
                type={inputKind(c)}
                step={c.type === "time" ? 1 : undefined}
                value={values[c.name] ?? ""}
                onChange={(v) => setValues({ ...values, [c.name]: v })}
                placeholder={inputHint(c)}
                options={options[c.name]}
              />
            </label>
          ))}
        </div>
        <div className="mt-4 flex gap-2">
          <button disabled={pending} className="rounded-md bg-brand px-4 py-1.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50">
            {pending ? "Enviando…" : editing ? "Guardar cambios" : "Insertar"}
          </button>
          {editing && (
            <button type="button" onClick={reset} className="rounded-md border border-line px-4 py-1.5 text-sm">
              Cancelar
            </button>
          )}
        </div>
      </form>

      <ResultBanner result={result} />

      <DataTable
        columns={columns.map((c) => c.name)}
        rows={rows}
        actions={(row) => (
          <span className="space-x-2">
            <button onClick={() => startEdit(row)} className="text-xs font-semibold text-brand hover:underline">
              Editar
            </button>
            <button
              onClick={() => {
                if (confirm("¿Eliminar la fila? La base puede rechazarlo.")) run(() => deleteRow(table, pkOf(row)));
              }}
              className="text-xs font-semibold text-red-600 hover:underline"
            >
              Eliminar
            </button>
          </span>
        )}
      />
    </div>
  );
}
