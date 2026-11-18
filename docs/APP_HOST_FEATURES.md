# App host: features para interactuar con la base

Aplicación web (Next.js) para operar la base `ClubDeportivo` y **activar a mano los triggers, constraints y stored procedures** del TP. No es una aplicación de negocio: es una consola amigable sobre el modelo.

## 1. Principio de diseño

**La app no valida.** Ningún formulario controla tipos, rangos, obligatoriedad ni reglas de negocio. Todo valor viaja a la base (el campo vacío viaja como `NULL`) y la base responde. Así se pueden probar los rechazos de `03` y `04` (errores 50001 a 50014, `CK_*` error 547, FK, PK duplicada, conversiones).

Consecuencias de diseño:

- Los errores de SQL Server se muestran **tal cual** (número y mensaje), sin traducirlos ni suavizarlos.
- Lo único que la app controla es la **seguridad básica**: los nombres de tabla y de SP se toman de una lista blanca (metadatos de la base o `lib/procedures.ts`) y los valores siempre van como parámetros, nunca concatenados.
- Un cambio de esquema (tabla o columna nueva) aparece solo en la app, porque los formularios se generan desde `sys.tables`/`sys.columns`.

## 2. Features del MVP (implementadas)

| # | Feature | Pantalla | Qué permite |
|---|---------|----------|-------------|
| F1 | Inicio | `/` | Las 19 tablas agrupadas por área, con cantidad de filas. Aviso si no hay conexión. |
| F2 | Listado de tabla | `/tablas/[tabla]` | Primeras 500 filas ordenadas por PK. Fechas y horas en texto ISO. |
| F3 | Alta directa (`INSERT`) | `/tablas/[tabla]` | Formulario generado desde los metadatos; omite columnas `IDENTITY`. Dispara triggers de tabla y constraints. |
| F4 | Edición (`UPDATE`) | `/tablas/[tabla]` | Carga la fila en el formulario; la clave original viaja aparte, por lo que se puede cambiar la PK. Dispara, por ejemplo, `TR_SOCIO_CAMBIO_CATEGORIA`. |
| F5 | Baja (`DELETE`) | `/tablas/[tabla]` | Con confirmación del navegador. Dispara `TR_SOCIO_BAJA_GRUPO` y las FK. |
| F6 | Consultas y vistas | `/consultas` | `VW_TITULARES_DEUDA_ANIO_ACTUAL`, `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR` y `VW_CONFLICTOS_DICTADO`. Muestra "sin filas" cuando la vista no devuelve nada (decisión TODO 8). |
| F7 | Stored procedures | `/procedimientos` | Un formulario por SP: `SP_ALTA_GRUPO_FAMILIAR`, `SP_ALTA_ACTIVIDAD_ARANCELADA`, `SP_ALTA_ACTIVIDAD_GRATUITA`, `SP_ALTA_DICTADO`, `SP_INSCRIBIR_ACTIVIDAD`, `SP_LIQUIDAR_CUOTA_SOCIAL`, `SP_LIQUIDAR_CUOTA_ARANCEL`. Muestra parámetros `OUTPUT` (`nro_socio_base`, `cod_dictado`), result sets y mensajes `PRINT`. |
| F9 | Consola SQL libre | `/sql` | Ejecuta T-SQL arbitrario, con lotes separados por `GO` (corta en el primer error y dice qué lote falló). Muestra result sets, mensajes `PRINT` y filas afectadas. Por defecto corre en una transacción que **siempre se deshace** (ROLLBACK), para probar triggers y constraints sin ensuciar los datos; desmarcando la opción los cambios persisten (con confirmación). Ctrl+Enter ejecuta. |
| F10 | Sugerencias (`datalist`) | tablas y `/procedimientos` | Los campos de dominio cerrado (CHECK) y de clave foránea ofrecen los valores válidos, con etiqueta descriptiva (ej.: `nro_socio_base` → `1 = Juan Perez`), pero aceptan cualquier valor. Ver §5. |
| F8 | Resultado de cada operación | todas | Banner verde (éxito) o rojo (rechazo con número de error y mensaje del motor). |

## 3. Backlog (no implementado)

Ordenado por utilidad para el TP. Ninguno cambia el principio de la sección 1.

