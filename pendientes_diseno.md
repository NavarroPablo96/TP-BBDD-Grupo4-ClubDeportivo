# Pendientes de revisión del diseño

## TODO 1: Definir los valores permitidos de `meses_por_cuota`

**Estado:** pendiente de revisión con el grupo.

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