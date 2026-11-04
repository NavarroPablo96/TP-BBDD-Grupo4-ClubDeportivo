# Spec de estado: Club Deportivo (Grupo 4)

Documento para cualquier integrante del grupo que quiera empezar a trabajar. Resume qué está hecho, cómo correrlo, qué falta y qué está pendiente de decisión. La fuente de verdad del diseño sigue siendo [TP_BBDD_Grupo_4.md](TP_BBDD_Grupo_4.md) (§4.1 y §4.2); las decisiones abiertas están en [pendientes_diseno.md](pendientes_diseno.md).

## 1. Objetivo

Diseño e implementación en **SQL Server (T-SQL)** de la base de datos de un club deportivo: socios, grupos familiares, categorías, actividades, cronograma de dictados, cuotas sociales y aranceles. Entrega para la cátedra de Bases de Datos (UNMdP, Facultad de Ingeniería).

## 2. Cómo correr los scripts

Orden obligatorio (cada uno depende del anterior). Los scripts están en `scripts/`:

| Script | Qué hace |
|---|---|
| `00_creacion_bd.sql` | Elimina y recrea la base `ClubDeportivo`. |
| `01_creacion_tablas.sql` | Crea las tablas, con sus constraints. |
| `02_insercion_datos.sql` | Carga datos base: categorías, grupos, socios y valores de cuota social. |
| `03_logica_socios_cuotas.sql` | Triggers, stored procedures y consultas de socios y cuotas. Se puede volver a correr (`CREATE OR ALTER`). |
| `04_logica_areas_profesionales.sql` | Triggers de profesional habilitado y área apta de los dictados. Se puede volver a correr (`CREATE OR ALTER`). Va antes de `05`. |
| `05_datos_logica_socios_cuotas.sql` | Datos de prueba para `03` y `04`: actividades, habilitaciones, grupos, cuotas e inscripciones. Asume que se corre justo después de `02` sobre una base recién creada. |

Comando (LocalDB, autenticación de Windows):

Desde la raíz del repo:

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

Implementadas (todas las de §4.1 de TP_BBDD_Grupo_4.md, con su `DROP` en el bloque inicial):

- Socios: `CATEGORIA`, `GRUPO_FAMILIAR`, `SOCIO`.
- Cuotas sociales: `VALOR_CUOTA_SOCIAL`, `CUOTA_SOCIAL`.
- Actividades: `ACTIVIDAD`, `ACTIVIDAD_ARANCELADA`, `ACTIVIDAD_GRATUITA`, `HABILITADA_PARA`, `INSCRIPCION`.
- Profesionales y áreas: `PROFESIONAL`, `AREA`, `PUEDE_DESEMPENIARSE_EN`, `APTA_PARA`.
- Dictados: `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`.
- Arancel: `CUOTA_ARANCEL`.

Las tablas nuevas de cronograma y arancel tienen DDL pero todavía no tienen lógica (triggers, SP) ni datos de prueba. Ver §4.

Constraints de §4.2 ya resueltos con DDL:
- `CK_CUOTA_SOCIAL_ABONADO`: `monto_abonado <= monto_a_pagar` (`NULL` = sin pagos).
- `CK_VALOR_CUOTA_SOCIAL_FECHAS`: `fecha_hasta >= fecha_desde`.
- `CK_DICTADO_FECHAS` y `CK_DICTADO_HORARIO`: `fecha_desde <= fecha_fin` y `hora_inicio < hora_fin`.
- `CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA`: `meses_por_cuota IN (1, 2, 3, 6, 12)`. Lista decidida por el usuario, no por el grupo (TODO 1).

### 3.2 Lógica (`03_logica_socios_cuotas.sql`)

Triggers:

