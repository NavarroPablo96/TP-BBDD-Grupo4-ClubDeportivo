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

La aplicación host (`app-host/`) necesita la base ya creada con estos seis scripts; ver §4.3.

## 3. Estado: qué está hecho

### 3.1 Tablas (`01_creacion_tablas.sql`): 21

Las 19 de §4.1 de TP_BBDD_Grupo_4.md más `ESTADO_AREA` y `HISTORIAL_AREA_ESTADO` (historial de estados de las áreas, TODO 3; ver TODO 12), con su `DROP` en el bloque inicial:

- Socios: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`.
- Cuotas sociales: `VALOR_CUOTA_SOCIAL`, `CUOTA_SOCIAL`.
- Actividades: `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`.
- Profesionales y áreas: `PROFESIONAL`, `AREA`, `ESTADO_AREA` (catálogo de estados), `HISTORIAL_AREA_ESTADO`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`.
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
- `CK_INSCRIPCION_ESTADO` (`'Activa'` / `'Baja'`) y `CK_INSCRIPCION_FECHA_BAJA` (activa sin fecha de baja; baja con fecha no anterior a la inscripción) (TODO 5).

Claves: la PK de `INSCRIPCION` es `(nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)` y `CUOTA_ARANCEL` la incluye en su PK y en su FK hacia `INSCRIPCION` (TODO 5).

Historial de estados de las áreas (TODO 3): `AREA` ya no tiene `estado_mantenimiento`. `ESTADO_AREA (nombre_estado)` es el catálogo y `HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)` es la relación N:M con `fecha_desde`. Su PK es `(cod_area, fecha_desde)`: un área puede volver a un estado anterior, pero tiene un único estado por fecha. Las FK exigen que el área y el estado existan.

### 3.2 Lógica en `03_logica_socios_cuotas.sql`

Triggers:

- `TR_INSCRIPCION_CATEGORIA_HABILITADA` (sobre `INSCRIPCION`): un socio sólo se inscribe en actividades habilitadas para su categoría (§4.2). Valida sólo las inscripciones `Activa`. Error 50001.
- `TR_INSCRIPCION_VIGENTE_UNICA` (sobre `INSCRIPCION`): a lo sumo una inscripción `Activa` por socio y actividad (H6). Error 50014.
- `TR_SOCIO_CAMBIO_CATEGORIA` (sobre `SOCIO`, al actualizar la categoría): da de baja las inscripciones activas no habilitadas para la nueva categoría y conserva las compatibles (H12, TODO 5).
- `TR_VALOR_CUOTA_SOCIAL_VIGENCIA` (sobre `VALOR_CUOTA_SOCIAL`): los períodos no se superponen ni dejan huecos (§4.2). Error 50002.
- `TR_SOCIO_TITULAR_CATEGORIA` (sobre `SOCIO`): el titular (`nro_orden = 0`) no puede ser `infantiles` (§4.2). Usa `'infantiles'` literal. Error 50003.
- `TR_SOCIO_BAJA_GRUPO` (sobre `SOCIO`, al borrar): el titular no se da de baja mientras el grupo tenga integrantes (50009), y un grupo no queda sin integrantes (50010). No aplica al borrar el grupo completo por cascada.
- `TR_DICTADO_SOLAPAMIENTO_*` (sobre `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`): no hay dos dictados que coincidan en día, horario y período con un área o profesional en común. Consultan la vista `VW_CONFLICTOS_DICTADO`. Error 50007.
- `TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA` (sobre `CUOTA_ARANCEL`): sólo las actividades aranceladas generan cuotas de arancel (§4.2, H9). Aporte de un compañero, adaptado al estilo de `03`. Error 50008.
- `TR_ACTIVIDAD_ARANCELADA_TIPO` (50011), `TR_ACTIVIDAD_GRATUITA_TIPO` (50012) y `TR_ACTIVIDAD_TIPO_INMUTABLE` (50013): coherencia y exclusividad de la jerarquía de `ACTIVIDAD` (TODO 2).

