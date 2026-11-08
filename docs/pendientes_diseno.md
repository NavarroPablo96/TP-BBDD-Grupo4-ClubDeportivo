# Pendientes de revisión del diseño

Registro de decisiones de diseño: qué está abierto, qué se decidió y qué quedó aplicado en los scripts. El estado general del proyecto está en [SPEC_ESTADO.md](SPEC_ESTADO.md). La consulta redactada para el grupo (TODO 3, 5, 8 y 9) está en [consulta_decisiones_abiertas.md](consulta_decisiones_abiertas.md).

## Resumen

| TODO | Tema | Estado |
|---|---|---|
| 1 | Periodicidades de `meses_por_cuota` | Cerrado |
| 2 | Jerarquía de `ACTIVIDAD` | Aplicado (con limitación) |
| 3 | Dominio de `AREA.estado_mantenimiento` | **Abierto** |
| 4 | Tipos de `PROFESIONAL.dni` y `AREA.cod_area` | Aplicado |
| 5 | Baja de inscripciones al cambiar de categoría (H12) | **Abierto** |
| 6 | Categorías y `nro_orden` | Aplicado |
| 7 | Vencimiento de la cuota social | Cerrado |
| 8 | Consulta 2: "todas las gratuitas" y "año pasado" | **Abierto** (supuesto aplicado) |
| 9 | Consultas 1 y 2 como stored procedures | Decidido; falta confirmar el criterio de año (ver TODO 8) |
| 10 | Participaciones totales sin garantizar | **Abierto** (no consultado aún) |
| 11 | Restricciones de cuotas que sólo cubren los SP | **Abierto** (no consultado aún) |
| 12 | Inconsistencias en TP_BBDD_Grupo_4.md | **Abierto** (requiere OK del grupo) |

Los TODO 10 a 12 surgieron de comparar `TP_BBDD_Grupo_4.md` (§4.1 y §4.2) con los scripts. Todavía no están en la consulta para el grupo.

---

# Abiertos

## TODO 3: Definir dominio de `AREA.estado_mantenimiento`

**Estado:** ABIERTO. El usuario lo va a consultar. Hoy es `VARCHAR(30) NOT NULL` sin valores permitidos, porque el enunciado no los define (`-- TODO` en `01_creacion_tablas.sql`). Propuesta sin confirmar: `CHECK` con `'Operativa'`, `'En mantenimiento'`, `'Fuera de servicio'`.

- [ ] Acordar la lista de estados y reemplazar el tipo libre por un `CHECK` o una tabla de dominio.
- [ ] Confirmar que un área tiene un solo estado a la vez: no se admiten atributos multivaluados, así que varios estados simultáneos o un historial exigirían una tabla aparte (`ESTADO_AREA`) y un cambio de modelo.

## TODO 5: Baja de inscripciones al cambiar de categoría (H12)

**Estado:** ABIERTO. El usuario lo va a consultar; se inclina por agregar estado a `INSCRIPCION`. No hay nada implementado en `03_logica_socios_cuotas.sql`.

H12 dice que al cambiar la categoría de un socio se dan de baja sus inscripciones a actividades no habilitadas para la nueva categoría. `INSCRIPCION` no tiene campo de estado ni fecha de baja.

Propuesta sin confirmar:
- Columnas `estado` (`'Activa'` / `'Baja'`) y `fecha_baja` en `INSCRIPCION`, más un trigger `AFTER UPDATE` sobre `SOCIO`. Cambia el modelo de TP_BBDD_Grupo_4.md §4.1.
- `SP_LIQUIDAR_CUOTA_ARANCEL` deja de generar cuotas para las inscripciones dadas de baja; las ya generadas se mantienen.
- Las inscripciones dadas de baja siguen contando en la consulta 2.
- H6 habla de "una inscripción **vigente** por actividad", pero la PK de `INSCRIPCION` es `(nro_socio_base, nro_orden, cod_actividad)`. Con estado, un socio dado de baja no podría volver a inscribirse en la misma actividad. Hay que decidir si eso es aceptable o si la PK cambia (por ejemplo, sumando `fecha_inscripcion`), lo que también afecta la FK de `CUOTA_ARANCEL`.

- [ ] Decidir si la baja borra filas de `INSCRIPCION` o si se agrega estado / fecha de baja (cambio de modelo).
- [ ] Decidir el efecto sobre la PK y la reinscripción (H6).
- [ ] Implementar el trigger `AFTER UPDATE` sobre `SOCIO` según la decisión y ajustar `SP_LIQUIDAR_CUOTA_ARANCEL`, `SP_INSCRIBIR_ACTIVIDAD` y `SP_CONSULTA_SOCIOS_GRATUITAS`.
- [ ] Agregar pruebas (cambio de categoría con inscripciones compatibles e incompatibles).

