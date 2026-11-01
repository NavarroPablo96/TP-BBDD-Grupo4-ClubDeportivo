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