Stored procedures:

- `SP_ALTA_GRUPO_FAMILIAR`: crea grupo y titular en una transacción. Garantiza que todo grupo tenga titular (H1).
- `SP_ALTA_ACTIVIDAD_ARANCELADA` y `SP_ALTA_ACTIVIDAD_GRATUITA`: crean la actividad y su subentidad en una transacción (totalidad de la jerarquía, TODO 2).
- `SP_ALTA_DICTADO (…, @dni, @cod_area, @cod_dictado OUTPUT)`: crea dictado, un día, un profesional a cargo y un área en una transacción (H13, §4.1; TODO 10).
- `SP_INSCRIBIR_ACTIVIDAD (@nro_socio_base, @nro_orden, @cod_actividad, @fecha_inscripcion)`: inscribe. Si la actividad es arancelada, genera la cuota 1 por adelantado (H9). Transacción.
- `SP_LIQUIDAR_CUOTA_ARANCEL (@anio, @mes)`: "puesta al día": genera todas las cuotas de arancel vencidas hasta el mes indicado que falten, de las inscripciones activas (y de las dadas de baja sólo hasta su fecha de baja). La cuota n vence (n - 1) × `meses_por_cuota` meses después de la inscripción (H9). No duplica (H8) y la numeración queda correlativa aunque se saltee un mes (TODO 11).
- `SP_LIQUIDAR_CUOTA_SOCIAL (@anio, @mes)`: genera la cuota social de un mes para cada grupo que no la tenga (H8, H10). Monto = suma de `monto_base` vigente × `(1 + porcentaje_mod_cuota / 100)` por integrante. Se fija al generar. Vencimiento: último día del mes (TODO 7, cerrado).

Vistas de las consultas del enunciado (decisión del usuario, TODO 9; se eliminan los SP anteriores con `DROP PROCEDURE IF EXISTS`):

- `VW_TITULARES_DEUDA_ANIO_ACTUAL`: consulta 1. Titulares con deuda en las cuotas sociales de `YEAR(GETDATE())`, importe total e integrantes.
- `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`: consulta 2. Socios por categoría inscriptos en todas las gratuitas durante `YEAR(GETDATE()) - 1`. Cuenta también las inscripciones dadas de baja. Sólo muestra las categorías con al menos un socio que cumple: si no hay filas para mostrar (por ejemplo, sin actividades gratuitas) no devuelve nada (TODO 8).
- `VW_CONFLICTOS_DICTADO`: pares de dictados en conflicto, para los triggers de solapamiento.

### 3.3 Lógica en `04_logica_areas_profesionales.sql`

Aporte de un compañero, adaptado a los códigos de error y al estilo de `03`:

- `TR_A_CARGO_DE_PROF_HABILITADO` (sobre `A_CARGO_DE`): el profesional debe estar en `PUEDE_DESEMPENIARSE_EN` para la actividad del dictado (§4.2). Error 50005.
- `TR_SE_DESARROLLA_EN_AREA_APTA` (sobre `SE_DESARROLLA_EN`): el área debe estar en `APTA_PARA` para la actividad del dictado (§4.2). Error 50006.

Historial de estados de las áreas (TODO 3):

- `SP_ALTA_AREA (@cod_area, @ubicacion, @capacidad, @nombre_estado, @fecha_desde = NULL)`: crea el área y su primer estado en una transacción. Sin fecha rige la actual. Es la única vía que garantiza que toda área tenga estado (§4.1); un `INSERT` directo en `AREA` la saltea.
- `SP_CAMBIAR_ESTADO_AREA (@cod_area, @nombre_estado, @fecha_desde = NULL)`: registra un nuevo estado desde una fecha. Rechaza (PK) un segundo estado en la misma fecha y (FK) un estado que no está en el catálogo.
- `VW_ESTADO_ACTUAL_AREA`: estado vigente de cada área, el de mayor `fecha_desde` que no sea futura. Un área sin historial figura con estado `NULL`.

