import type { ActionResult } from "@/app/actions";

export function ResultBanner({ result }: { result: ActionResult | null }) {
  if (!result) return null;
  if (!result.ok) {
    return (
      <div role="alert" className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
        <p className="font-semibold">
          Rechazado por la base{result.error?.number ? ` · error ${result.error.number}` : ""}
        </p>
        <p className="mt-1 whitespace-pre-wrap font-mono text-xs">{result.error?.message}</p>
      </div>
    );
  }
  return (
    <div role="status" className="rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-800">
      <p className="font-semibold">✓ {result.message}</p>
      {result.messages?.map((m, i) => (
        <p key={i} className="mt-1 font-mono text-xs">{m}</p>
      ))}
    </div>
  );
}
