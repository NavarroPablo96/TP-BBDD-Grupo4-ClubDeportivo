import { PROCEDURES } from "@/lib/procedures";
import { ProcedureForm } from "@/components/ProcedureForm";

export default function ProcedimientosPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-5">
      <header>
        <h1 className="text-xl font-bold">Procedimientos almacenados</h1>
        <p className="text-sm text-muted">
          Los valores vacíos se envían como NULL. Los errores de triggers y constraints se muestran tal cual.
        </p>
      </header>
      <div className="grid gap-5 lg:grid-cols-2">
        {PROCEDURES.map((p) => (
          <ProcedureForm key={p.name} proc={p} />
        ))}
      </div>
    </div>
  );
}
