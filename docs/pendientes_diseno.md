# Pendientes de revisión del diseño

## TODO 1: Definir los valores permitidos de `meses_por_cuota`

**Estado:** CERRADO. Lista cerrada `IN (1, 2, 3, 6, 12)` aplicada en `01_creacion_tablas.sql` y confirmada por el usuario.

**Tabla:** `ACTIVIDAD_ARANCELADA`.

Definir qué periodicidades de cobro se permiten. Por ejemplo: mensual (`1`), bimestral (`2`), trimestral (`3`), semestral (`6`) o anual (`12`). Estos valores son ejemplos; todavía no constituyen una lista acordada.

Hasta definir la regla, se propone usar `CHECK (meses_por_cuota > 0)`, que permite cualquier entero positivo. El control `>= 0` también permitiría cero meses.

- [ ] Acordar si se admite cualquier cantidad positiva de meses o una lista cerrada de valores.
- [ ] Registrar los valores acordados y actualizar el `CHECK` si corresponde.
- [ ] Probar valores válidos e inválidos.

**Decisión del grupo:** pendiente.

## TODO 2: Garantizar la jerarquía de actividades

**Estado:** APLICADO en `03_logica_socios_cuotas.sql` (`TR_ACTIVIDAD_ARANCELADA_TIPO` 50011, `TR_ACTIVIDAD_GRATUITA_TIPO` 50012, `TR_ACTIVIDAD_TIPO_INMUTABLE` 50013, `SP_ALTA_ACTIVIDAD_ARANCELADA`, `SP_ALTA_ACTIVIDAD_GRATUITA`), con pruebas H–K en `04`. Mecanismo decidido: triggers de coherencia en `ACTIVIDAD_ARANCELADA` (`tipo = 'A'`) y `ACTIVIDAD_GRATUITA` (`tipo = 'G'`); trigger en `ACTIVIDAD` que impide cambiar `tipo` si ya tiene subentidad (una actividad nunca cambia de gratuita a arancelada); `SP_ALTA_ACTIVIDAD_ARANCELADA` y `SP_ALTA_ACTIVIDAD_GRATUITA` que crean actividad y subentidad en una transacción (totalidad). Limitación: un `INSERT` directo puede saltear los SP.

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

**Decisión del grupo:** mecanismo aprobado por el usuario (ver Estado). Limitación vigente: borrar una subentidad, o un `INSERT` directo en `ACTIVIDAD`, puede dejar una actividad sin clasificar; no se agregó trigger de `DELETE` porque rompería la recarga de `02`.

## TODO 3: Definir dominio de `AREA.estado_mantenimiento`

**Estado:** ABIERTO. El usuario lo va a consultar. Hoy es `VARCHAR(30) NOT NULL` sin valores permitidos, porque el enunciado no los define. Propuesta sin confirmar: `CHECK` con `'Operativa'`, `'En mantenimiento'`, `'Fuera de servicio'`.

- [ ] Acordar la lista de estados y reemplazar el tipo libre por un `CHECK` o una tabla de dominio.

## TODO 4: Validar supuestos de tipos de `PROFESIONAL` y `AREA`

**Estado:** APLICADO en `01`, `03` y `05`. Como `dni` y `cod_area` son PK (únicos), no se agregó `UNIQUE` redundante. Se probó `dni` como `VARCHAR(12)` y el usuario decidió volver a `INT`.

- [x] `PROFESIONAL.dni` queda `INT` con `CK_PROFESIONAL_DNI CHECK (dni > 0)` (como en el supuesto original).
- [x] `AREA.capacidad` con `CHECK (capacidad >= 0)` (confirmado).
- [x] `AREA.cod_area` como `VARCHAR(20)`; `CK_AREA_COD_AREA` exige no vacío y sin espacios al inicio ni al final.
- [x] FK de `cod_area` (`APTA_PARA`, `SE_DESARROLLA_EN`) y datos de prueba ajustados a texto.

## TODO 5: Baja de inscripciones al cambiar de categoría (H12)

**Estado:** ABIERTO. El usuario lo va a consultar; se inclina por agregar estado a `INSCRIPCION`. No implementado en `03_logica_socios_cuotas.sql`. Propuesta sin confirmar: columnas `estado` (`'Activa'`/`'Baja'`) y `fecha_baja`; `SP_LIQUIDAR_CUOTA_ARANCEL` deja de generar cuotas para las dadas de baja (las ya generadas se mantienen); las dadas de baja siguen contando en la consulta 2; reflejar el cambio en TP_BBDD_Grupo_4.md §4.1.

H12 dice que al cambiar la categoría de un socio se dan de baja sus inscripciones a actividades no habilitadas para la nueva categoría. `INSCRIPCION` no tiene campo de estado ni fecha de baja.

- [ ] Decidir si la baja borra filas de `INSCRIPCION` o si se agrega estado / fecha de baja a la tabla (cambio de modelo).
- [ ] Implementar el trigger `AFTER UPDATE` sobre `SOCIO` según la decisión.

## TODO 6: Categorías y `nro_orden` de los datos frente a §4.2 y H1

**Estado:** APLICADO en `02`, `03` y `05`. Categorías `infantiles` (-30.00) / `mayores` (0.00) / `vitalicios` (-15.00); mapeo: Infantil → infantiles, Juvenil y Adulto → mayores, Jubilado → vitalicios. Titulares con `nro_orden = 0` en `02`. `TR_SOCIO_TITULAR_CATEGORIA` usa `'infantiles'`. Porcentajes y mapeo son decisión del usuario, no figuran en el enunciado.

Situación previa (resuelta): los datos usaban `Infantil/Juvenil/Adulto/Jubilado` y numeraban `nro_orden` desde 1, y `SP_CONSULTA_TITULARES_DEUDA` dejaba afuera los grupos de `02`.

- [x] Acordar la nomenclatura de categorías y corregirla en `CATEGORIA`, `02`, `03` y `05`.
- [x] Corregir la numeración de los titulares de `02`.
- [x] `CK_CATEGORIA_NOMBRE` en `CATEGORIA`: sólo `infantiles`, `mayores`, `vitalicios` (§4.2). Si el grupo cambia los nombres, hay que actualizar este CHECK y `TR_SOCIO_TITULAR_CATEGORIA`.
- [x] `CK_SOCIO_NRO_ORDEN` en `SOCIO`: `nro_orden >= 0`. Sigue sin garantizarse en `SOCIO` que cada grupo tenga exactamente un titular: lo cubren `SP_ALTA_GRUPO_FAMILIAR` y `TR_SOCIO_BAJA_GRUPO`, y un `INSERT` directo puede saltearlos.

## TODO 7: Fecha de vencimiento de la cuota social

**Estado:** CERRADO. `SP_LIQUIDAR_CUOTA_SOCIAL` usa el último día del mes, confirmado por el usuario.

- [ ] Confirmar la fecha de vencimiento de la cuota social con el equipo (el enunciado no la define).

## TODO 8: Criterio de "todas las gratuitas" sin actividades gratuitas

**Estado:** ABIERTO. El usuario lo va a consultar. Supuesto aplicado: `SP_CONSULTA_SOCIOS_GRATUITAS` no cuenta a nadie si no hay actividades gratuitas ("todas" no se cumple en vacío).

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
- [x] Definir el parámetro de año y actualizar `03_logica_socios_cuotas.sql` y `05_datos_logica_socios_cuotas.sql`.
- [ ] Confirmar con el equipo si el criterio de "año pasado" queda en el parámetro (ver TODO 8). ABIERTO: el usuario lo va a consultar junto con el TODO 8.