# Pendientes de revisión del diseño

## TODO 1: Definir los valores permitidos de `meses_por_cuota`

**Estado:** lista cerrada aplicada en `01_creacion_tablas.sql` por decisión del usuario (`IN (1, 2, 3, 6, 12)`). Pendiente de confirmación del grupo.

**Tabla:** `ACTIVIDAD_ARANCELADA`.

Definir qué periodicidades de cobro se permiten. Por ejemplo: mensual (`1`), bimestral (`2`), trimestral (`3`), semestral (`6`) o anual (`12`). Estos valores son ejemplos; todavía no constituyen una lista acordada.

Hasta definir la regla, se propone usar `CHECK (meses_por_cuota > 0)`, que permite cualquier entero positivo. El control `>= 0` también permitiría cero meses.

- [ ] Acordar si se admite cualquier cantidad positiva de meses o una lista cerrada de valores.
- [ ] Registrar los valores acordados y actualizar el `CHECK` si corresponde.
- [ ] Probar valores válidos e inválidos.

**Decisión del grupo:** pendiente.

## TODO 2: Garantizar la jerarquía de actividades

**Estado:** pendiente de definición e implementación con el grupo.

**Tablas:** `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA` y `ACTIVIDAD_GRATUITA`.

Las FK actuales garantizan que la actividad referenciada exista, pero no alcanzan para asegurar todas las reglas de la jerarquía:

- **Coherencia:** una actividad arancelada debe tener `tipo = 'A'` y una gratuita debe tener `tipo = 'G'`.
- **Exclusividad:** una actividad no puede pertenecer a ambas subentidades.
- **Totalidad:** toda actividad debe pertenecer a una de las dos subentidades.

### Pendientes

- [ ] Validar los `INSERT` y `UPDATE` en ambas subentidades para garantizar que el tipo de la actividad referenciada sea el correspondiente.
- [ ] Controlar los cambios de `ACTIVIDAD.tipo` para que no contradigan la subentidad existente.
- [ ] Definir cómo crear una actividad junto con su subentidad sin bloquear el estado intermedio entre ambas inserciones.
- [ ] Controlar las bajas y los cambios de subentidad para no dejar una actividad sin clasificación.
- [ ] Probar operaciones válidas e inválidas, incluyendo cambios que afecten varias filas.

Si se garantiza la coherencia del tipo en ambas subentidades, también se garantiza la exclusividad. La totalidad requiere un mecanismo adicional.

**Alternativas a evaluar:** triggers para la coherencia y procedimientos almacenados con transacciones y permisos controlados para las altas, bajas y modificaciones; o una modificación del diseño.

**Decisión del grupo:** pendiente.

## TODO 3: Definir dominio de `AREA.estado_mantenimiento`

**Estado:** pendiente. Hoy es `VARCHAR(30) NOT NULL` sin valores permitidos, porque el enunciado no los define.

- [ ] Acordar la lista de estados y reemplazar el tipo libre por un `CHECK` o una tabla de dominio.

## TODO 4: Validar supuestos de tipos de `PROFESIONAL` y `AREA`

**Estado:** supuestos aplicados en `01_creacion_tablas.sql`, sin confirmar con el equipo.

- [ ] `PROFESIONAL.dni` como `INT` con `CHECK (dni > 0)`.
- [ ] `AREA.capacidad` con `CHECK (capacidad >= 0)`.
- [ ] `AREA.cod_area` como `INT` manual, sin `IDENTITY`.

## TODO 5: Baja de inscripciones al cambiar de categoría (H12)

**Estado:** pendiente. No implementado en `03_logica_socios_cuotas.sql`.

H12 dice que al cambiar la categoría de un socio se dan de baja sus inscripciones a actividades no habilitadas para la nueva categoría. `INSCRIPCION` no tiene campo de estado ni fecha de baja.