- `TR_INSCRIPCION_CATEGORIA_HABILITADA` (sobre `INSCRIPCION`): un socio sólo se inscribe en actividades habilitadas para su categoría (§4.2).
- `TR_VALOR_CUOTA_SOCIAL_VIGENCIA` (sobre `VALOR_CUOTA_SOCIAL`): los períodos no se superponen ni dejan huecos (§4.2).
- `TR_SOCIO_TITULAR_CATEGORIA` (sobre `SOCIO`): el titular (`nro_orden = 0`) no puede ser `infantiles` (§4.2). Usa `'infantiles'` literal.
- `TR_ACTIVIDAD_ARANCELADA_TIPO` (50011), `TR_ACTIVIDAD_GRATUITA_TIPO` (50012) y `TR_ACTIVIDAD_TIPO_INMUTABLE` (50013): coherencia y exclusividad de la jerarquía de `ACTIVIDAD` (TODO 2).
- En `04_logica_areas_profesionales.sql` (aporte de un compañero, adaptado a los códigos y al estilo de `03`):
  - `TR_A_CARGO_DE_PROF_HABILITADO` (sobre `A_CARGO_DE`): el profesional debe estar en `PUEDE_DESEMPENIARSE_EN` para la actividad del dictado (§4.2). Error 50005.
  - `TR_SE_DESARROLLA_EN_AREA_APTA` (sobre `SE_DESARROLLA_EN`): el área debe estar en `APTA_PARA` para la actividad del dictado (§4.2). Error 50006.
- `TR_DICTADO_SOLAPAMIENTO_*` (sobre `DICTADO`, `DICTADO_DIA`, `A_CARGO_DE`, `SE_DESARROLLA_EN`): no hay dos dictados que coincidan en día, horario y período con un área o profesional en común. Consultan la vista `VW_CONFLICTOS_DICTADO`. Error 50007.
- `TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA` (sobre `CUOTA_ARANCEL`): sólo las actividades aranceladas generan cuotas de arancel (§4.2, H9). Error 50008.
- `TR_SOCIO_BAJA_GRUPO` (sobre `SOCIO`, al borrar): el titular no se da de baja mientras el grupo tenga integrantes (50009), y un grupo no queda sin integrantes (50010). No aplica al borrar el grupo completo por cascada.

Stored procedures:

- `SP_ALTA_GRUPO_FAMILIAR`: crea grupo y titular en una transacción. Garantiza que todo grupo tenga titular (H1).
- Constraints de dominio agregados en `01`: `CK_CATEGORIA_NOMBRE` (las tres categorías de §4.2), `CK_SOCIO_NRO_ORDEN` (`nro_orden >= 0`) y `CK_AREA_COD_AREA`.
- `SP_ALTA_ACTIVIDAD_ARANCELADA` y `SP_ALTA_ACTIVIDAD_GRATUITA`: crean la actividad y su subentidad en una transacción (totalidad de la jerarquía, TODO 2). Un `INSERT` directo en `ACTIVIDAD` puede saltearlos (limitación).
- `SP_ALTA_DICTADO`: crea dictado, un día y un profesional a cargo en una transacción (H13). Un dictado sin profesional no se puede crear.
- `SP_INSCRIBIR_ACTIVIDAD (@nro_socio_base, @nro_orden, @cod_actividad, @fecha_inscripcion)`: inscribe. Si la actividad es arancelada, genera la cuota 1 por adelantado (H9). Transacción.
- `SP_LIQUIDAR_CUOTA_ARANCEL (@anio, @mes)`: genera, para el mes, la cuota de arancel que vence en cada inscripción arancelada. La cuota k vence k × `meses_por_cuota` meses después de la inscripción. No duplica (H8, H9).
- `SP_LIQUIDAR_CUOTA_SOCIAL (@anio, @mes)`: genera la cuota social de un mes para cada grupo que no la tenga (H8, H10). Monto = suma de `monto_base` vigente × `(1 + porcentaje_mod_cuota / 100)` por integrante. Se fija al generar. Vencimiento: último día del mes (supuesto, TODO 7).
- `SP_CONSULTA_TITULARES_DEUDA (@anio)`: consulta 1 del enunciado. Titulares con deuda del año, importe total e integrantes.
- `SP_CONSULTA_SOCIOS_GRATUITAS (@anio)`: consulta 2 del enunciado. Socios por categoría inscriptos en todas las gratuitas del año indicado. Se llama con el año anterior.

Las consultas también son SP, con año como parámetro, por decisión del usuario (TODO 9). El criterio de partida era usar vistas para consultas, pero se cambió.

### 3.3 Datos de prueba

- `02_insercion_datos.sql`: 3 categorías (`infantiles` -30, `mayores` 0, `vitalicios` -15), 5 grupos (8 socios, titulares con `nro_orden = 0`), 4 valores de cuota social (2025 y 2026). Sin `CUOTA_SOCIAL`, sin actividades, sin inscripciones.
- `05_datos_logica_socios_cuotas.sql`: 3 grupos nuevos (Marta Ruiz, Pablo Diaz, Elena Sosa), 2 actividades gratuitas (201, 202), 1 arancelada (301), habilitaciones, cuotas de enero a marzo 2026 con pagos completos, parciales y sin pagar, e inscripciones de 2025 y 2026.