1. **Historial y scripts guardados** en la consola SQL (hoy el script se pierde al recargar).
2. **Filtro y búsqueda por columna** en el listado de tablas (hoy sólo las primeras 500 filas).
3. **Navegación por claves foráneas**: desde un `nro_socio_base` saltar a su grupo, sus cuotas e inscripciones (vista de detalle de un grupo familiar).
4. **Vista de deuda por grupo**: cuotas sociales y de arancel de un grupo, con pagos (`monto_abonado`, `fecha_pago`).
5. **Registrar pago** de cuota (`UPDATE` guiado de `monto_abonado` y `fecha_pago`), hoy se hace por edición de la fila.
6. **Baja de inscripción** guiada (hoy por edición de `estado` y `fecha_baja`).
7. **Reinicio de datos**: botón que re-ejecuta `00` a `05` (destructivo: pedir confirmación). Hoy se hace con `sqlcmd`.
8. ~~Selectores / sugerencias~~: implementado como F10 con `datalist` (ver §5).
9. **Pruebas automatizadas** de la app (Playwright) sobre una base de prueba.

## 4. Limitaciones conocidas

- Sólo corre en Windows con LocalDB y el driver ODBC de SQL Server (usa `msnodesqlv8` por la autenticación de Windows).
- Las operaciones de F3 a F5 y F7 persisten de inmediato. Para probar sin persistir, usar la consola SQL (F9) en modo rollback. Para volver al estado inicial hay que reconstruir la base con los scripts.
- La consola SQL ejecuta cualquier cosa (incluido DDL y `DROP`) sin controles: pensada sólo para uso local. En modo rollback, un script que haga su propio `COMMIT` persiste igual.
- Los lotes de la consola se ejecutan con el motor de SQL Server, no con SSMS: no hay comandos de `sqlcmd`/SSMS aparte de `GO`.
- Las tablas sin PK no se pueden editar ni eliminar (no es el caso del modelo actual).
- Los `SP_ALTA_*` siguen siendo la única vía que garantiza la participación total; el alta directa (F3) la saltea, como ya está documentado en `CLAUDE.md` §3.

## 5. Inputs candidatos a select

**Estado: implementado con `datalist` (F10).** Lo que sigue es el relevamiento que lo originó; las §5.1 a §5.3 describen lo que hoy ofrece sugerencias.

Relevamiento hecho sobre `scripts/01_creacion_tablas.sql` (FK y CHECK) y las firmas de `lib/procedures.ts`. Hoy todos los campos son texto libre.

**Cuidado con el principio de la sección 1:** un `<select>` estricto impide cargar el valor inválido que justamente se quiere para probar el rechazo (`CK_*`, FK). Por eso se propone una de estas dos formas, a decidir con el grupo:

- **Sugerencia (recomendada):** `<input list>` con `<datalist>`; ofrece los valores válidos pero deja escribir cualquier otro.
- **Select con interruptor:** `<select>` normal más un modo "valor libre" global (o una opción "otro…") para volver al texto libre.

### 5.1 Dominios cerrados (salen de un CHECK)

| Campo | Valores | Dónde aparece |
|---|---|---|
| `nombre_categoria` | `infantiles`, `mayores`, `vitalicios` (`CK_CATEGORIA_NOMBRE`) | `CATEGORIA`; `SOCIO` y `HABILITADA_PARA` (FK); `SP_ALTA_GRUPO_FAMILIAR` |
| `ACTIVIDAD.tipo` | `A`, `G` | `ACTIVIDAD` (ojo: lo fijan los triggers 50011 a 50013 y el SP de alta) |
| `meses_por_cuota` | 1, 2, 3, 6, 12 | `ACTIVIDAD_ARANCELADA`; `SP_ALTA_ACTIVIDAD_ARANCELADA` |
| `INSCRIPCION.estado` | `Activa`, `Baja` | `INSCRIPCION` |
| `dia_semana` | 1 a 7 | `DICTADO_DIA`; `SP_ALTA_DICTADO` |
| `mes` | 1 a 12 | `CUOTA_SOCIAL`; `SP_LIQUIDAR_CUOTA_SOCIAL`; `SP_LIQUIDAR_CUOTA_ARANCEL` |

### 5.2 Claves foráneas simples (opciones = filas de la tabla padre)