Regla del estado operativo (TODO 13): un dictado sólo puede desarrollarse en un área que esté `Operativa` durante todo su período.

- `VW_AREA_ESTADO_PERIODO`: intervalo de vigencia de cada estado (hasta el día anterior al siguiente; el último queda abierto).
- `VW_CONFLICTOS_ESTADO_DICTADO`: pares (dictado, área) cuyo período se solapa con un estado distinto de `Operativa`.
- `TR_DICTADO_AREA_OPERATIVA_SE_DESARROLLA_EN`, `TR_DICTADO_AREA_OPERATIVA_DICTADO` y `TR_DICTADO_AREA_OPERATIVA_HISTORIAL` (sobre `SE_DESARROLLA_EN`, `DICTADO` y `HISTORIAL_AREA_ESTADO`): rechazan con error 50015 al asignar el área, al cambiar las fechas del dictado y al cambiar el historial de estados.
- Un área puede crearse con cualquier estado. Un área sin historial no se restringe. Es una hipótesis del grupo, decidida como definitiva.

Los códigos de error son únicos en todo `03` y `04` (50001 a 50015, con 50004 usado por `SP_LIQUIDAR_CUOTA_SOCIAL`).

### 3.4 Datos de prueba

- `02_insercion_datos.sql`: 3 categorías (`infantiles` -30, `mayores` 0, `vitalicios` -15), 3 estados de área (`Operativa`, `En mantenimiento`, `Fuera de servicio`; lista propuesta, pendiente de confirmar con el grupo), 5 grupos (8 socios, titulares con `nro_orden = 0`), 4 valores de cuota social relativos al año actual (año anterior: 10000 y 12000; año actual: 15000 y 18000 desde julio). Sin `CUOTA_SOCIAL`, sin actividades, sin inscripciones.
- `05_datos_logica_socios_cuotas.sql`: 3 grupos nuevos (Marta Ruiz, Pablo Diaz, Elena Sosa), 2 actividades gratuitas (201, 202) y 1 arancelada (301) creadas con los SP de alta, habilitaciones, cuotas de enero a marzo del año actual con pagos completos, parciales y sin pagar, inscripciones del año anterior y del actual, un profesional, dos áreas con su historial de estados y un dictado de ejemplo. Las fechas son relativas al año actual para que las vistas den los mismos resultados cualquiera sea el año.

Resultados esperados con estos datos:

- `VW_TITULARES_DEUDA_ANIO_ACTUAL`: Juan Perez 121500.00 (3), Carlos Gomez 90000.00 (2), Sofia Rodriguez 45000.00 (1), Roberto Fernandez 38250.00 (1), Laura Martinez 45000.00 (1), Pablo Diaz 30000.00 (1), Elena Sosa 78250.00 (2).
- `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`: una sola fila, mayores 2. Las categorías sin socios no se muestran.
- Deuda de arancel de Marta (actividad 301): 8000.00.
- `VW_ESTADO_ACTUAL_AREA`: `AREA-01` Operativa y `AREA-02` Fuera de servicio. El historial de `AREA-02` tiene cuatro registros: Operativa, En mantenimiento, Operativa (vuelve a un estado anterior) y Fuera de servicio.

### 3.5 Verificación hecha

