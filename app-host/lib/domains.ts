export type Domain = { column: string; values: string[] };

const EQUALITY = /\[\w+\]=(?:'([^']*)'|\((-?\d+)\))/g;
const RANGE = /^\(\[(\w+)\]>=\((-?\d+)\) AND \[\w+\]<=\((-?\d+)\)\)$/;
const MAX_RANGE = 31;

/**
 * Extrae el dominio cerrado de un CHECK de una sola columna, tal como lo guarda SQL Server:
 * `IN (...)` queda como cadena de `[c]=valor OR ...` y `BETWEEN` como `>= AND <=`.
 * Devuelve null si el CHECK relaciona varias columnas o no es una lista cerrada.
 */
export function parseDomain(definition: string): Domain | null {
  const range = RANGE.exec(definition.trim());
  if (range) {
    const [from, to] = [Number(range[2]), Number(range[3])];
    if (to < from || to - from + 1 > MAX_RANGE) return null;
    return { column: range[1], values: Array.from({ length: to - from + 1 }, (_, i) => String(from + i)) };
  }

  const columns = new Set([...definition.matchAll(/\[(\w+)\]/g)].map((m) => m[1]));
  if (columns.size !== 1) return null;
  const matches = [...definition.matchAll(EQUALITY)];
  if (matches.length === 0) return null;
  const leftover = definition.replace(EQUALITY, "").replace(/[()\s]|OR/g, "");
  if (leftover !== "") return null;

  const values = matches.map((m) => m[1] ?? m[2]);
  const numeric = values.every((v) => /^-?\d+$/.test(v));
  const sorted = [...values].sort((a, b) => (numeric ? Number(a) - Number(b) : a.localeCompare(b)));
  return { column: [...columns][0], values: sorted };
}
