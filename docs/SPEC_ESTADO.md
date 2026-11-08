# Spec de estado: Club Deportivo (Grupo 4)

Documento para cualquier integrante del grupo que quiera empezar a trabajar. Resume qué está hecho, cómo correrlo, qué falta y qué está pendiente de decisión. La fuente de verdad del diseño sigue siendo [TP_BBDD_Grupo_4.md](TP_BBDD_Grupo_4.md) (§4.1 y §4.2); las decisiones abiertas están en [pendientes_diseno.md](pendientes_diseno.md) y la consulta redactada para el grupo en [consulta_decisiones_abiertas.md](consulta_decisiones_abiertas.md).

## 1. Objetivo

Diseño e implementación en **SQL Server (T-SQL)** de la base de datos de un club deportivo: socios, grupos familiares, categorías, actividades, cronograma de dictados, cuotas sociales y aranceles. Entrega para la cátedra de Bases de Datos (UNMdP, Facultad de Ingeniería).

## 2. Cómo correr los scripts

Orden obligatorio (cada uno depende del anterior). Los scripts están en `scripts/`:

| Script | Qué hace |
|---|---|
| `00_creacion_bd.sql` | Elimina y recrea la base `ClubDeportivo`. |
| `01_creacion_tablas.sql` | Crea las tablas, con sus constraints. |
| `02_insercion_datos.sql` | Carga datos base: categorías, grupos, socios y valores de cuota social. |
| `03_logica_socios_cuotas.sql` | Triggers, stored procedures y consultas de socios, cuotas, actividades y dictados. Se puede volver a correr (`CREATE OR ALTER`). |
| `04_logica_areas_profesionales.sql` | Triggers de profesional habilitado y área apta de los dictados. Se puede volver a correr (`CREATE OR ALTER`). Va antes de `05` porque sus pruebas verifican estos rechazos. |
| `05_datos_logica_socios_cuotas.sql` | Datos de prueba y pruebas de rechazo para `03` y `04`: actividades, habilitaciones, grupos, cuotas, inscripciones y dictado. Asume que se corre después de `04` sobre una base recién creada. |

Comando (LocalDB, autenticación de Windows), desde la raíz del repo:

```bash
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -b -i scripts/00_creacion_bd.sql -i scripts/01_creacion_tablas.sql -i scripts/02_insercion_datos.sql -i scripts/03_logica_socios_cuotas.sql -i scripts/04_logica_areas_profesionales.sql -i scripts/05_datos_logica_socios_cuotas.sql
```

Connection string para SSMS / clientes (LocalDB):

```
Data Source=(localdb)\MSSQLLocalDB;Integrated Security=True;Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Application Name="SQL Server Management Studio";Command Timeout=0
```

Nota: con `-S localhost` no conecta en esta máquina; la instancia es `(localdb)\MSSQLLocalDB`.

## 3. Estado: qué está hecho

### 3.1 Tablas (`01_creacion_tablas.sql`): 19 de 19

Implementadas todas las de §4.1 de TP_BBDD_Grupo_4.md, con su `DROP` en el bloque inicial:

- Socios: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`.
- Cuotas sociales: `VALOR_CUOTA_SOCIAL`, `CUOTA_SOCIAL`.
- Actividades: `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`.
- Profesionales y áreas: `PROFESIONAL`, `AREA`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`.
- Dictados: `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`.
- Arancel: `CUOTA_ARANCEL`.

Constraints de dominio resueltos con DDL:

- `CK_CATEGORIA_NOMBRE`: sólo `infantiles`, `mayores`, `vitalicios` (§4.2).
- `CK_SOCIO_NRO_ORDEN`: `nro_orden >= 0`.
- `CK_CUOTA_SOCIAL_ABONADO` y `CK_CUOTA_ARANCEL_ABONADO`: `monto_abonado <= monto_a_pagar` (`NULL` = sin pagos).
- `CK_VALOR_CUOTA_SOCIAL_FECHAS`: `fecha_hasta >= fecha_desde`.
- `CK_DICTADO_FECHAS` y `CK_DICTADO_HORARIO`: `fecha_desde <= fecha_fin` y `hora_inicio < hora_fin`. `CK_DICTADO_DIA_SEMANA`: de 1 a 7.
- `CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA`: `meses_por_cuota IN (1, 2, 3, 6, 12)` (TODO 1, cerrado).
- `CK_PROFESIONAL_DNI`: `dni > 0`. `CK_AREA_COD_AREA`: no vacío y sin espacios al borde. `CK_AREA_CAPACIDAD`: `capacidad >= 0` (TODO 4).
- `CK_CUOTA_ARANCEL_NRO_CUOTA` (`nro_cuota > 0`) y `CK_CUOTA_ARANCEL_IMPORTES`.

