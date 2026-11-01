# Spec de estado: Club Deportivo (Grupo 4)

Documento para cualquier integrante del grupo que quiera empezar a trabajar. Resume qué está hecho, cómo correrlo, qué falta y qué está pendiente de decisión. La fuente de verdad del diseño sigue siendo [TP_BBDD_Grupo_4.md](TP_BBDD_Grupo_4.md) (§4.1 y §4.2); las decisiones abiertas están en [pendientes_diseno.md](pendientes_diseno.md).

## 1. Objetivo

Diseño e implementación en **SQL Server (T-SQL)** de la base de datos de un club deportivo: socios, grupos familiares, categorías, actividades, cronograma de dictados, cuotas sociales y aranceles. Entrega para la cátedra de Bases de Datos (UNMdP, Facultad de Ingeniería).

## 2. Cómo correr los scripts

Orden obligatorio (cada uno depende del anterior):

| Script | Qué hace |
|---|---|
| `00_creacion_bd.sql` | Elimina y recrea la base `ClubDeportivo`. |
| `01_creacion_tablas.sql` | Crea las tablas, con sus constraints. |
| `02_insercion_datos.sql` | Carga datos base: categorías, grupos, socios y valores de cuota social. |
| `03_logica_socios_cuotas.sql` | Triggers, stored procedures y consultas de socios y cuotas. Se puede volver a correr (`CREATE OR ALTER`). |
| `04_datos_logica_socios_cuotas.sql` | Datos de prueba para `03`: actividades, habilitaciones, grupos, cuotas e inscripciones. Asume que se corre justo después de `02` sobre una base recién creada. |

Comando (LocalDB, autenticación de Windows):

```bash
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -b -i 00_creacion_bd.sql -i 01_creacion_tablas.sql -i 02_insercion_datos.sql -i 03_logica_socios_cuotas.sql -i 04_datos_logica_socios_cuotas.sql
```

Connection string para SSMS / clientes (LocalDB):

```
Data Source=(localdb)\MSSQLLocalDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Application Name="SQL Server Management Studio";Command Timeout=0
```

Nota: `CLAUDE.md` §2 indica `-S localhost`, pero en esta máquina la instancia es `(localdb)\MSSQLLocalDB`. Ese comando con `localhost` no conecta.

## 3. Estado: qué está hecho

### 3.1 Tablas (`01_creacion_tablas.sql`): 15 de 19

Implementadas:

- Socios: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`.
- Cuotas sociales: `VALOR_CUOTA_SOCIAL`, `CUOTA_SOCIAL`.
- Actividades: `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`.
- Profesionales y áreas: `PROFESIONAL`, `AREA`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`.
- Dictados: `DICTADO`.

Faltan (ver §4): `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`, `CUOTA_ARANCEL`.

Constraints de §4.2 ya resueltos con DDL:
- `CK_CUOTA_SOCIAL_ABONADO`: `monto_abonado <= monto_a_pagar` (`NULL` = sin pagos).
- `CK_VALOR_CUOTA_SOCIAL_FECHAS`: `fecha_hasta >= fecha_desde`.
- `CK_DICTADO_FECHAS` y `CK_DICTADO_HORARIO`: `fecha_desde <= fecha_fin` y `hora_inicio < hora_fin`.
- `CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA`: `meses_por_cuota IN (1, 2, 3, 6, 12)`. Lista decidida por el usuario, no por el grupo (TODO 1).

### 3.2 Lógica (`03_logica_socios_cuotas.sql`)

Triggers:

- `TR_INSCRIPCION_CATEGORIA_HABILITADA` (sobre `INSCRIPCION`): un socio sólo se inscribe en actividades habilitadas para su categoría (§4.2).
- `TR_VALOR_CUOTA_SOCIAL_VIGENCIA` (sobre `VALOR_CUOTA_SOCIAL`): los períodos no se superponen ni dejan huecos (§4.2).
- `TR_SOCIO_TITULAR_CATEGORIA` (sobre `SOCIO`): el titular (`nro_orden = 0`) no puede ser `Infantil` (§4.2). Usa `'Infantil'` literal (TODO 6).

Stored procedures:

- `SP_ALTA_GRUPO_FAMILIAR`: crea grupo y titular en una transacción. Garantiza que todo grupo tenga titular (H1).
- `SP_LIQUIDAR_CUOTA_SOCIAL (@anio, @mes)`: genera la cuota social de un mes para cada grupo que no la tenga (H8, H10). Monto = suma de `monto_base` vigente × `(1 + porcentaje_mod_cuota / 100)` por integrante. Se fija al generar. Vencimiento: último día del mes (supuesto, TODO 7).
- `SP_CONSULTA_TITULARES_DEUDA (@anio)`: consulta 1 del enunciado. Titulares con deuda del año, importe total e integrantes.
- `SP_CONSULTA_SOCIOS_GRATUITAS (@anio)`: consulta 2 del enunciado. Socios por categoría inscriptos en todas las gratuitas del año indicado. Se llama con el año anterior.

