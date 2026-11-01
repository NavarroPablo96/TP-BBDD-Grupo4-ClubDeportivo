# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Trabajo Práctico de Bases de Datos (UNMdP, Facultad de Ingeniería) del **Grupo 4**: diseño e implementación en **Microsoft SQL Server (T-SQL)** de la base de datos de un club deportivo (socios, grupos familiares, categorías, actividades, cronograma de dictados, cuotas sociales y aranceles).

Responder en español rioplatense, de forma clara y técnica.

## 1. Recursos de contexto y orden de consulta

Antes de resolver cualquier pedido, consultar los recursos **en este orden de prioridad**. Se empieza por el 1; si alcanza para resolver lo que pide el usuario, se deja de consultar. Si no alcanza, se pasa al siguiente.

| P | Archivo | Qué es | Cuándo usarlo |
|---|---------|--------|---------------|
| 1 | [docs/TP_BBDD_Grupo_4.md](docs/TP_BBDD_Grupo_4.md) | Resolución entregada por el grupo: hipótesis H1–H14 (§2), esquemas de relación con restricciones de integridad referencial (§4.1), restricciones adicionales (§4.2), normalización (§5). | Fuente principal del diseño. Todo script debe reflejar el modelo lógico de §4.1 y las restricciones de §4.2. |
| 2 | [docs/referencias/TP A-2c 2026-UNMdP - BDyDBD.md](<docs/referencias/TP A-2c 2026-UNMdP - BDyDBD.md>) | Enunciado oficial: descripción del problema, entregables (a–e) y funcionalidades pedidas por la cátedra. | Para validar requisitos, desambiguar el dominio o cuando la resolución del grupo no cubre el tema. |
| 3 | [docs/referencias/BD-MR-Leticia.md](docs/referencias/BD-MR-Leticia.md) | Apunte de la cátedra (Prof. Seijas): modelo relacional, restricciones y reglas de transformación ER → relacional (entidades débiles, 1:1, 1:N, M:N, unarias, ternarias, jerarquías, agregación). | Para justificar decisiones de mapeo y respetar la nomenclatura de la cátedra. |
| 4 | [docs/referencias/Navathe.md](docs/referencias/Navathe.md) | Bibliografía teórica (Elmasri/Navathe, *Fundamentos de Sistemas de Bases de Datos*). Archivo muy grande (~28k líneas): **no leerlo entero**, buscar con Grep y leer por rangos. | Sólo si los anteriores no alcanzan. Capítulos útiles: 3 ER (l.1773), 4 EER (l.2660), 5 modelo relacional y restricciones (l.3403), 7 mapeo ER/EER→relacional (l.5854), 8 SQL: esquema, restricciones, vistas (l.6156), 9 programación SQL (l.7560), 10–11 dependencias funcionales y normalización (l.8594, l.9856), 16 diseño físico (l.14834), 17 transacciones (l.15180). |

Reglas sobre las fuentes:

- Si la resolución del grupo (P1) contradice el enunciado (P2), **no resolverlo en silencio**: señalar la contradicción en el informe y preguntar.
- Al citar, indicar archivo y sección/hipótesis/línea (ej.: "TP_BBDD_Grupo_4.md §4.2", "H9", "Navathe cap. 7").
- Los `.md` de contexto son conversiones de PDF/Docs: pueden tener escapes (`\_`), saltos raros o texto de imágenes. Interpretar, no copiar literalmente.

## 2. Ejecución de los scripts

No hay build, lint ni tests automatizados. Los scripts se ejecutan en SQL Server (Developer Edition) desde SSMS, en orden:

Los scripts están en `scripts/` y la documentación en `docs/` (las fuentes de referencia en `docs/referencias/`).

1. `scripts/00_creacion_bd.sql` — **elimina y recrea** la base `ClubDeportivo` (`SINGLE_USER WITH ROLLBACK IMMEDIATE`).
2. `scripts/01_creacion_tablas.sql` — crea las tablas con sus constraints.
3. `scripts/02_insercion_datos.sql` — carga datos base.
4. `scripts/03_logica_socios_cuotas.sql` — triggers, stored procedures y consultas de socios y cuotas.
5. `scripts/04_datos_logica_socios_cuotas.sql` — datos de prueba para `03`.

Equivalente por línea de comandos desde la raíz del repo (autenticación de Windows, LocalDB):

```bash
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -b -i scripts/00_creacion_bd.sql -i scripts/01_creacion_tablas.sql -i scripts/02_insercion_datos.sql -i scripts/03_logica_socios_cuotas.sql -i scripts/04_datos_logica_socios_cuotas.sql
```

Connection string de la base local (LocalDB, autenticación de Windows):

```
Data Source=(localdb)\MSSQLLocalDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Application Name="SQL Server Management Studio";Command Timeout=0
```

Cada script nuevo debe correr sin errores sobre una base limpia, después de los anteriores. Los scripts nuevos siguen la numeración (`03_...sql`, etc.) y usan `GO` como separador de lotes, igual que los existentes.

## 3. Estado actual del repositorio