- Reconstrucción limpia con `00` a `05` (exit 0). `03` y `04` se pueden volver a correr (exit 0).
- Pruebas en `05`, cada una en transacción con `ROLLBACK` (salvo R, que limpia sus datos):
  - A–G: rechazos 50005, 50006, 50007 (y el control D, que pasa), 50008, 50009 y 50010.
  - H–K: rechazos 50011, 50012 y 50013, y el alta por SP de actividades (K, pasa).
  - L–N: error 547 de `CK_PROFESIONAL_DNI`, `CK_AREA_COD_AREA` (blanco y espacio inicial), `CK_CATEGORIA_NOMBRE` y `CK_SOCIO_NRO_ORDEN`.
  - O: el cambio de categoría da de baja la inscripción incompatible, conserva la compatible y la cuota ya generada (H12).
  - P1 y P2: reinscripción tras una baja (pasa) y segunda inscripción activa en la misma actividad (50014).
  - Q: puesta al día, cuotas 1 a 4 correlativas al liquidar abril sin haber liquidado antes, sin duplicar al repetir.
  - R: `SP_ALTA_DICTADO` con un área no apta rechaza 50006 y no deja filas.
  - S: sin actividades gratuitas, `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR` no devuelve filas.
  - T–X (historial de estados de áreas): dos estados en la misma fecha rechazan por la PK (2627); un estado fuera del catálogo rechaza por la FK (547) y no deja filas (U); un área vuelve a un estado anterior y un estado con fecha futura no es el vigente (V); `SP_ALTA_AREA` con estado inválido rechaza y no deja el área (W); estados vigentes de los datos de prueba (X).
  - Y1, Y2 y Z (regla del estado operativo): asignar un área en mantenimiento durante todo el período rechaza 50015 (Y1); pasar el área a mantenimiento a mitad de un dictado rechaza 50015 (Y2); un mantenimiento que termina antes del dictado no lo bloquea (Z).
- Liquidar dos veces el mismo mes no duplica cuotas. Los montos calculados coinciden con los esperados.
- El alta de un titular infantil no deja filas en `GRUPO_FAMILIAR` (rollback del SP).
- Re-correr `02` sobre una base cargada falla por diseño (`FK_SOCIO_GRUPO_FAMILIAR`): la `IDENTITY` de `GRUPO_FAMILIAR` no se reinicia. Re-correr `05` sobre datos cargados falla por claves duplicadas.

## 4. Qué falta

### 4.1 Decisiones del grupo (abiertas)

Detalle en [pendientes_diseno.md](pendientes_diseno.md). No implementar ni asumir sin el equipo.

- TODO 8: confirmar que "año pasado" es el año de `fecha_inscripcion` (`YEAR(GETDATE()) - 1`). El caso vacío ya está decidido: la consulta 2 no devuelve filas.
- TODO 12: correcciones a la resolución entregada (§3.2, §4.1 con las dos tablas del historial, §4.2 y H15 con la regla del TODO 13, §5.1.1, §5.1.15 y H9 vs §4.2 l.219).

### 4.2 Restricciones del modelo sin garantizar

Surgen de comparar TP_BBDD_Grupo_4.md §4.1 y §4.2 con los scripts. Quedan como limitación documentada por decisión del usuario (TODO 10 y 11 en [pendientes_diseno.md](pendientes_diseno.md)); hay que registrarlas en las restricciones adicionales (entregable d).

- Participaciones totales (TODO 10): `ACTIVIDAD` en `HABILITADA_PARA`, `PROFESIONAL` en `PUEDE_DESEMPENIARSE_EN` y `AREA` en `APTA_PARA` no se garantizan. `GRUPO_FAMILIAR`, `DICTADO` (día, profesional y área), `AREA` en `HISTORIAL_AREA_ESTADO` (todo área tiene al menos un estado) y la jerarquía de `ACTIVIDAD` sólo se garantizan por los SP de alta; un `INSERT` directo los saltea.
- Cuotas (TODO 11): la correlatividad y el vencimiento de `CUOTA_ARANCEL` y el monto de `CUOTA_SOCIAL` sólo los cumplen los SP; un `INSERT` o `UPDATE` directo los saltea.

### 4.3 Aplicación host

Enunciado (funcionalidad e): aplicación sencilla en un lenguaje host que acceda a la base y haga una operación con transacciones.

