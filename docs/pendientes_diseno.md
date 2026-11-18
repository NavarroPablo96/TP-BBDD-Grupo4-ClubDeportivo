# Pendientes de revisión del diseño

Registro de decisiones de diseño: qué está abierto, qué se decidió y qué quedó aplicado en los scripts. El estado general del proyecto está en [SPEC_ESTADO.md](SPEC_ESTADO.md). La consulta redactada para el grupo (TODO 8 y 9) está en [consulta_decisiones_abiertas.md](consulta_decisiones_abiertas.md).

## Resumen

| TODO | Tema | Estado |
|---|---|---|
| 1 | Periodicidades de `meses_por_cuota` | Cerrado |
| 2 | Jerarquía de `ACTIVIDAD` | Aplicado (con limitación) |
| 3 | Estado de mantenimiento de las áreas (historial) | Cerrado: historial con la lista de estados confirmada |
| 4 | Tipos de `PROFESIONAL.dni` y `AREA.cod_area` | Aplicado |
| 5 | Baja de inscripciones al cambiar de categoría (H12) | Cerrado: se deja la baja automática con historial |
| 6 | Categorías y `nro_orden` | Aplicado |
| 7 | Vencimiento de la cuota social | Cerrado |
| 8 | Consulta 2: "todas las gratuitas" y "año pasado" | Parcial: caso vacío decidido (no devuelve filas); falta confirmar "año pasado" |
| 9 | Consultas 1 y 2 como vistas | Aplicado (vistas con `YEAR(GETDATE())`); falta confirmar el criterio de la consulta 2 (ver TODO 8) |
| 10 | Participaciones totales sin garantizar | Parcial: `DICTADO` → área por SP; el resto, limitación documentada |
| 11 | Restricciones de cuotas que sólo cubren los SP | Aplicado: puesta al día en `SP_LIQUIDAR_CUOTA_ARANCEL`; el resto, limitación documentada |
| 12 | Inconsistencias en TP_BBDD_Grupo_4.md | **Abierto** (requiere OK del grupo) |
| 13 | Un dictado sólo en un área operativa durante todo su período | Cerrado (definitivo) |

Los TODO 10 a 12 surgieron de comparar `TP_BBDD_Grupo_4.md` (§4.1 y §4.2) con los scripts. Los TODO 3, 5, 10, 11 y 13 se resolvieron con decisiones del usuario.

---

# Abiertos

## TODO 8: Criterio de "todas las gratuitas" sin actividades gratuitas

**Estado:** PARCIAL. El criterio del caso vacío lo decidió el usuario y está aplicado; falta confirmar "año pasado" con el grupo.

- Decidido: si no hay filas para mostrar, no se muestra nada. `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR` usa `INNER JOIN` y sólo lista las categorías con al menos un socio que cumple. Sin actividades gratuitas ("todas" no se cumple en vacío) o sin socios que cumplan, no devuelve filas. Esto cambia el resultado anterior, que mostraba todas las categorías con 0.
- Pendiente: "año pasado" se interpreta como `YEAR(GETDATE()) - 1` sobre `fecha_inscripcion`.

- [x] Definir el criterio del caso vacío: la vista no devuelve filas (prueba S en `05`).
- [ ] Confirmar con el equipo que "año pasado" refiere al año de `fecha_inscripcion`.

## TODO 9: Consultas 1 y 2 del enunciado como vistas

**Estado:** APLICADO por decisión del usuario: vistas en `03_logica_socios_cuotas.sql` que usan `YEAR(GETDATE())`. Antes fueron vistas, después SP con parámetro `@anio`, y ahora vuelven a ser vistas para seguir el enunciado al pie de la letra ("año en curso" y "año pasado"). Se eliminan los SP anteriores con `DROP PROCEDURE IF EXISTS`.

