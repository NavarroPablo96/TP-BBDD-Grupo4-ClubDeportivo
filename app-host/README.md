# App host · Club Deportivo

Next.js (App Router) + Tailwind sobre SQL Server. Documentación de features: [../docs/APP_HOST_FEATURES.md](../docs/APP_HOST_FEATURES.md).

## Requisitos

- Base `ClubDeportivo` creada con los scripts `00` a `05` (ver README de la raíz).
- Node 20+ y ODBC Driver 17/18 para SQL Server (Windows, LocalDB).

## Uso

```bash
npm install
cp .env.example .env.local   # ajustar DB_CONNECTION_STRING si hace falta
npm run dev                  # http://localhost:3000
```

Otros comandos: `npm run build`, `npm run lint`.

## Estructura

- `app/` páginas (`/`, `/tablas/[tabla]`, `/consultas`, `/procedimientos`) y server actions (`app/actions.ts`).
- `lib/db.ts` conexión (pool único) y manejo de errores de SQL Server.
- `lib/schema.ts` metadatos de tablas leídos de la base. `lib/groups.ts` agrupación de tablas para la navegación.
- `lib/procedures.ts` definición de los SP y las vistas que expone la app.
- `components/` tabla, formularios y banners.