Hay un MVP en `app-host/` (Next.js, TypeScript): lista, inserta, edita y borra filas de las 21 tablas, muestra las cuatro vistas, ejecuta los SP de `03` y `04` (incluido el alta de áreas y el cambio de estado) y tiene una consola SQL. Features, backlog y limitaciones en [APP_HOST_FEATURES.md](APP_HOST_FEATURES.md); cómo correrla en `app-host/README.md` y en CLAUDE.md §8.

- **No valida a propósito:** todo valor viaja a la base y los triggers, constraints y SP son los que rechazan; los errores de SQL Server se muestran tal cual. Sirve para probar los rechazos 50001 a 50015 y los `CK_*`.
- **La lógica de negocio vive en la base:** un cambio de comportamiento se hace en `scripts/`, no en la app. Si cambia la firma de un SP, hay que actualizarla a mano en `app-host/lib/procedures.ts`.
- **Requiere** la base creada con `00` a `05`, Node 20+, LocalDB y el ODBC Driver 17/18 para SQL Server (sólo Windows).
- **Pendiente:** decidir qué operación con transacciones se muestra en la entrega (los SP de alta y de inscripción corren en una transacción) y el backlog opcional de la app.

### 4.4 Entregables de documentación (enunciado a–e)

- a) Modelo ER y modelo relacional: el ER está en el link de Drive citado en TP_BBDD_Grupo_4.md §3.1. El modelo relacional de §4.1 no refleja los cambios posteriores: tablas nuevas, orden de implementación y los CHECK agregados (TODO 12).
- b) Supuestos: ya están en TP_BBDD_Grupo_4.md §2 (H1–H14) y en los TODO de `pendientes_diseno.md`. Falta juntar los supuestos propios del código: mapeo y porcentajes de categorías, vencimiento de la cuota, "año pasado", `cod_area` como texto, `SP_LIQUIDAR_CUOTA_ARANCEL` mensual.
- c) Diseño físico: falta documentarlo. Aún no hay documento.
- d) Restricciones adicionales: TP_BBDD_Grupo_4.md §3.2 está vacío. Hay que completarlo con las de §4.2, los triggers y SP implementados y las limitaciones del TODO 10 (TODO 12).
- e) Código de SP y triggers: está en `03_logica_socios_cuotas.sql` y `04_logica_areas_profesionales.sql`. Falta revisarlo contra §4.2 cuando se cierren los TODO abiertos. La aplicación host (MVP) está en `app-host/` (§4.3).

## 5. Decisiones: resumen

Todas en [pendientes_diseno.md](pendientes_diseno.md).

| TODO | Tema | Estado |
|---|---|---|
| 1 | Periodicidades de `meses_por_cuota` | Cerrado: `IN (1, 2, 3, 6, 12)`. |
| 2 | Jerarquía de `ACTIVIDAD` | Aplicado (triggers y SP de alta). Totalidad sólo vía SP. |
| 3 | Estado de mantenimiento de las áreas | Cerrado: historial (`ESTADO_AREA` + `HISTORIAL_AREA_ESTADO`) con la lista de estados confirmada. |
| 4 | Tipos de `PROFESIONAL.dni` y `AREA.cod_area` | Aplicado: `dni` `INT` con `dni > 0`; `cod_area` `VARCHAR(20)` con CHECK de formato. |
| 5 | Baja de inscripciones al cambiar categoría (H12) | Cerrado: `estado` y `fecha_baja` en `INSCRIPCION`, PK con `fecha_inscripcion`; la baja es automática y conserva el historial. |
| 6 | Categorías y `nro_orden` | Aplicado: `infantiles/mayores/vitalicios` y titular en 0. |
| 7 | Vencimiento de la cuota social | Cerrado: último día del mes. |
| 8 | "Todas las gratuitas" sin actividades y "año pasado" | Parcial: el caso vacío no devuelve filas (decidido); falta confirmar "año pasado". |
| 9 | Consultas 1 y 2 como vistas | Aplicado: vistas con `YEAR(GETDATE())`. |
| 10 | Participaciones totales sin garantizar | Parcial: `DICTADO` → área por SP; el resto, limitación documentada. |
| 11 | Restricciones de cuotas que sólo cubren los SP | Aplicado: puesta al día en `SP_LIQUIDAR_CUOTA_ARANCEL`; el resto, limitación documentada. |
| 12 | Inconsistencias en TP_BBDD_Grupo_4.md (§3.2, §5.1.1, §5.1.15, §4.1) | **Abierto**; requiere OK del grupo. |
| 13 | Un dictado sólo en un área operativa durante todo su período | Cerrado (definitivo). |

