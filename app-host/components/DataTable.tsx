type Row = Record<string, unknown>;

function fmt(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value);
}

export function DataTable({
  columns,
  rows,
  actions,
  empty = "Sin filas.",
}: {
  columns: string[];
  rows: Row[];
  actions?: (row: Row, index: number) => React.ReactNode;
  empty?: string;
}) {
  return (
    <div className="overflow-x-auto rounded-xl border border-line bg-card shadow-sm">
      <table className="w-full text-left text-sm">
        <thead className="bg-brand-soft text-xs uppercase tracking-wide text-muted">
          <tr>
            {columns.map((c) => (
              <th key={c} className="whitespace-nowrap px-3 py-2 font-semibold">{c}</th>
            ))}
            {actions && <th className="px-3 py-2" />}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr><td colSpan={columns.length + 1} className="px-3 py-6 text-center text-muted">{empty}</td></tr>
          )}
          {rows.map((row, i) => (
            <tr key={i} className="border-t border-line hover:bg-slate-50">
              {columns.map((c) => (
                <td key={c} className="whitespace-nowrap px-3 py-2">
                  {row[c] === null ? <span className="text-slate-300">NULL</span> : fmt(row[c])}
                </td>
              ))}
              {actions && <td className="whitespace-nowrap px-3 py-2 text-right">{actions(row, i)}</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