| Campo | Tabla padre (texto de la opción) | Dónde aparece |
|---|---|---|
| `cod_actividad` | `ACTIVIDAD` (código + nombre + tipo) | `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`, `DICTADO`; `SP_ALTA_DICTADO`, `SP_INSCRIBIR_ACTIVIDAD` |
| `nro_socio_base` | `GRUPO_FAMILIAR` (número + titular) | `SOCIO`, `CUOTA_SOCIAL` |
| `dni` | `PROFESIONAL` (dni + nombre) | `PUEDE_DESEMPENIARSE_EN`, `A_CARGO_DE`; `SP_ALTA_DICTADO` |
| `cod_area` | `AREA` (código + ubicación) | `APTA_PARA`, `SE_DESARROLLA_EN`; `SP_ALTA_DICTADO` |
| `cod_dictado` | `DICTADO` (código + actividad + período) | `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN` |

### 5.3 Claves foráneas compuestas (un solo select que completa varios campos)

| Campos | Padre | Dónde aparece |
|---|---|---|
| `nro_socio_base` + `nro_orden` | `SOCIO` (ej.: "1-0 Juan Perez") | `INSCRIPCION`; `SP_INSCRIBIR_ACTIVIDAD` |
| `nro_socio_base` + `nro_orden` + `cod_actividad` + `fecha_inscripcion` | `INSCRIPCION` | `CUOTA_ARANCEL` |

### 5.4 Descartados o a esperar

- `AREA.estado_mantenimiento`: parece un dominio cerrado pero está abierto (TODO 3); no definir opciones hasta que el grupo lo cierre.
- `SOCIO.nro_orden`: no es FK; es correlativo dentro del grupo (0 = titular). Se podría sugerir el próximo libre, pero es lógica de negocio.
- `cod_actividad` y `cod_area` en los altas de `ACTIVIDAD` y `AREA`, y `dni` de `PROFESIONAL`: son claves nuevas, no existen en ningún padre.
- Fechas y horas: ya implementado con `<input type="date">` / `type="time"` (calendario y selector de hora nativos) en los formularios de tablas y de SP. Limitación: el navegador no deja enviar una fecha inválida (ej.: 31/02) ni texto libre en esos campos; para probar fechas mal formadas usar la consola SQL.
- `anio` de las liquidaciones: sin dominio definido en el modelo.

### 5.5 Cómo está implementado

- FK: leer `sys.foreign_keys` en `lib/schema.ts` (columnas hijas y padre) y cargar las opciones desde la tabla padre al renderizar la página. Las tablas chicas (`CATEGORIA`, `ACTIVIDAD`, `PROFESIONAL`, `AREA`) se cargan completas; `GRUPO_FAMILIAR`, `SOCIO` e `INSCRIPCION` pueden crecer, por lo que conviene limitar a las primeras N filas o buscar por texto.
- Dominios cerrados: parsear `sys.check_constraints` (`IN (...)` y `BETWEEN a AND b`) en vez de escribir las listas a mano.
- SP: agregar a cada parámetro de `lib/procedures.ts` un campo `source` (`"CATEGORIA"`, `"ACTIVIDAD"`, `"SOCIO"`, `{ enum: [...] }`) con el origen de sus opciones.

Detalle de la implementación:

- `lib/schema.ts` lee `sys.foreign_keys` y `sys.check_constraints` y deja en cada columna `fk` (tabla y columna padre; gana la FK simple sobre la compuesta) y `domain` (valores del CHECK). `lib/domains.ts` interpreta los CHECK de una sola columna (`IN` y `BETWEEN`, hasta 31 valores).
- `optionsForColumn` devuelve el dominio o los valores distintos de la columna padre (hasta 200). La etiqueta sale del nombre de la columna: `nro_socio_base` → titular, `cod_actividad` → nombre, `dni` → profesional, `cod_area` → ubicación, `cod_dictado` → actividad.
- En los SP, cada parámetro declara `source: { table, column }` en `lib/procedures.ts`: tiene las mismas sugerencias que esa columna. Si cambia un SP, actualizar también su `source`.
- `components/SuggestInput.tsx` renderiza el `<input list>` y su `<datalist>`. Los campos `date` y `time` conservan el calendario y no llevan lista.
- Con la base caída, las páginas de procedimientos muestran los formularios sin sugerencias.
- Límite: el navegador filtra las sugerencias por lo que ya está escrito en el campo; al editar una fila hay que borrar el valor para ver las demás.
