# Decisiones abiertas del TP (para cerrar entre todos)

Tenemos 2 puntos sin confirmar que el enunciado no resuelve. Para cada uno van las opciones y lo que proponemos, así alcanza con responder "ok" o "no, mejor X". El detalle técnico de cada uno está en [pendientes_diseno.md](pendientes_diseno.md).

Restricción a tener en cuenta en todas las opciones: **no se admiten atributos multivaluados** en el modelo lógico ni en las tablas. Si un dato puede tomar varios valores a la vez, va en una tabla aparte (como `DICTADO_DIA`).

## 1. Consulta 2: "socios inscriptos en todas las actividades gratuitas el año pasado"

* Decidido: si no hay filas para mostrar, no se muestra nada. La consulta sólo lista las categorías con al menos un socio que cumple; si no existe ninguna actividad gratuita ("todas" se cumpliría en vacío) o nadie cumple, no devuelve filas.
* "Año pasado" lo interpretamos como el año de `fecha_inscripcion`: `YEAR(GETDATE()) - 1`.
* Pregunta: ¿les parece bien lo de "año pasado", o lo consultamos con la cátedra?

## 2. Consultas 1 y 2 como vistas

Quedaron como vistas (`VW_TITULARES_DEUDA_ANIO_ACTUAL` y `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`) que usan `YEAR(GETDATE())` y `YEAR(GETDATE()) - 1`, siguiendo el enunciado al pie de la letra ("año en curso" y "año pasado"). Sólo confirmamos que el grupo está de acuerdo.

## 3. Para informar (no hace falta decidir)

* **Estados de mantenimiento de un área, resuelto (definitivo).** Como no se admiten atributos multivaluados, el estado ya no es una columna de `AREA`: quedó como historial en dos tablas nuevas (cambia el modelo relacional de §4.1, que pasa a 21 tablas).
   * `ESTADO_AREA (nombre_estado)`: catálogo de estados posibles: `Operativa`, `En mantenimiento` y `Fuera de servicio`.
   * `HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)`: desde qué fecha un área está en un estado. Un área puede volver a un estado anterior y tiene un único estado por fecha. El estado vigente es el de mayor fecha que no sea futura.
* **Dictados en áreas no operativas, resuelto (definitivo).** El enunciado dice que cada área tiene un "estado de mantenimiento", pero no dice si eso afecta a los dictados; es una hipótesis nuestra.
   * Un dictado no puede desarrollarse en un área que esté `En mantenimiento` o `Fuera de servicio` en algún momento de su período (de `fecha_desde` a `fecha_fin`). Se controla al asignar el área al dictado, al cambiar las fechas del dictado y al cambiar el historial de estados del área.
   * Un área puede crearse con cualquier estado. Si nace en mantenimiento, no recibe dictados hasta pasar a `Operativa`. Un área sin ningún estado cargado no se restringe.
* **Baja de inscripciones al cambiar de categoría (H12), resuelto.** El enunciado sólo pide verificar la categoría al inscribirse; que al cambiar de categoría se den de baja las inscripciones incompatibles es una hipótesis nuestra (H12). Quedó implementado: `INSCRIPCION` tiene `estado` (`Activa` o `Baja`) y `fecha_baja`, y un trigger sobre `SOCIO` da la baja y conserva el historial. Para poder reinscribirse tras una baja (H6 habla de una inscripción *vigente* por actividad), la PK de `INSCRIPCION` ahora incluye `fecha_inscripcion`, y la FK de `CUOTA_ARANCEL` también (cambia §4.1). Una baja corta las cuotas de arancel (las ya generadas se mantienen) y sigue contando en la consulta 2. No se puede reinscribir el mismo día de la inscripción anterior.
* Las cuotas de arancel se generan con "puesta al día": si no se liquida un mes, la próxima liquidación completa las que falten y la numeración queda correlativa.
* `SP_ALTA_DICTADO` ahora también carga el área del dictado. Las participaciones totales de actividad, profesional y área siguen sin garantizarse (sólo se documentan).
* H9 dice que la primera cuota de arancel vence en la fecha de inscripción, pero §4.2 dice que la cuota k vence a los k × `meses_por_cuota` meses. Los scripts siguen H9; habría que corregir el texto de §4.2.