### 3.2 Lógica en `03_logica_socios_cuotas.sql`

Triggers:

- `TR_INSCRIPCION_CATEGORIA_HABILITADA` (sobre `INSCRIPCION`): un socio sólo se inscribe en actividades habilitadas para su categoría (§4.2). Error 50001.
- `TR_VALOR_CUOTA_SOCIAL_VIGENCIA` (sobre `VALOR_CUOTA_SOCIAL`): los períodos no se superponen ni dejan huecos (§4.2). Error 50002.
- `TR_SOCIO_TITULAR_CATEGORIA` (sobre `SOCIO`): el titular (`nro_orden = 0`) no puede ser `infantiles` (§4.2). Usa `'infantiles'` literal. Error 50003.
- `TR_SOCIO_BAJA_GRUPO` (sobre `SOCIO`, al borrar): el titular no se da de baja mientras el grupo tenga integrantes (50009), y un grupo no queda sin integrantes (50010). No aplica al borrar el grupo completo por cascada.
- `TR_DICTADO_SOLAPAMIENTO_*` (sobre `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`): no hay dos dictados que coincidan en día, horario y período con un área o profesional en común. Consultan la vista `VW_CONFLICTOS_DICTADO`. Error 50007.
- `TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA` (sobre `CUOTA_ARANCEL`): sólo las actividades aranceladas generan cuotas de arancel (§4.2, H9). Aporte de un compañero, adaptado al estilo de `03`. Error 50008.
- `TR_ACTIVIDAD_ARANCELADA_TIPO` (50011), `TR_ACTIVIDAD_GRATUITA_TIPO` (50012) y `TR_ACTIVIDAD_TIPO_INMUTABLE` (50013): coherencia y exclusividad de la jerarquía de `ACTIVIDAD` (TODO 2).

Stored procedures:

- `SP_ALTA_GRUPO_FAMILIAR`: crea grupo y titular en una transacción. Garantiza que todo grupo tenga titular (H1).
- `SP_ALTA_ACTIVIDAD_ARANCELADA` y `SP_ALTA_ACTIVIDAD_GRATUITA`: crean la actividad y su subentidad en una transacción (totalidad de la jerarquía, TODO 2).
- `SP_ALTA_DICTADO`: crea dictado, un día y un profesional a cargo en una transacción (H13). No carga el área (ver TODO 10).
- `SP_INSCRIBIR_ACTIVIDAD (@nro_socio_base, @nro_orden, @cod_actividad, @fecha_inscripcion)`: inscribe. Si la actividad es arancelada, genera la cuota 1 por adelantado (H9). Transacción.
- `SP_LIQUIDAR_CUOTA_ARANCEL (@anio, @mes)`: genera, para el mes, la cuota de arancel que vence en cada inscripción arancelada. La cuota k vence k × `meses_por_cuota` meses después de la inscripción. No duplica (H8, H9). Supuesto: se corre cada mes (ver TODO 11).
- `SP_LIQUIDAR_CUOTA_SOCIAL (@anio, @mes)`: genera la cuota social de un mes para cada grupo que no la tenga (H8, H10). Monto = suma de `monto_base` vigente × `(1 + porcentaje_mod_cuota / 100)` por integrante. Se fija al generar. Vencimiento: último día del mes (TODO 7, cerrado).
- `SP_CONSULTA_TITULARES_DEUDA (@anio)`: consulta 1 del enunciado. Titulares con deuda del año, importe total e integrantes.
- `SP_CONSULTA_SOCIOS_GRATUITAS (@anio)`: consulta 2 del enunciado. Socios por categoría inscriptos en todas las gratuitas del año indicado. Se llama con el año anterior.

Las consultas son SP con año como parámetro por decisión del usuario (TODO 9), no vistas.

### 3.3 Lógica en `04_logica_areas_profesionales.sql`

Aporte de un compañero, adaptado a los códigos de error y al estilo de `03`:

- `TR_A_CARGO_DE_PROF_HABILITADO` (sobre `A_CARGO_DE`): el profesional debe estar en `PUEDE_DESEMPENIARSE_EN` para la actividad del dictado (§4.2). Error 50005.
- `TR_SE_DESARROLLA_EN_AREA_APTA` (sobre `SE_DESARROLLA_EN`): el área debe estar en `APTA_PARA` para la actividad del dictado (§4.2). Error 50006.

Los códigos de error son únicos en todo `03` y `04` (50001 a 50013, con 50004 usado por `SP_LIQUIDAR_CUOTA_SOCIAL`).

### 3.4 Datos de prueba

