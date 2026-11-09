# Decisiones abiertas del TP (para cerrar entre todos)

Tenemos 4 puntos sin definir que el enunciado no resuelve. Para cada uno van las opciones y lo que proponemos, así alcanza con responder "ok" o "no, mejor X". El detalle técnico de cada uno está en [pendientes_diseno.md](pendientes_diseno.md).

Restricción a tener en cuenta en todas las opciones: **no se admiten atributos multivaluados** en el modelo lógico ni en las tablas. Si un dato puede tomar varios valores a la vez, va en una tabla aparte (como `DICTADO_DIA`).

## 1. Estados de mantenimiento de un área (`AREA.estado_mantenimiento`)

Hoy es un `VARCHAR(30)` de texto libre. El enunciado no dice qué valores puede tener ni si un área puede tener más de un estado a la vez.

* Propuesta: un único estado por área (atributo monovaluado), restringido con un `CHECK` a `Operativa`, `En mantenimiento` y `Fuera de servicio`.
* Alternativa, si un área puede tener varios estados a la vez o se quiere guardar el historial: no se puede guardar en una sola columna (sería un atributo multivaluado). Habría que sacarlo a una tabla aparte, por ejemplo `ESTADO_AREA (cod_area, estado, fecha_desde)`, y cambia el modelo relacional de §4.1.
* Preguntas:
   * ¿Un área tiene un solo estado en cada momento?
   * ¿Esos tres valores o cuáles?

## 2. Baja de inscripciones al cambiar de categoría (H12)

H12 dice que cuando un socio cambia de categoría, se dan de baja sus inscripciones a actividades no habilitadas para la nueva. Hoy `INSCRIPCION` no tiene forma de marcar una baja.

* Ya implementado (a confirmar por el grupo): se agregó `estado` (`Activa` o `Baja`) y `fecha_baja` a `INSCRIPCION`, más un trigger sobre `SOCIO` que da la baja. Para poder reinscribirse después de una baja (H6 pide una inscripción *vigente* por actividad), la PK de `INSCRIPCION` ahora incluye `fecha_inscripcion`, y la FK de `CUOTA_ARANCEL` también. Cambia el modelo relacional de §4.1.
* Alternativa descartada por ahora: borrar las filas de `INSCRIPCION`, sin cambiar el modelo. Se pierde el historial y el dato de "inscripto el año pasado" que usa la consulta 2.
* Preguntas que quedan:
   * ¿Una inscripción dada de baja deja de generar cuotas de arancel? Lo implementamos así, y las cuotas ya generadas se mantienen.
   * ¿Una inscripción dada de baja cuenta en la consulta 2? Lo implementamos así, porque el socio estuvo inscripto ese año.
   * ¿Una reinscripción crea una fila nueva (con otra fecha de inscripción)? Un socio no puede reinscribirse el mismo día de su inscripción anterior.

## 3. Consulta 2: "socios inscriptos en todas las actividades gratuitas el año pasado"

* Decidido: si no hay filas para mostrar, no se muestra nada. La consulta sólo lista las categorías con al menos un socio que cumple; si no existe ninguna actividad gratuita ("todas" se cumpliría en vacío) o nadie cumple, no devuelve filas.
* "Año pasado" lo interpretamos como el año de `fecha_inscripcion`: `YEAR(GETDATE()) - 1`.
* Pregunta: ¿les parece bien lo de "año pasado", o lo consultamos con la cátedra?

## 4. Consultas 1 y 2 como vistas

Quedaron como vistas (`VW_TITULARES_DEUDA_ANIO_ACTUAL` y `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`) que usan `YEAR(GETDATE())` y `YEAR(GETDATE()) - 1`, siguiendo el enunciado al pie de la letra ("año en curso" y "año pasado"). Sólo confirmamos que el grupo está de acuerdo.

## 5. Para informar (no hace falta decidir)

* Las cuotas de arancel se generan con "puesta al día": si no se liquida un mes, la próxima liquidación completa las que falten y la numeración queda correlativa.
* `SP_ALTA_DICTADO` ahora también carga el área del dictado. Las participaciones totales de actividad, profesional y área siguen sin garantizarse (sólo se documentan).
* H9 dice que la primera cuota de arancel vence en la fecha de inscripción, pero §4.2 dice que la cuota k vence a los k × `meses_por_cuota` meses. Los scripts siguen H9; habría que corregir el texto de §4.2.