## TODO 8: Criterio de "todas las gratuitas" sin actividades gratuitas

**Estado:** ABIERTO. El usuario lo va a consultar. Supuesto aplicado: `SP_CONSULTA_SOCIOS_GRATUITAS` no cuenta a nadie si no hay actividades gratuitas ("todas" no se cumple en vacío).

- [ ] Confirmar el criterio con el equipo.
- [ ] Confirmar si "año pasado" refiere al año de `fecha_inscripcion`.

## TODO 9: Consultas 1 y 2 del enunciado como stored procedures

**Estado:** decidido por el usuario: stored procedures con parámetro `@anio`, implementados en `03_logica_socios_cuotas.sql`. Antes eran vistas con `GETDATE()`.

- `SP_CONSULTA_TITULARES_DEUDA (@anio)`: titulares con deuda `monto_a_pagar - ISNULL(monto_abonado, 0) > 0` en las cuotas sociales del año, con importe total e integrantes del grupo.
- `SP_CONSULTA_SOCIOS_GRATUITAS (@anio)`: por categoría, socios con inscripciones de ese año (`fecha_inscripcion`) que cubren todas las filas de `ACTIVIDAD_GRATUITA`. El llamador pasa el año anterior para cumplir el enunciado. Exige al menos una actividad gratuita (TODO 8).

- [x] Decidir: stored procedure para cada consulta.
- [x] Definir el parámetro de año y actualizar `03` y `05`.
- [ ] Confirmar con el equipo que el criterio de "año pasado" queda en el parámetro (junto con el TODO 8).

## TODO 10: Participaciones totales sin garantizar

**Estado:** ABIERTO. No consultado todavía. TP_BBDD_Grupo_4.md §4.1 exige participación total ("debe estar") en estos casos y los scripts no la garantizan:

| Restricción de §4.1 | Cómo está hoy |
|---|---|
| l.157: toda `ACTIVIDAD` debe estar en `HABILITADA_PARA` | No se garantiza. `SP_ALTA_ACTIVIDAD_*` no cargan habilitaciones. |
| l.163: todo `PROFESIONAL` debe estar en `PUEDE_DESEMPENIARSE_EN` | No se garantiza. |
| l.169: toda `AREA` debe estar en `APTA_PARA` | No se garantiza. |
| l.188: todo `DICTADO` debe estar en `SE_DESARROLLA_EN` | No se garantiza. `SP_ALTA_DICTADO` crea el día y el profesional, pero no el área. |
| l.136: todo `GRUPO_FAMILIAR` debe estar en `SOCIO` | `SP_ALTA_GRUPO_FAMILIAR` y `TR_SOCIO_BAJA_GRUPO`. Un `INSERT` directo los saltea. |
| l.177 y l.182: todo `DICTADO` debe tener día y profesional | `SP_ALTA_DICTADO`. Un `INSERT` directo lo saltea. |
| l.151: jerarquía total de `ACTIVIDAD` | `SP_ALTA_ACTIVIDAD_*` (ver TODO 2). Un `INSERT` directo, o borrar una subentidad, la saltea. |

Son participaciones circulares: un trigger de `INSERT` bloquearía las propias altas, así que sólo se pueden resolver con SP de alta (que cargan las filas relacionadas en una transacción) o documentarse como limitación.

Opciones para las cuatro primeras filas:
- **A:** ampliar los SP de alta. Por ejemplo `SP_ALTA_DICTADO` con `@cod_area`, y SP de alta de `PROFESIONAL` y `AREA` con su actividad. Lo difícil es `ACTIVIDAD` ↔ `HABILITADA_PARA`, que necesita una lista de categorías (varias filas) como parámetro.
- **B:** documentarlas como limitación, igual que `GRUPO_FAMILIAR`.

- [ ] Decidir A o B para cada restricción.
- [ ] Registrar las que queden como limitación en la sección de restricciones adicionales de la resolución (entregable d).

## TODO 11: Restricciones de cuotas que sólo cubren los SP

**Estado:** ABIERTO. No consultado todavía.