- Implementadas en `01_creacion_tablas.sql`: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`, `VALOR_CUOTA_SOCIAL`, `CUOTA_SOCIAL`, `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`.
- Pobladas en `02_insercion_datos.sql`: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`, `VALOR_CUOTA_SOCIAL`.
- Faltan del modelo lógico (§4.1): `PROFESIONAL`, `AREA`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`, `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`, `CUOTA_ARANCEL`. Usar la versión de §4.1 (con `DICTADO_DIA` separada): fue un cambio de modelo confirmado por el grupo, y §5.1.15 (que deja `dia_semana` dentro de `DICTADO`) quedó desactualizada.
- Faltan las funcionalidades pedidas por el enunciado: consulta de titulares con deuda de cuota social del año en curso (importe total e integrantes), cantidad de socios por categoría inscriptos en todas las actividades gratuitas del año pasado, al menos un trigger, y una aplicación sencilla en un lenguaje host que use transacciones (ej. inscripción a actividades).
- [docs/pendientes_diseno.md](docs/pendientes_diseno.md) registra decisiones abiertas del grupo (valores de `meses_por_cuota`; cómo garantizar coherencia, exclusividad y totalidad de la jerarquía `ACTIVIDAD`). Consultarlo antes de tocar esas tablas y no cerrar esas decisiones sin el equipo.

Inconsistencias conocidas entre scripts y diseño (señalarlas si se trabaja cerca, no corregirlas sin avisar):

- La columna se llama `porcentaje_mod_couta` en el script; el modelo dice `porcentaje_mod_cuota`.
- Los datos usan categorías `Infantil/Juvenil/Adulto/Jubilado`; el enunciado y §4.2 fijan `infantiles/mayores/vitalicios`.
- Los datos numeran `nro_orden` desde 1; H1 y §4.2 dicen que el titular tiene `nro_orden = 0`.
- Los `DROP TABLE` de `01` y los `DELETE` de `02` no siguen el orden inverso de dependencias; hoy funciona sólo porque `00` recrea la base.
- `CK_CUOTA_IMPORTES` no controla `monto_abonado <= monto_a_pagar` (§4.2).

## 4. Reglas generales de trabajo

- **La IA no hace commits ni `git push`.** Los cambios se entregan como archivos y el equipo revisa y commitea.
- No inventar requisitos, restricciones ni datos que no estén en las fuentes. Si falta información, preguntar; si hay que asumir algo, marcarlo como supuesto.
- Cada entrega incluye un **informe de trabajo** (en la respuesta, y en `INFORME_TRABAJO.md` si el usuario lo pide) con:
  - Qué se hizo: cambios concretos y archivos creados o modificados.
  - Recursos usados, con sección o línea (ver §1).
  - Supuestos y decisiones de diseño, con su justificación.
  - Dudas o puntos pendientes de validar con la cátedra o el equipo.

## 5. Restricciones del enunciado y de la cátedra

- **Prohibidos los atributos multivaluados** en el modelo lógico y en las tablas: se normalizan en una tabla aparte (como `DICTADO_DIA`).
- Al pasar a scripts, respetar todas las restricciones del modelo: cardinalidades, claves, dominios y reglas de negocio de §4.1 y §4.2 de la resolución. Antes de codificar, listar las restricciones que afectan a lo que se va a escribir y, al terminar, verificar cada una contra el script.
- Las restricciones que no se pueden expresar con `PRIMARY KEY`/`FOREIGN KEY`/`UNIQUE`/`CHECK` (participación total, coherencia de la jerarquía, categoría del socio habilitada para la actividad, períodos sin superposición, etc.) se resuelven con triggers o stored procedures; si no se implementan, dejarlo documentado como pendiente.
- Motor: **SQL Server / T-SQL** únicamente. Nada de `AUTO_INCREMENT`, `SERIAL`, `LIMIT`, `NOW()`; usar `IDENTITY`, `TOP`, `GETDATE()`, etc.

## 6. Nomenclatura

La nomenclatura de la cátedra (BD-MR-Leticia.md) y la ya usada en la resolución del grupo **priman** sobre cualquier otra:

- Tablas en MAYÚSCULAS y singular, con guion bajo, sin tildes ni `Ñ` (`PUEDE_DESEMPENIARSE_EN`). Atributos en `snake_case` minúscula, en castellano.
- Esquema lógico escrito como en la resolución:
  `TABLA (atr1, atr2, ...) PK = CK = {...} FK = {...}`
  seguido de las restricciones de integridad referencial en la forma "X.a **debe estar** en Y.b" / "X.a **puede no estar** en Y.b" / "no puede tomar valor nulo".
- Cada tabla en `01_creacion_tablas.sql` va precedida por un comentario con su esquema lógico (PK/CK/FK), como las existentes.

## 7. Convenciones T-SQL

- Palabras clave en MAYÚSCULAS, sentencias terminadas en `;`, lotes separados con `GO`.
- Constraints siempre con nombre: `PK_<TABLA>`, `FK_<TABLA>_<TABLA_REF>`, `UQ_`, `CK_<TABLA>_<ATRIBUTO>`, `DF_`.
- `NOT NULL` donde el modelo lo exige, `UNIQUE` para claves candidatas no primarias, `CHECK` para dominios.
- Crear tablas respetando dependencias; eliminar e insertar en el orden que corresponda (inverso para borrar).
- Usar `BEGIN TRANSACTION` / `COMMIT` (con `TRY...CATCH` y `ROLLBACK`) cuando una operación toca varias tablas.
- Comentarios en español sólo para decisiones no obvias; marcar con `-- TODO:` lo que quede pendiente de decisión del grupo.
- Los datos de prueba tienen que permitir evaluar las consultas pedidas por el enunciado (deudas del año en curso, inscripciones del año pasado, etc.).
- Al final de implementar un plan o hacer cambios a los archivos de scripts / source code dar un titulo de commit consiso