- `VW_TITULARES_DEUDA_ANIO_ACTUAL`: titulares con deuda `monto_a_pagar - ISNULL(monto_abonado, 0) > 0` en las cuotas sociales de `YEAR(GETDATE())`, con importe total e integrantes del grupo.
- `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`: por categoría, socios con inscripciones de `YEAR(GETDATE()) - 1` (`fecha_inscripcion`) que cubren todas las filas de `ACTIVIDAD_GRATUITA`. Sólo muestra las categorías con al menos un socio que cumple, así que sin actividades gratuitas no devuelve filas (TODO 8). Cuenta también las inscripciones dadas de baja (TODO 5).
- Para que los resultados esperados no dependan del año en que se corra, los períodos de `VALOR_CUOTA_SOCIAL` de `02` y las fechas de `05` son relativos al año actual.

- [x] Decidir: vista para cada consulta, con `YEAR(GETDATE())` y `YEAR(GETDATE()) - 1`.
- [x] Reemplazar los SP por las vistas y actualizar `02` y `05`.
- [ ] Confirmar con el equipo el criterio de la consulta 2 (junto con el TODO 8).

## TODO 10: Participaciones totales sin garantizar

**Estado:** PARCIAL por decisión del usuario. Se resolvió con SP la participación de `DICTADO` en `SE_DESARROLLA_EN`; las demás quedan como limitación documentada. TP_BBDD_Grupo_4.md §4.1 exige participación total ("debe estar") en estos casos:

| Restricción de §4.1 | Cómo está hoy |
|---|---|
| l.157: toda `ACTIVIDAD` debe estar en `HABILITADA_PARA` | Limitación: no se garantiza. `SP_ALTA_ACTIVIDAD_*` no cargan habilitaciones. |
| l.163: todo `PROFESIONAL` debe estar en `PUEDE_DESEMPENIARSE_EN` | Limitación: no se garantiza. |
| l.169: toda `AREA` debe estar en `APTA_PARA` | Limitación: no se garantiza. |
| Toda `AREA` debe estar en `HISTORIAL_AREA_ESTADO` (TODO 3) | `SP_ALTA_AREA`. Un `INSERT` directo en `AREA` lo saltea. |
| l.188: todo `DICTADO` debe estar en `SE_DESARROLLA_EN` | Resuelto por SP: `SP_ALTA_DICTADO` recibe `@cod_area` y carga el área en la misma transacción. Un `INSERT` directo lo saltea. |
| l.136: todo `GRUPO_FAMILIAR` debe estar en `SOCIO` | `SP_ALTA_GRUPO_FAMILIAR` y `TR_SOCIO_BAJA_GRUPO`. Un `INSERT` directo los saltea. |
| l.177 y l.182: todo `DICTADO` debe tener día y profesional | `SP_ALTA_DICTADO`. Un `INSERT` directo lo saltea. |
| l.151: jerarquía total de `ACTIVIDAD` | `SP_ALTA_ACTIVIDAD_*` (ver TODO 2). Un `INSERT` directo, o borrar una subentidad, la saltea. |

Son participaciones circulares: un trigger de `INSERT` bloquearía las propias altas, así que sólo se pueden resolver con SP de alta (que cargan las filas relacionadas en una transacción) o documentarse como limitación.

Opciones para las cuatro primeras filas:
- **A:** ampliar los SP de alta. Por ejemplo `SP_ALTA_DICTADO` con `@cod_area`, y SP de alta de `PROFESIONAL` y `AREA` con su actividad. Lo difícil es `ACTIVIDAD` ↔ `HABILITADA_PARA`, que necesita una lista de categorías (varias filas) como parámetro.
- **B:** documentarlas como limitación, igual que `GRUPO_FAMILIAR`.

- [x] Decidir: sólo `DICTADO` → área por SP; el resto, limitación.
- [x] `SP_ALTA_DICTADO` con `@cod_area` y prueba R en `05`.
- [ ] Registrar las limitaciones (ACTIVIDAD, PROFESIONAL y AREA, y los `INSERT` directos) en la sección de restricciones adicionales de la resolución (entregable d).

## TODO 11: Restricciones de cuotas que sólo cubren los SP

**Estado:** APLICADO por decisión del usuario: "puesta al día" en `SP_LIQUIDAR_CUOTA_ARANCEL`, sin trigger nuevo. El resto queda como limitación documentada.