Resultados esperados con estos datos:

- `SP_CONSULTA_TITULARES_DEUDA 2026`: Juan Perez 121500.00 (3), Carlos Gomez 90000.00 (2), Sofia Rodriguez 45000.00 (1), Roberto Fernandez 38250.00 (1), Laura Martinez 45000.00 (1), Pablo Diaz 30000.00 (1), Elena Sosa 78250.00 (2).
- `SP_CONSULTA_SOCIOS_GRATUITAS 2025`: mayores 2, el resto 0.

### 3.4 Verificación hecha

- `00` a `05` corren con exit 0, y `01`, `03` y `04` se pueden volver a correr sobre la base creada.
- Rechazos comprobados: inscripción no habilitada, vigencia superpuesta, hueco en vigencia, titular infantil y abonado mayor a pagar. El alta de titular infantil no deja filas en `GRUPO_FAMILIAR` (rollback del SP).
- Liquidar dos veces el mismo mes no duplica cuotas. Los montos calculados coinciden con los esperados.
- Reconstrucción limpia con `00` a `05` (exit 0). `03` y `04` se pueden volver a correr (exit 0).
- Pruebas de rechazo y control dentro de `04` (bloques A–G, cada uno en transacción con `ROLLBACK`): 50005, 50006, 50007 (y el control D que pasa), 50008, 50009 y 50010. Imprimen el resultado.
- Pruebas H–N en `04`: 50011, 50012 y 50013 rechazan, el alta por SP de actividades pasa (K), y los CHECK rechazan con error 547: `CK_PROFESIONAL_DNI` (dni 0), `CK_AREA_COD_AREA` (blanco y espacio inicial), `CK_CATEGORIA_NOMBRE` (categoría no permitida) y `CK_SOCIO_NRO_ORDEN` (nro_orden negativo). Los casos L–N corren en transacción con `ROLLBACK`.
- Reconstrucción `00` a `05` con exit 0 y `03` y `04` re-ejecutables, tras aplicar TODO 2, 4 y 6 e integrar el PR de triggers de áreas y profesionales.
- Arancel de control: la deuda de arancel de Marta (actividad 301) es 8000.00.
- Re-correr `02` sobre una base cargada falla por diseño (`FK_SOCIO_GRUPO_FAMILIAR`): la `IDENTITY` de `GRUPO_FAMILIAR` no se reinicia. Los `DELETE` sí corren hasta ese punto. Re-correr `04` sobre datos cargados falla por claves duplicadas.

### 3.5 Cambios recientes que conviene conocer

- `02_insercion_datos.sql` ya no tiene `DBCC CHECKIDENT ... RESEED 0`. Con ese comando, los `nro_socio_base` quedaban en 0..4 y rompían la FK de `SOCIO`. Hoy la numeración arranca en 1, por lo que los datos asumen una base recién creada por `00`.
- `porcentaje_mod_couta` pasó a `porcentaje_mod_cuota` en `01` y `02`.

## 4. Qué falta

### 4.1 Tablas

Ya no faltan tablas. Las cuatro de cronograma y arancel están en `01` con PK, FK y CHECK:

- `DICTADO_DIA`: `dia_semana` entre 1 y 7 (`CK_DICTADO_DIA_SEMANA`).
- `A_CARGO_DE`: PK compuesta, FK a `DICTADO` y `PROFESIONAL`.
- `SE_DESARROLLA_EN`: PK compuesta, FK a `DICTADO` y `AREA`.
- `CUOTA_ARANCEL`: PK compuesta, FK a `INSCRIPCION`, `CK_CUOTA_ARANCEL_NRO_CUOTA`, `CK_CUOTA_ARANCEL_IMPORTES` y `CK_CUOTA_ARANCEL_ABONADO`.

### 4.2 Triggers y procedimientos de cronograma (implementados)

- Profesional a cargo debe poder desempeñarse en la actividad: `TR_A_CARGO_DE_PROF_HABILITADO` (en `04`).
- Área del dictado debe ser apta para la actividad: `TR_SE_DESARROLLA_EN_AREA_APTA`.
- Sin solapamiento de día, horario y período con área o profesional en común: `TR_DICTADO_SOLAPAMIENTO_*`.
- Todo dictado con al menos un profesional a cargo (H13): `SP_ALTA_DICTADO`. Un `INSERT` directo puede saltear el SP (limitación).

