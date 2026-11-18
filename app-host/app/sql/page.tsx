import { SqlConsole } from "@/components/SqlConsole";

export default function SqlPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <header>
        <h1 className="text-xl font-bold">Consola SQL</h1>
        <p className="text-sm text-muted">
          Ejecuta T-SQL libre sobre <code>ClubDeportivo</code>, sin controles de la app. Por defecto todo corre en una
          transacción que se deshace, para probar triggers y constraints sin ensuciar los datos.
        </p>
      </header>
      <SqlConsole />
    </div>
  );
}