Las consultas también son SP, con año como parámetro, por decisión del usuario (TODO 9). El criterio de partida era usar vistas para consultas, pero se cambió.

### 3.3 Datos de prueba

- `02_insercion_datos.sql`: 4 categorías, 5 grupos (8 socios), 4 valores de cuota social (2025 y 2026). Categorías en `Infantil/Juvenil/Adulto/Jubilado` (ver TODO 6). Sin `CUOTA_SOCIAL`, sin actividades, sin inscripciones.
- `04_datos_logica_socios_cuotas.sql`: 3 grupos nuevos (Marta Ruiz, Pablo Diaz, Elena Sosa), 2 actividades gratuitas (201, 202), 1 arancelada (301), habilitaciones, cuotas de enero a marzo 2026 con pagos completos, parciales y sin pagar, e inscripciones de 2025 y 2026.

Resultados esperados con estos datos:

- `SP_CONSULTA_TITULARES_DEUDA 2026`: Pablo Diaz 30000.00 (1 integrante), Elena Sosa 78250.00 (2 integrantes).
- `SP_CONSULTA_SOCIOS_GRATUITAS 2025`: Adulto 2, el resto 0.

### 3.4 Verificación hecha

- `00` a `04` corren con exit 0, y `01` y `03` se pueden volver a correr sobre la base creada.
- Rechazos comprobados: inscripción no habilitada, vigencia superpuesta, hueco en vigencia, titular infantil y abonado mayor a pagar. El alta de titular infantil no deja filas en `GRUPO_FAMILIAR` (rollback del SP).
- Liquidar dos veces el mismo mes no duplica cuotas. Los montos calculados coinciden con los esperados.

### 3.5 Cambios recientes que conviene conocer

- `02_insercion_datos.sql` ya no tiene `DBCC CHECKIDENT ... RESEED 0`. Con ese comando, los `nro_socio_base` quedaban en 0..4 y rompían la FK de `SOCIO`. Hoy la numeración arranca en 1, por lo que los datos asumen una base recién creada por `00`.
- `porcentaje_mod_couta` pasó a `porcentaje_mod_cuota` en `01` y `02`.

## 4. Qué falta

### 4.1 Tablas

- `DICTADO_DIA (cod_dictado, dia_semana)`: PK compuesta, FK a `DICTADO`. `dia_semana` entre 1 y 7 (§4.2).
- `A_CARGO_DE (cod_dictado, dni)`: PK compuesta, FK a `DICTADO` y `PROFESIONAL`.
- `SE_DESARROLLA_EN (cod_dictado, cod_area)`: PK compuesta, FK a `DICTADO` y `AREA`.
- `CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)`: PK compuesta, FK a `INSCRIPCION`. Esquema en §4.1 de TP_BBDD_Grupo_4.md.

Orden de creación: `DICTADO_DIA`, `A_CARGO_DE` y `SE_DESARROLLA_EN` después de `DICTADO` (que ya existe); `CUOTA_ARANCEL` después de `INSCRIPCION` (que ya existe).

Para cada tabla nueva: agregar `DROP` al bloque inicial de `01` en orden inverso, comentario con el esquema lógico (PK/CK/FK) y constraints con nombre (CLAUDE.md §6 y §7).

### 4.2 Triggers y procedimientos de cronograma (dependen de tablas de 4.1)

- Un profesional a cargo de un dictado debe poder desempeñarse en la actividad del dictado (`PUEDE_DESEMPENIARSE_EN`). Trigger sobre `A_CARGO_DE`.
- Un área en la que se desarrolla un dictado debe ser apta para la actividad (`APTA_PARA`). Trigger sobre `SE_DESARROLLA_EN`.
- Un área o un profesional no puede estar en dos dictados que coincidan en día, horario y período. Trigger sobre `DICTADO_DIA`, `A_CARGO_DE` y `SE_DESARROLLA_EN`.
- Todo dictado tiene al menos un profesional a cargo (H13, participación total). Requiere SP de alta de dictado, o trigger sobre `DICTADO` / `A_CARGO_DE`.

### 4.3 Triggers y procedimientos de arancel (dependen de `CUOTA_ARANCEL`)

- Sólo las inscripciones a actividades aranceladas generan cuotas de arancel (§4.2). Validar contra `ACTIVIDAD_ARANCELADA`.
- Al inscribir en una actividad arancelada se generan las cuotas según `meses_por_cuota`, con vencimiento a `k × meses_por_cuota` meses de la inscripción (H9, §4.2). Es el SP de inscripción transaccional.
- `monto_abonado` entre 0 y `monto_a_pagar`; la deuda no se almacena (§4.2). Ya hay `CK_CUOTA_SOCIAL_ABONADO` para cuotas sociales; falta el equivalente en `CUOTA_ARANCEL`.
- Las cuotas de arancel se fijan al generar (H8).

