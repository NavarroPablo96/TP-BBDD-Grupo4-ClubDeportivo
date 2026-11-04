# TP-BBDD-Grupo4-ClubDeportivo

### Herramientas utilizadas
- SQL Server en el siguiente link
- https://www.microsoft.com/es-ar/sql-server/sql-server-downloads
- Ahí descargar la opción "Descargar la edición Enterprise Developer"

- SSMS, cuando se termina de descargar SQL Server te solicita instalar SSMS del siguiente link:
    - https://learn.microsoft.com/es-es/ssms/install/install?redirectedfrom=MSDN


### Estructura del repositorio
- `scripts/`: scripts T-SQL, en orden de ejecución (`00` a `05`).
- `docs/`: resolución del grupo, pendientes de diseño y spec de estado (`SPEC_ESTADO.md`).
- `docs/referencias/`: enunciado, apunte de la cátedra y bibliografía.

### Ejecución
Ejecutar en orden, desde SSMS o con `sqlcmd` desde la raíz del repo:
1. `scripts/00_creacion_bd.sql`
2. `scripts/01_creacion_tablas.sql`
3. `scripts/02_insercion_datos.sql`
4. `scripts/03_logica_socios_cuotas.sql`
5. `scripts/04_logica_areas_profesionales.sql`
6. `scripts/05_datos_logica_socios_cuotas.sql`

Nota: el primer script elimina y vuelve a crear la base de datos ClubDeportivo si ya existe.