- **Correlatividad de las cuotas de arancel:** `SP_LIQUIDAR_CUOTA_ARANCEL` genera ahora todas las cuotas vencidas hasta el mes indicado que falten (no sólo la del mes), así que saltear una corrida mensual ya no deja huecos en `nro_cuota`. Sigue siendo idempotente. Prueba Q en `05`.
- **Regla de vencimiento:** se mantiene la de H9 (la cuota n vence `(n - 1) × meses_por_cuota` meses después de la inscripción; la primera vence en la fecha de inscripción). §4.2 l.219 dice "la cuota k vence a los k × `meses_por_cuota` meses", que contradice H9: se registra en el TODO 12 para que el grupo corrija el texto.
- **Limitación:** un `INSERT` o `UPDATE` directo en `CUOTA_ARANCEL` puede saltear la correlatividad y el vencimiento (el DDL sólo tiene `CHECK (nro_cuota > 0)`).
- **Cuota social (§4.2 l.217):** el monto lo calcula sólo `SP_LIQUIDAR_CUOTA_SOCIAL` y se fija al generar (H8). Un trigger no podría recalcularlo sin romper H8; queda documentado como limitación.

- [x] Decidir: puesta al día en el SP, sin trigger.
- [x] Implementar la puesta al día y la prueba Q.
- [ ] Registrar las limitaciones en la sección de restricciones adicionales de la resolución (entregable d).

## TODO 12: Inconsistencias en la resolución entregada (TP_BBDD_Grupo_4.md)

**Estado:** ABIERTO. Es la resolución entregada por el grupo (fuente principal del diseño), así que no se modifica sin el OK del equipo. Según CLAUDE.md §1, las contradicciones se señalan y se consultan.

- **§3.2 (restricciones adicionales) está vacío.** Es el entregable d. Hay que completarlo con las de §4.2 y los triggers y SP implementados.
- **§5.1.1 `CUOTA_SOCIAL` lista el atributo `deuda`**, pero §4.1, §4.2 l.216 y el DDL dicen que la deuda no se almacena.
- **§5.1.15 `DICTADO` está desactualizada**: el modelo ahora tiene `DICTADO_DIA` como tabla separada.
- **§4.1 no refleja los cambios posteriores**: tablas nuevas, orden de implementación y los CHECK agregados (`CK_CATEGORIA_NOMBRE`, `CK_SOCIO_NRO_ORDEN`, `CK_AREA_COD_AREA`, entre otros). Es el entregable a. En particular, por el TODO 5:
  - `INSCRIPCION` suma `estado` y `fecha_baja`, y su PK incluye `fecha_inscripcion`.
  - `CUOTA_ARANCEL` suma `fecha_inscripcion` a su PK y a la FK hacia `INSCRIPCION`.
  - `AREA` pierde `estado_mantenimiento` y se agregan `ESTADO_AREA (nombre_estado)` y `HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)` con PK `(cod_area, fecha_desde)` (TODO 3). El modelo pasa a 21 tablas.
  - Hay que agregar a §4.2 la restricción "un área tiene un único estado por `fecha_desde`" y a §5 el análisis de normalización de las dos tablas nuevas.
  - Hay que agregar a §4.2 (y como H15) la regla del TODO 13: *"Un dictado sólo puede desarrollarse en un área que esté en estado `Operativa` durante todo su período; un área sin estado registrado no se restringe."*
- **H9 contradice §4.2 l.219**: H9 dice que la primera cuota vence en la fecha de inscripción; §4.2 dice que la cuota k vence a los k × `meses_por_cuota` meses. Los scripts siguen H9.
- **Las consultas 1 y 2 son vistas** (`VW_TITULARES_DEUDA_ANIO_ACTUAL` y `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`); la resolución no las define como SP ni como vistas.

- [ ] Confirmar con el grupo qué se corrige en la resolución y qué se documenta aparte.

---

# Cerrados y aplicados

## TODO 1: Valores permitidos de `meses_por_cuota`

**Estado:** CERRADO. Lista cerrada `IN (1, 2, 3, 6, 12)` (`CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA`), confirmada por el usuario.

- [x] Acordar una lista cerrada de valores.
- [x] Aplicar el `CHECK` en `01_creacion_tablas.sql`.