### 4.3 Triggers y procedimientos de arancel (implementados)

- Sólo actividades aranceladas generan cuotas: `TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA` (50008).
- Inscripción con cuota 1 por adelantado y cuotas siguientes por periodicidad (H9): `SP_INSCRIBIR_ACTIVIDAD` y `SP_LIQUIDAR_CUOTA_ARANCEL`.
- `monto_abonado` entre 0 y `monto_a_pagar`: `CK_CUOTA_ARANCEL_ABONADO`.
- Las cuotas de arancel se fijan al generar (H8).
- Supuesto: `SP_LIQUIDAR_CUOTA_ARANCEL` se corre cada mes. Si no se corre en un mes, la cuota de ese mes no se genera.

### 4.4 Restricciones pendientes de implementación

- Participación total de `GRUPO_FAMILIAR` ↔ `SOCIO`: `TR_SOCIO_BAJA_GRUPO` cubre la baja. Un `INSERT` directo puede saltear `SP_ALTA_GRUPO_FAMILIAR` (limitación).
- Jerarquía `ACTIVIDAD` (TODO 2): coherencia y exclusividad con triggers, totalidad con `SP_ALTA_ACTIVIDAD_*`. Limitación: un `INSERT` directo en `ACTIVIDAD`, o borrar una subentidad, deja una actividad sin clasificar.
- Baja de inscripciones al cambiar de categoría (H12, TODO 5). Requiere decisión sobre borrar filas o agregar estado.

### 4.5 Aplicación host

Enunciado (funcionalidad e): aplicación sencilla en un lenguaje host que acceda a la base y haga una operación con transacciones. **Fuera de alcance por ahora** (decisión del equipo de trabajo). Se retoma más adelante.

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
| 1 | Periodicidades de `meses_por_cuota` | Cerrado: `IN (1, 2, 3, 6, 12)`. |
| 2 | Jerarquía de `ACTIVIDAD` (coherencia, exclusividad, totalidad) | Aplicado (triggers y SP de alta). |
| 3 | Dominio de `AREA.estado_mantenimiento` | Abierto; el usuario lo consulta. |
| 4 | Tipos de `PROFESIONAL.dni` y `AREA.cod_area` | Aplicado: `dni` `INT` con `dni > 0`; `cod_area` `VARCHAR(20)` con CHECK de formato. |
| 5 | Baja de inscripciones al cambiar categoría (H12) | Abierto; el usuario lo consulta (se inclina por agregar estado a `INSCRIPCION`). |
| 6 | Nomenclatura de categorías y `nro_orden` de `02` vs. §4.2 | Aplicado: `infantiles/mayores/vitalicios` y titular en 0. |
| 7 | Fecha de vencimiento de la cuota social | Cerrado: último día del mes. |
| 8 | "Todas las gratuitas" sin actividades y criterio de "año pasado" | Abierto; el usuario lo consulta. Supuesto aplicado. |
| 9 | Consultas 1 y 2 como SP | SP con parámetro de año. Falta confirmar criterio de año pasado (ver TODO 8). |

## 6. Problemas conocidos

- `02_insercion_datos.sql`: sólo corre sobre base recién creada por `00`. Los `DELETE` ya van en orden inverso de dependencias, pero la re-carga falla igual por la `IDENTITY` de `GRUPO_FAMILIAR`.
- `03_logica_socios_cuotas.sql`: `TR_SOCIO_TITULAR_CATEGORIA` tiene `'infantiles'` literal. Si cambian las categorías, hay que actualizar el trigger.
- `05_datos_logica_socios_cuotas.sql`: no borra nada. Si se corre sobre una base con datos, falla por claves duplicadas. Correr siempre después de `00`.
- Un `INSERT` directo en `ACTIVIDAD` o borrar una subentidad puede dejar una actividad sin clasificar (la totalidad la cubren los `SP_ALTA_ACTIVIDAD_*`).

## 7. Próximos pasos sugeridos

Hecho en el plan de faltantes: triggers de cronograma, arancel, participación total, `DELETE` de `02`, datos y pruebas en `04`.

Pendiente:

1. Completar los entregables a–e (§4.6).
2. Resolver con el equipo los TODO abiertos de §5: 3, 5 (H12), 8 y 9.

La aplicación host queda fuera de este plan.