## 6. Problemas conocidos

- `02_insercion_datos.sql`: sólo corre sobre base recién creada por `00`. Los `DELETE` van en orden inverso de dependencias, pero la re-carga falla igual por la `IDENTITY` de `GRUPO_FAMILIAR`. La numeración de `nro_socio_base` arranca en 1 (no hay `DBCC CHECKIDENT ... RESEED 0`, que rompía la FK de `SOCIO`).
- `05_datos_logica_socios_cuotas.sql`: no borra nada. Si se corre sobre una base con datos, falla por claves duplicadas. Correr siempre después de `00`.
- `TR_SOCIO_TITULAR_CATEGORIA` tiene `'infantiles'` literal y `CK_CATEGORIA_NOMBRE` tiene las tres categorías. Si cambian los nombres, hay que actualizar ambos.
- Un `INSERT` directo en `ACTIVIDAD` o borrar una subentidad puede dejar una actividad sin clasificar (la totalidad la cubren los `SP_ALTA_ACTIVIDAD_*`).
- Los SP de alta (`SP_ALTA_GRUPO_FAMILIAR`, `SP_ALTA_DICTADO`, `SP_ALTA_ACTIVIDAD_*`) son la única vía que garantiza la participación total; un `INSERT` directo la saltea.
- Los SP de alta hacen `ROLLBACK` incondicional si hay una transacción abierta; si se los llama dentro de una transacción externa, la revierten completa.
- `SP_ALTA_DICTADO` ahora exige `@cod_area`: cualquier llamado anterior sin ese parámetro falla.
- Una reinscripción tras una baja crea una fila nueva y exige otra `fecha_inscripcion` (la PK la incluye); dos inscripciones en la misma fecha chocan por la PK.
- Las vistas de las consultas dependen de `GETDATE()`: sin datos del año actual o del anterior devuelven vacío o ceros.
- Un área cargada con un `INSERT` directo en `AREA` no tiene historial: `VW_ESTADO_ACTUAL_AREA` la muestra con estado `NULL`. Un área también queda sin estado si se borra su último registro de `HISTORIAL_AREA_ESTADO`.
- `AREA.estado_mantenimiento` ya no existe: cualquier consulta o `INSERT` que la use falla. El estado se lee de `VW_ESTADO_ACTUAL_AREA`.

## 7. Próximos pasos sugeridos

1. Llevar al grupo la consulta de [consulta_decisiones_abiertas.md](consulta_decisiones_abiertas.md) (TODO 8 y 9) y el TODO 12, que incluye redactar H12 y H15 y reflejar los TODO 3, 5 y 13 en §4.1 y §4.2.
2. Con las respuestas, ajustar, si cambia, el criterio de "año pasado" de la consulta 2 (TODO 8).
3. Completar los entregables a–d (§4.4). Conviene empezar por d (restricciones adicionales) y b (supuestos), que se pueden redactar con lo ya implementado.
4. Resolver con el grupo las inconsistencias de TP_BBDD_Grupo_4.md (TODO 12) antes de entregar.
5. Elegir con el grupo la operación con transacciones que se muestra en la aplicación host (§4.3) y revisar el backlog opcional de [APP_HOST_FEATURES.md](APP_HOST_FEATURES.md).