- **§4.2 l.219:** las cuotas de una inscripción se numeran en forma correlativa desde 1 y la cuota k vence a los k × `meses_por_cuota` meses de la fecha de inscripción. Hoy sólo lo cumplen `SP_INSCRIBIR_ACTIVIDAD` y `SP_LIQUIDAR_CUOTA_ARANCEL`; el DDL sólo tiene `CHECK (nro_cuota > 0)`. Un `INSERT` directo puede saltear la correlatividad o el vencimiento.
- **Riesgo operativo:** `SP_LIQUIDAR_CUOTA_ARANCEL` calcula `nro_cuota` a partir de los meses transcurridos (`meses_transcurridos / meses_por_cuota + 1`). Si no se corre en el mes en que vence una cuota, esa cuota no se genera y las siguientes quedan con un hueco en la numeración, lo que contradice la correlatividad.
- **§4.2 l.217:** la cuota social es la suma por integrante del monto base vigente afectado por el porcentaje de la categoría. Sólo la calcula `SP_LIQUIDAR_CUOTA_SOCIAL`; un `INSERT` o `UPDATE` directo en `CUOTA_SOCIAL` no se controla.

Opciones: trigger en `CUOTA_ARANCEL` que valide `nro_cuota` y `fecha_vencimiento` contra la inscripción; hacer que el SP genere también las cuotas faltantes de meses anteriores; o documentar como limitación. Para la cuota social, el monto es un dato derivado y fijado al generar (H8), así que un trigger no puede recalcularlo sin romper H8: lo razonable es documentarlo.

- [ ] Decidir trigger, SP que complete cuotas faltantes, o limitación documentada.
- [ ] Agregar pruebas de rechazo si se implementa.

## TODO 12: Inconsistencias en la resolución entregada (TP_BBDD_Grupo_4.md)

**Estado:** ABIERTO. Es la resolución entregada por el grupo (fuente principal del diseño), así que no se modifica sin el OK del equipo. Según CLAUDE.md §1, las contradicciones se señalan y se consultan.

- **§3.2 (restricciones adicionales) está vacío.** Es el entregable d. Hay que completarlo con las de §4.2 y los triggers y SP implementados.
- **§5.1.1 `CUOTA_SOCIAL` lista el atributo `deuda`**, pero §4.1, §4.2 l.216 y el DDL dicen que la deuda no se almacena.
- **§5.1.15 `DICTADO` está desactualizada**: el modelo ahora tiene `DICTADO_DIA` como tabla separada.
- **§4.1 no refleja los cambios posteriores**: tablas nuevas, orden de implementación y los CHECK agregados (`CK_CATEGORIA_NOMBRE`, `CK_SOCIO_NRO_ORDEN`, `CK_AREA_COD_AREA`, entre otros). Es el entregable a.

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

## TODO 4: Tipos de `PROFESIONAL` y `AREA`

**Estado:** APLICADO. Como `dni` y `cod_area` son PK (únicos), no se agregó `UNIQUE` redundante. Se probó `dni` como `VARCHAR(12)` y el usuario decidió volver a `INT`.

- [x] `PROFESIONAL.dni` `INT` con `CK_PROFESIONAL_DNI CHECK (dni > 0)`.
- [x] `AREA.capacidad` con `CHECK (capacidad >= 0)`.
- [x] `AREA.cod_area` `VARCHAR(20)`; `CK_AREA_COD_AREA` exige no vacío y sin espacios al inicio ni al final.
- [x] FK de `cod_area` (`APTA_PARA`, `SE_DESARROLLA_EN`) y datos de prueba ajustados a texto.

## TODO 6: Categorías y `nro_orden`

**Estado:** APLICADO en `01`, `02`, `03` y `05`. Categorías `infantiles` (-30.00), `mayores` (0.00) y `vitalicios` (-15.00). Mapeo: Infantil → infantiles, Juvenil y Adulto → mayores, Jubilado → vitalicios. El mapeo y los porcentajes son decisión del usuario; no figuran en el enunciado.

- [x] Nomenclatura corregida en `CATEGORIA`, `02`, `03` y `05`.
- [x] Titulares de `02` con `nro_orden = 0`.
- [x] `CK_CATEGORIA_NOMBRE`: sólo `infantiles`, `mayores`, `vitalicios` (§4.2). Si el grupo cambia los nombres, hay que actualizar este CHECK y `TR_SOCIO_TITULAR_CATEGORIA`.
- [x] `CK_SOCIO_NRO_ORDEN`: `nro_orden >= 0`. Que cada grupo tenga exactamente un titular lo cubren `SP_ALTA_GRUPO_FAMILIAR` y `TR_SOCIO_BAJA_GRUPO` (ver TODO 10).

## TODO 7: Fecha de vencimiento de la cuota social

**Estado:** CERRADO. `SP_LIQUIDAR_CUOTA_SOCIAL` usa el último día del mes, confirmado por el usuario.

- [x] Confirmar la fecha de vencimiento (el enunciado no la define).