- `02_insercion_datos.sql`: 3 categorías (`infantiles` -30, `mayores` 0, `vitalicios` -15), 5 grupos (8 socios, titulares con `nro_orden = 0`), 4 valores de cuota social (2025 y 2026). Sin `CUOTA_SOCIAL`, sin actividades, sin inscripciones.
- `05_datos_logica_socios_cuotas.sql`: 3 grupos nuevos (Marta Ruiz, Pablo Diaz, Elena Sosa), 2 actividades gratuitas (201, 202) y 1 arancelada (301) creadas con los SP de alta, habilitaciones, cuotas de enero a marzo 2026 con pagos completos, parciales y sin pagar, inscripciones de 2025 y 2026, un profesional, un área y un dictado de ejemplo.

Resultados esperados con estos datos:

- `SP_CONSULTA_TITULARES_DEUDA 2026`: Juan Perez 121500.00 (3), Carlos Gomez 90000.00 (2), Sofia Rodriguez 45000.00 (1), Roberto Fernandez 38250.00 (1), Laura Martinez 45000.00 (1), Pablo Diaz 30000.00 (1), Elena Sosa 78250.00 (2).
- `SP_CONSULTA_SOCIOS_GRATUITAS 2025`: mayores 2, el resto 0.
- Deuda de arancel de Marta (actividad 301): 8000.00.

### 3.5 Verificación hecha

- Reconstrucción limpia con `00` a `05` (exit 0). `03` y `04` se pueden volver a correr (exit 0).
- Pruebas en `05`, cada una en transacción con `ROLLBACK`:
  - A–G: rechazos 50005, 50006, 50007 (y el control D, que pasa), 50008, 50009 y 50010.
  - H–K: rechazos 50011, 50012 y 50013, y el alta por SP de actividades (K, pasa).
  - L–N: error 547 de `CK_PROFESIONAL_DNI`, `CK_AREA_COD_AREA` (blanco y espacio inicial), `CK_CATEGORIA_NOMBRE` y `CK_SOCIO_NRO_ORDEN`.
- Liquidar dos veces el mismo mes no duplica cuotas. Los montos calculados coinciden con los esperados.
- El alta de un titular infantil no deja filas en `GRUPO_FAMILIAR` (rollback del SP).
- Re-correr `02` sobre una base cargada falla por diseño (`FK_SOCIO_GRUPO_FAMILIAR`): la `IDENTITY` de `GRUPO_FAMILIAR` no se reinicia. Re-correr `05` sobre datos cargados falla por claves duplicadas.

## 4. Qué falta

### 4.1 Decisiones del grupo (abiertas)

Detalle en [pendientes_diseno.md](pendientes_diseno.md). No implementar ni asumir sin el equipo.

- TODO 3: dominio de `AREA.estado_mantenimiento` (y confirmar que es monovaluado).
- TODO 5: baja de inscripciones al cambiar de categoría (H12), con efecto sobre la PK de `INSCRIPCION` (H6).
- TODO 8 y 9: consulta 2, "todas las gratuitas" sin actividades y criterio de "año pasado".

### 4.2 Restricciones del modelo sin garantizar

Surgen de comparar TP_BBDD_Grupo_4.md §4.1 y §4.2 con los scripts. Detalle y opciones en los TODO 10 y 11 de [pendientes_diseno.md](pendientes_diseno.md). Ninguna se consultó todavía.

- Participaciones totales (TODO 10): `ACTIVIDAD` en `HABILITADA_PARA`, `PROFESIONAL` en `PUEDE_DESEMPENIARSE_EN`, `AREA` en `APTA_PARA` y `DICTADO` en `SE_DESARROLLA_EN` no se garantizan. `GRUPO_FAMILIAR`, `DICTADO` (día y profesional) y la jerarquía de `ACTIVIDAD` sólo se garantizan por los SP de alta; un `INSERT` directo los saltea.
- Cuotas (TODO 11): la correlatividad y el vencimiento de `CUOTA_ARANCEL` (§4.2) y el monto de `CUOTA_SOCIAL` sólo los cumplen los SP. Si `SP_LIQUIDAR_CUOTA_ARANCEL` no se corre en un mes, queda un hueco en la numeración.
- Baja de inscripciones al cambiar de categoría (H12): sin implementar hasta cerrar el TODO 5.

### 4.3 Aplicación host

Enunciado (funcionalidad e): aplicación sencilla en un lenguaje host que acceda a la base y haga una operación con transacciones. **Fuera de alcance por ahora** (decisión del equipo de trabajo). Se retoma más adelante.

### 4.4 Entregables de documentación (enunciado a–e)

