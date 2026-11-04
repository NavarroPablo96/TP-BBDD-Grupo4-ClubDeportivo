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

* Propuesta: agregar `estado` (`Activa` o `Baja`) y `fecha_baja` a `INSCRIPCION`, más un trigger sobre `SOCIO` que haga la baja. Cambia el modelo relacional de §4.1.
* Alternativa: borrar las filas de `INSCRIPCION`, sin cambiar el modelo. Se pierde el historial. También se perdería el dato de "inscripto el año pasado" que usa la consulta 2.
* Preguntas derivadas si se agrega el estado:
   * ¿Una inscripción dada de baja deja de generar cuotas de arancel? Proponemos que sí, y que las cuotas ya generadas se mantengan.
   * ¿Una inscripción dada de baja cuenta en la consulta 2? Proponemos que sí, porque el socio estuvo inscripto ese año.

## 3. Consulta 2: "socios inscriptos en todas las actividades gratuitas el año pasado"

* Si no existe ninguna actividad gratuita, "todas" se cumple en vacío y entrarían todos los socios. Proponemos que no cuente a nadie.
* "Año pasado" lo interpretamos como el año de `fecha_inscripcion`, y la consulta recibe el año como parámetro.
* Pregunta: ¿les parece bien, o lo consultamos con la cátedra?

## 4. Consultas 1 y 2 como stored procedures

Ya las dejamos como SP con parámetro de año, no como vistas, para poder probar con años pasados. Sólo confirmamos que el grupo está de acuerdo.
