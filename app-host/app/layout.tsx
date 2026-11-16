import type { Metadata } from "next";
import "./globals.css";
import { Nav } from "@/components/Nav";
import { loadSchema } from "@/lib/schema";
import { TABLE_GROUPS } from "@/lib/groups";
import { connection } from "next/server";

export const metadata: Metadata = {
  title: "Club Deportivo · Host",
  description: "Aplicación host para interactuar con la base ClubDeportivo (SQL Server).",
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  await connection();
  let tables: string[] = [];
  try {
    tables = (await loadSchema()).map((t) => t.name);
  } catch {
    // Sin conexión: la página mostrará el error; la navegación usa los nombres conocidos.
    tables = TABLE_GROUPS.flatMap((g) => g.tables);
  }
  return (
    <html lang="es">
      <body className="min-h-screen md:flex">
        <Nav tables={tables} />
        <main className="flex-1 min-w-0 p-5 md:p-8">{children}</main>
      </body>
    </html>
  );
}