- a) Modelo ER y modelo relacional: el ER está en el link de Drive citado en TP_BBDD_Grupo_4.md §3.1. El modelo relacional de §4.1 no refleja los cambios posteriores: tablas nuevas, orden de implementación y los CHECK agregados (TODO 12).
- b) Supuestos: ya están en TP_BBDD_Grupo_4.md §2 (H1–H14) y en los TODO de `pendientes_diseno.md`. Falta juntar los supuestos propios del código: mapeo y porcentajes de categorías, vencimiento de la cuota, "año pasado", `cod_area` como texto, `SP_LIQUIDAR_CUOTA_ARANCEL` mensual.
- c) Diseño físico: falta documentarlo. Aún no hay documento.
- d) Restricciones adicionales: TP_BBDD_Grupo_4.md §3.2 está vacío. Hay que completarlo con las de §4.2, los triggers y SP implementados y las limitaciones del TODO 10 (TODO 12).
- e) Código de SP y triggers: está en `03_logica_socios_cuotas.sql` y `04_logica_areas_profesionales.sql`. Falta revisarlo contra §4.2 cuando se cierren los TODO abiertos.

## 5. Decisiones: resumen

Todas en [pendientes_diseno.md](pendientes_diseno.md).

| TODO | Tema | Estado |
|---|---|---|
| 1 | Periodicidades de `meses_por_cuota` | Cerrado: `IN (1, 2, 3, 6, 12)`. |
| 2 | Jerarquía de `ACTIVIDAD` | Aplicado (triggers y SP de alta). Totalidad sólo vía SP. |
| 3 | Dominio de `AREA.estado_mantenimiento` | **Abierto**; el usuario lo consulta. |
| 4 | Tipos de `PROFESIONAL.dni` y `AREA.cod_area` | Aplicado: `dni` `INT` con `dni > 0`; `cod_area` `VARCHAR(20)` con CHECK de formato. |
| 5 | Baja de inscripciones al cambiar categoría (H12) | **Abierto**; el usuario lo consulta (se inclina por agregar estado a `INSCRIPCION`). |
| 6 | Categorías y `nro_orden` | Aplicado: `infantiles/mayores/vitalicios` y titular en 0. |
| 7 | Vencimiento de la cuota social | Cerrado: último día del mes. |
| 8 | "Todas las gratuitas" sin actividades y "año pasado" | **Abierto**; el usuario lo consulta. Supuesto aplicado. |
| 9 | Consultas 1 y 2 como SP | SP con parámetro de año. Falta confirmar el criterio de año (ver TODO 8). |
| 10 | Participaciones totales sin garantizar | **Abierto**; no consultado. |
| 11 | Restricciones de cuotas que sólo cubren los SP | **Abierto**; no consultado. |
| 12 | Inconsistencias en TP_BBDD_Grupo_4.md (§3.2, §5.1.1, §5.1.15, §4.1) | **Abierto**; requiere OK del grupo. |

## 6. Problemas conocidos

- `02_insercion_datos.sql`: sólo corre sobre base recién creada por `00`. Los `DELETE` van en orden inverso de dependencias, pero la re-carga falla igual por la `IDENTITY` de `GRUPO_FAMILIAR`. La numeración de `nro_socio_base` arranca en 1 (no hay `DBCC CHECKIDENT ... RESEED 0`, que rompía la FK de `SOCIO`).
- `05_datos_logica_socios_cuotas.sql`: no borra nada. Si se corre sobre una base con datos, falla por claves duplicadas. Correr siempre después de `00`.
- `TR_SOCIO_TITULAR_CATEGORIA` tiene `'infantiles'` literal y `CK_CATEGORIA_NOMBRE` tiene las tres categorías. Si cambian los nombres, hay que actualizar ambos.
- Un `INSERT` directo en `ACTIVIDAD` o borrar una subentidad puede dejar una actividad sin clasificar (la totalidad la cubren los `SP_ALTA_ACTIVIDAD_*`).
- Los SP de alta (`SP_ALTA_GRUPO_FAMILIAR`, `SP_ALTA_DICTADO`, `SP_ALTA_ACTIVIDAD_*`) son la única vía que garantiza la participación total; un `INSERT` directo la saltea.
- Los SP de alta hacen `ROLLBACK` incondicional si hay una transacción abierta; si se los llama dentro de una transacción externa, la revierten completa.

## 7. Próximos pasos sugeridos

1. Llevar al grupo la consulta de [consulta_decisiones_abiertas.md](consulta_decisiones_abiertas.md) (TODO 3, 5, 8 y 9) y agregarle los TODO 10 y 11.
2. Con las respuestas, aplicar en los scripts: dominio de `estado_mantenimiento`, baja de inscripciones (H12) y lo que se decida de los TODO 10 y 11.
3. Completar los entregables a–d (§4.4). Conviene empezar por d (restricciones adicionales) y b (supuestos), que se pueden redactar con lo ya implementado.
4. Resolver con el grupo las inconsistencias de TP_BBDD_Grupo_4.md (TODO 12) antes de entregar.

La aplicación host queda fuera de este plan.