### 4.4 Restricciones pendientes de implementación

- Participación total de `GRUPO_FAMILIAR` ↔ `SOCIO`: el SP cubre el alta, pero no evita borrar el último integrante ni el titular. Revisar si hace falta trigger.
- Totalidad y coherencia de la jerarquía `ACTIVIDAD` (TODO 2): hoy sólo hay CHECK de `tipo`. Requiere decisión del grupo.
- Baja de inscripciones al cambiar de categoría (H12, TODO 5). Requiere decisión sobre borrar filas o agregar estado.

### 4.5 Aplicación host

Enunciado (funcionalidad e): aplicación sencilla en un lenguaje host que acceda a la base y haga una operación con transacciones, por ejemplo la inscripción de un socio a una actividad. No hay decisión de lenguaje ni de estructura todavía.

### 4.6 Entregables de documentación (enunciado a–e)

- a) Modelo ER y modelo relacional: el ER está en el link de Drive citado en TP_BBDD_Grupo_4.md §3.1. El modelo relacional está en §4.1, pero no refleja aún las tablas nuevas de `01` ni su orden de implementación.
- b) Supuestos: ya están en TP_BBDD_Grupo_4.md §2 (H1–H14) y en los TODO de `pendientes_diseno.md`. Falta juntar los supuestos propios del código (tipos, vencimiento, "año pasado").
- c) Diseño físico: falta documentarlo. Aún no hay documento.
- d) Restricciones adicionales: TP_BBDD_Grupo_4.md §3.2 está vacío. Hay que completarlo con las de §4.2 y las que se implementen con triggers.
- e) Código de SP y triggers: está en `03_logica_socios_cuotas.sql`. Completar con lo que falte de §4.2–§4.3.

## 5. Decisiones pendientes

Todas en [pendientes_diseno.md](pendientes_diseno.md). Resumen:

| TODO | Tema | Estado |
|---|---|---|
| 1 | Periodicidades de `meses_por_cuota` | Lista cerrada aplicada por decisión del usuario; falta confirmar con el grupo. |
| 2 | Jerarquía de `ACTIVIDAD` (coherencia, exclusividad, totalidad) | Pendiente. |
| 3 | Dominio de `AREA.estado_mantenimiento` | Pendiente. |
| 4 | Supuestos de tipos de `PROFESIONAL` y `AREA` | Aplicados, sin confirmar. |
| 5 | Baja de inscripciones al cambiar categoría (H12) | Pendiente; fuera del alcance actual. |
| 6 | Nomenclatura de categorías y `nro_orden` de `02` vs. §4.2 | Pendiente; los datos no se corrigieron. |
| 7 | Fecha de vencimiento de la cuota social | Supuesto: último día del mes. |
| 8 | "Todas las gratuitas" sin actividades y criterio de "año pasado" | Supuesto aplicado; falta confirmar. |
| 9 | Consultas 1 y 2 como SP | Decidido: SP con parámetro de año. Falta confirmar criterio de año pasado (ver TODO 8). |

## 6. Problemas conocidos

- `02_insercion_datos.sql`: el `DELETE` borra `SOCIO` antes que `INSCRIPCION` y no borra las tablas de actividades. Hoy no molesta porque `00` recrea la base, pero rompe si se corre `02` sobre datos existentes. Hay que ordenarlo al agregar `CUOTA_ARANCEL`.
- `01_creacion_tablas.sql`: el `DROP` inicial tiene las tablas de la 4.1 que todavía no existen (`DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`, `CUOTA_ARANCEL`). Agregarlas al crearlas.
- `03_logica_socios_cuotas.sql`: `TR_SOCIO_TITULAR_CATEGORIA` tiene `'Infantil'` literal. Si cambian las categorías (TODO 6), hay que actualizar el trigger.
- `04_datos_logica_socios_cuotas.sql`: no borra nada. Si se corre sobre una base con datos, falla por claves duplicadas. Correr siempre después de `00`.
- Los grupos de `02` no tienen titular con `nro_orden = 0`. No aparecen en la consulta de deuda (`SP_CONSULTA_TITULARES_DEUDA`), aunque sí tienen cuotas.
- `CLAUDE.md` §3 quedó desactualizado: todavía dice que faltan las tablas de profesionales, áreas y dictados, y las funcionalidades ya implementadas. Conviene actualizarlo.

## 7. Próximos pasos sugeridos

1. Crear `DICTADO_DIA`, `A_CARGO_DE` y `SE_DESARROLLA_EN` en `01`, con su DROP y comentario de esquema.
2. Agregar los triggers de cronograma (§4.2 de este spec).
3. Crear `CUOTA_ARANCEL` y el SP de inscripción transaccional con generación de cuotas (§4.3).
4. Definir la aplicación host y el lenguaje.
5. Completar los entregables a–e (§4.6).
6. Resolver los TODO de §5 con el equipo.