- [ ] Decidir si la baja borra filas de `INSCRIPCION` o si se agrega estado / fecha de baja a la tabla (cambio de modelo).
- [ ] Implementar el trigger `AFTER UPDATE` sobre `SOCIO` según la decisión.

## TODO 6: Categorías y `nro_orden` de los datos frente a §4.2 y H1

**Estado:** pendiente. Los datos de `02` no se corrigieron.

- Los datos usan `Infantil/Juvenil/Adulto/Jubilado`; §4.2 usa `infantiles/mayores/vitalicios`.
- Los datos de `02` numeran `nro_orden` desde 1; H1 y §4.2 piden `0` para el titular.
- `TR_SOCIO_TITULAR_CATEGORIA` tiene `'Infantil'` escrito a mano. Si se cambian las categorías, hay que actualizar el trigger.
- La vista `VW_TITULARES_DEUDA_ANIO_ACTUAL` depende de `nro_orden = 0`: los grupos de `02` no aparecen en ella.

- [ ] Acordar la nomenclatura de categorías y corregirla en `CATEGORIA`, `02`, `03` y `04`.
- [ ] Corregir la numeración de los titulares de `02`.

## TODO 7: Fecha de vencimiento de la cuota social

**Estado:** supuesto aplicado. `SP_LIQUIDAR_CUOTA_SOCIAL` usa el último día del mes.

- [ ] Confirmar la fecha de vencimiento de la cuota social con el equipo (el enunciado no la define).

## TODO 8: Criterio de "todas las gratuitas" sin actividades gratuitas

**Estado:** supuesto aplicado. `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR` no cuenta a nadie si no hay actividades gratuitas.

- [ ] Confirmar el criterio con el equipo.
- [ ] Confirmar si "año pasado" refiere a `fecha_inscripcion` del año anterior.

## TODO 9: Implementación de las consultas 1 y 2 del enunciado (vista o stored procedure)

**Estado:** decidido por el usuario: stored procedures con parámetro `@anio`. Implementado en `03_logica_socios_cuotas.sql` como `SP_CONSULTA_TITULARES_DEUDA` y `SP_CONSULTA_SOCIOS_GRATUITAS`. Antes eran vistas con `GETDATE()`.

**Consulta 1: `VW_TITULARES_DEUDA_ANIO_ACTUAL`.** Toma `CUOTA_SOCIAL` del año `YEAR(GETDATE())` con deuda `monto_a_pagar - ISNULL(monto_abonado, 0) > 0`. Agrupa por `nro_socio_base` y devuelve el nombre del titular (`SOCIO` con `nro_orden = 0`), el importe total adeudado y la cantidad de integrantes (`COUNT` de `SOCIO` por grupo).

**Consulta 2: `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`.** Cuenta, por `nombre_categoria`, los socios con inscripciones de `fecha_inscripcion` en `YEAR(GETDATE()) - 1` que cubren todas las filas de `ACTIVIDAD_GRATUITA`. Usa `COUNT(DISTINCT cod_actividad)` contra `COUNT(*)` de `ACTIVIDAD_GRATUITA`, y exige que esa cantidad sea mayor que cero para evitar cumplir la condición en vacío (supuesto).

**Decisión:** pasar ambas consultas a stored procedure. Cada una recibe el año como parámetro, así se pueden probar años pasados.

- `SP_CONSULTA_TITULARES_DEUDA (@anio)`: año de las cuotas sociales a considerar.
- `SP_CONSULTA_SOCIOS_GRATUITAS (@anio)`: año de `fecha_inscripcion` a considerar. El llamador pasa el año anterior para cumplir el enunciado.

- [x] Decidir: stored procedure para cada consulta.
- [x] Definir el parámetro de año y actualizar `03_logica_socios_cuotas.sql` y `04_datos_logica_socios_cuotas.sql`.
- [ ] Confirmar con el equipo si el criterio de "año pasado" queda en el parámetro (ver TODO 8).