## TODO 2: Jerarquía de actividades

**Estado:** APLICADO en `03_logica_socios_cuotas.sql`, con pruebas H–K en `05_datos_logica_socios_cuotas.sql`.

- Coherencia y exclusividad: `TR_ACTIVIDAD_ARANCELADA_TIPO` (50011) exige `tipo = 'A'` y `TR_ACTIVIDAD_GRATUITA_TIPO` (50012) exige `tipo = 'G'`. Con ambos, una actividad no puede estar en las dos subentidades.
- `TR_ACTIVIDAD_TIPO_INMUTABLE` (50013) impide cambiar `tipo` si ya tiene subentidad. Una actividad nunca cambia de gratuita a arancelada.
- Totalidad: `SP_ALTA_ACTIVIDAD_ARANCELADA` y `SP_ALTA_ACTIVIDAD_GRATUITA` crean actividad y subentidad en una transacción.
- Limitación vigente: borrar una subentidad, o un `INSERT` directo en `ACTIVIDAD`, puede dejar una actividad sin clasificar. No se agregó trigger de `DELETE` porque rompería la recarga de `02`. Ver TODO 10.

## TODO 3: Estado de mantenimiento de las áreas (historial)

**Estado:** CERRADO por decisión del usuario: historial de estados con la lista `Operativa`, `En mantenimiento`, `Fuera de servicio` confirmada. El enunciado no define los estados de mantenimiento ni si se guarda su historia, y no se admiten atributos multivaluados, así que el estado salió de `AREA` y pasó a dos tablas nuevas (cambia el modelo de TP_BBDD_Grupo_4.md §4.1; ver TODO 12).

Modelo (DER del grupo: N:M entre `AREA` y `ESTADO_AREA`, con `fecha_desde` como clave de la relación):

```
ESTADO_AREA (nombre_estado)                                   PK = CK = {nombre_estado}
HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)  PK = CK = {(cod_area, fecha_desde)}  FK = {cod_area, nombre_estado}
```

- `ESTADO_AREA` es el catálogo de estados posibles (`Operativa`, `En mantenimiento`, `Fuera de servicio`, cargados en `02`).
- `HISTORIAL_AREA_ESTADO` registra desde qué fecha un área está en un estado. Un área puede volver a un estado anterior (otra `fecha_desde`).
- Restricción adicional: **un área tiene un único estado por `fecha_desde`**. Una N:M con `fecha_desde` como clave no lo expresa (permitiría dos estados distintos en la misma fecha), así que la clave candidata real es `(cod_area, fecha_desde)` y `nombre_estado` depende de ella.
- El estado vigente de un área es el de mayor `fecha_desde` que no sea futura: `VW_ESTADO_ACTUAL_AREA` (en `04`). Sin `fecha_hasta`, para evitar huecos y superposiciones entre períodos.
- `SP_ALTA_AREA` crea el área y su primer estado en una transacción; `SP_CAMBIAR_ESTADO_AREA` agrega un nuevo estado (sin fecha rige la actual).
- Participación total de `AREA` en `HISTORIAL_AREA_ESTADO` (§4.1): sólo la garantiza `SP_ALTA_AREA`; un `INSERT` directo en `AREA` la saltea y el área figura sin estado (limitación, ver TODO 10).
- La app host ofrece los dos SP y la vista, y las tablas nuevas con sugerencias por FK.
- Pruebas T–X en `05`.

- [x] Decidir el modelo (catálogo + historial) y la PK `(cod_area, fecha_desde)`.
- [x] Implementar tablas, catálogo, SP, vista, datos de prueba y pruebas.
- [x] Adaptar la app host.
- [x] Confirmar la lista de estados.
- [ ] Reflejar las dos tablas nuevas y la restricción de la fecha en §4.1 y §4.2 de la resolución, y su normalización en §5 (TODO 12).

## TODO 4: Tipos de `PROFESIONAL` y `AREA`

**Estado:** APLICADO. Como `dni` y `cod_area` son PK (únicos), no se agregó `UNIQUE` redundante. Se probó `dni` como `VARCHAR(12)` y el usuario decidió volver a `INT`.

