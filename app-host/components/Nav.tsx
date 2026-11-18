"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { TABLE_GROUPS } from "@/lib/groups";


function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  const pathname = usePathname();
  const active = pathname === href;
  return (
    <Link
      href={href}
      className={`block rounded-md px-3 py-1.5 text-sm transition-colors ${
        active ? "bg-white/15 font-semibold text-white" : "text-indigo-100 hover:bg-white/10"
      }`}
    >
      {children}
    </Link>
  );
}

export function Nav({ tables }: { tables: string[] }) {
  const known = new Set(tables);
  return (
    <aside className="bg-gradient-to-b from-indigo-700 to-indigo-900 p-4 md:sticky md:top-0 md:h-screen md:w-64 md:shrink-0 md:overflow-y-auto">
      <Link href="/" className="mb-5 flex items-center gap-2 text-white">
        <span className="grid h-9 w-9 place-items-center rounded-lg bg-white/15 text-lg">🏟️</span>
        <span className="leading-tight">
          <span className="block font-bold">Club Deportivo</span>
          <span className="block text-xs text-indigo-200">Grupo 4 · Host</span>
        </span>
      </Link>
      <nav className="space-y-1">
        <NavLink href="/">Inicio</NavLink>
        <NavLink href="/consultas">Consultas y vistas</NavLink>
        <NavLink href="/procedimientos">Procedimientos</NavLink>
        <NavLink href="/sql">Consola SQL</NavLink>
      </nav>
      {TABLE_GROUPS.map((g) => (
        <div key={g.title} className="mt-5">
          <p className="mb-1 px-3 text-[11px] font-semibold uppercase tracking-wider text-indigo-300">{g.title}</p>
          {g.tables.filter((t) => known.has(t) || known.size === 0).map((t) => (
            <NavLink key={t} href={`/tablas/${t}`}>{t}</NavLink>
          ))}
        </div>
      ))}
    </aside>
  );
}