- [x] `PROFESIONAL.dni` `INT` con `CK_PROFESIONAL_DNI CHECK (dni > 0)`.
- [x] `AREA.capacidad` con `CHECK (capacidad >= 0)`.
- [x] `AREA.cod_area` `VARCHAR(20)`; `CK_AREA_COD_AREA` exige no vacío y sin espacios al inicio ni al final.
- [x] FK de `cod_area` (`APTA_PARA`, `SE_DESARROLLA_EN`) y datos de prueba ajustados a texto.

## TODO 5: Baja de inscripciones al cambiar de categoría (H12)

**Estado:** CERRADO por decisión del usuario: se deja como está implementado (baja automática con historial). Es una hipótesis propia del grupo (H12), no un requisito del enunciado.

Fundamento:
- El enunciado sólo exige verificar la categoría **al inscribirse** ("siendo necesario verificar que la categoría del socio coincida con la categoría asociada a la actividad en la que se inscribe"). No dice nada sobre cambios de categoría ni sobre bajas.
- H6 y H9 hablan de inscripción "vigente": hace falta algún modo de terminar una inscripción, si no las cuotas de arancel se generarían para siempre.
- No se pueden borrar las filas: `CUOTA_ARANCEL` tiene FK hacia `INSCRIPCION` y la consulta 2 necesita el historial de inscripciones del año pasado.
- Texto propuesto para H12: *"El enunciado verifica la categoría sólo al inscribir; asumimos además que al cambiar la categoría de un socio se dan de baja sus inscripciones incompatibles con la nueva categoría, conservando el historial."*

Implementado:
- `INSCRIPCION` tiene `estado` (`'Activa'` / `'Baja'`, default `'Activa'`) y `fecha_baja`, con `CK_INSCRIPCION_ESTADO` y `CK_INSCRIPCION_FECHA_BAJA`.
- La PK de `INSCRIPCION` pasó a `(nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)`, para que un socio dado de baja pueda reinscribirse en la misma actividad (H6). La FK y la PK de `CUOTA_ARANCEL` incluyen ahora `fecha_inscripcion`.
- `TR_INSCRIPCION_VIGENTE_UNICA` (50014): a lo sumo una inscripción `Activa` por socio y actividad (H6). Es un trigger y no un índice único filtrado porque `sqlcmd` corre con `QUOTED_IDENTIFIER OFF`.
- `TR_SOCIO_CAMBIO_CATEGORIA` (sobre `SOCIO`): al cambiar `nombre_categoria` pasa a `Baja` las inscripciones activas no habilitadas para la nueva categoría y conserva las compatibles. `fecha_baja` es la fecha actual (o la de inscripción si es posterior).
- `TR_INSCRIPCION_CATEGORIA_HABILITADA` valida sólo las inscripciones `Activa`, para que la baja no se rechace a sí misma.
- `SP_LIQUIDAR_CUOTA_ARANCEL` deja de generar cuotas para las inscripciones dadas de baja (sólo las vencidas hasta la `fecha_baja`); las ya generadas se mantienen.
- Pruebas O, P1 y P2 en `05`.

Criterios adoptados:
- Una inscripción dada de baja deja de generar cuotas de arancel; las ya generadas se mantienen.
- Las inscripciones dadas de baja siguen contando en la consulta 2 (el socio estuvo inscripto ese año).
- Reinscribirse crea una fila nueva (otra `fecha_inscripcion`); no se reactiva la fila de baja. Como la fecha es parte de la PK, no se puede reinscribir el mismo día de una inscripción anterior en esa actividad (error 2627).

- [x] Decidir agregar estado / fecha de baja a `INSCRIPCION` (cambio de modelo).
- [x] Decidir el efecto sobre la PK y la reinscripción (H6): la PK suma `fecha_inscripcion`.
- [x] Implementar el trigger sobre `SOCIO` y ajustar `SP_INSCRIBIR_ACTIVIDAD`, `SP_LIQUIDAR_CUOTA_ARANCEL` y la consulta 2.
- [x] Agregar pruebas (cambio de categoría con inscripciones compatibles e incompatibles, reinscripción, doble inscripción activa).
- [x] Cerrar la decisión: se deja como está.
- [ ] Reflejar el cambio en §4.1 de la resolución y redactar H12 con el texto propuesto (TODO 12).

## TODO 13: Un dictado sólo en un área operativa durante todo su período

**Estado:** CERRADO por decisión del usuario (definitivo). Es una hipótesis propia del grupo: ni el enunciado ni §4.2 relacionan el estado de mantenimiento con los dictados.

Regla: *un dictado no puede desarrollarse en un área que esté `En mantenimiento` o `Fuera de servicio` en algún momento de su período (`fecha_desde` a `fecha_fin`).*

Implementado en `04_logica_areas_profesionales.sql`, con el mismo patrón que `TR_DICTADO_SOLAPAMIENTO_*`:
- `VW_AREA_ESTADO_PERIODO`: intervalo de vigencia de cada estado (desde su `fecha_desde` hasta el día anterior al siguiente estado; el último queda abierto).
- `VW_CONFLICTOS_ESTADO_DICTADO`: pares (dictado, área) cuyo período se solapa con un intervalo de estado distinto de `Operativa`.
- `TR_DICTADO_AREA_OPERATIVA_SE_DESARROLLA_EN`, `TR_DICTADO_AREA_OPERATIVA_DICTADO` y `TR_DICTADO_AREA_OPERATIVA_HISTORIAL` (error 50015): al asignar el área, al cambiar las fechas del dictado y al cambiar el historial de estados (incluye `SP_CAMBIAR_ESTADO_AREA`).
- Pruebas Y1, Y2 y Z en `05`.

Criterios:
- Un área puede crearse con cualquier estado (no se fuerza `Operativa`): si nace en mantenimiento, no recibe dictados hasta pasar a `Operativa`.
- Un área sin historial (cargada con un `INSERT` directo en `AREA`) no se restringe: no hay estado conocido. Tampoco se restringe un dictado cuyo período empieza antes del primer estado registrado.
- Un cambio de estado retroactivo que choque con un dictado ya cargado se rechaza.
- El estado "operativo" es el nombre `'Operativa'` escrito en la vista, igual que `'infantiles'` en `TR_SOCIO_TITULAR_CATEGORIA`. Si se agregan estados que también permitan dictados, hay que tocar `VW_CONFLICTOS_ESTADO_DICTADO` (o agregar una columna a `ESTADO_AREA`, que cambia el modelo).
- Los triggers revisan toda la vista, como los de solapamiento.

- [x] Decidir la regla (período completo, sin forzar `Operativa` al crear).
- [x] Implementar vistas, triggers y pruebas; mostrar las vistas en la app host.
- [x] Confirmar la regla: definitiva.
- [ ] Redactarla como H15 y agregarla a §4.2 de la resolución (TODO 12).

## TODO 6: Categorías y `nro_orden`

**Estado:** APLICADO en `01`, `02`, `03` y `05`. Categorías `infantiles` (-30.00), `mayores` (0.00) y `vitalicios` (-15.00). Mapeo: Infantil → infantiles, Juvenil y Adulto → mayores, Jubilado → vitalicios. El mapeo y los porcentajes son decisión del usuario; no figuran en el enunciado.

- [x] Nomenclatura corregida en `CATEGORIA`, `02`, `03` y `05`.
- [x] Titulares de `02` con `nro_orden = 0`.
- [x] `CK_CATEGORIA_NOMBRE`: sólo `infantiles`, `mayores`, `vitalicios` (§4.2). Si el grupo cambia los nombres, hay que actualizar este CHECK y `TR_SOCIO_TITULAR_CATEGORIA`.
- [x] `CK_SOCIO_NRO_ORDEN`: `nro_orden >= 0`. Que cada grupo tenga exactamente un titular lo cubren `SP_ALTA_GRUPO_FAMILIAR` y `TR_SOCIO_BAJA_GRUPO` (ver TODO 10).

## TODO 7: Fecha de vencimiento de la cuota social

**Estado:** CERRADO. `SP_LIQUIDAR_CUOTA_SOCIAL` usa el último día del mes, confirmado por el usuario.

- [x] Confirmar la fecha de vencimiento (el enunciado no la define).
