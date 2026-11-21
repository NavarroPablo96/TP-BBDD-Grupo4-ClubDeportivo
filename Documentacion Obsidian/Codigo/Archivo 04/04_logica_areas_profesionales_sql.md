¡Perfecto! Manteniendo la misma estructura del cuadro anterior, este es el listado del Código 04, respetando el orden en el que aparecen los objetos en el archivo.
### Division:
- [[i6 04_logica_areas_profesionales]]
- [[Comun i6 i5 04_logica_areas_profesionales]]
- [[i5 04_logica_areas_profesionales]]
## Código 04 – Triggers, procedimientos almacenados y vistas



| Tipo                     | Nombre                                                   | Tabla / referencia                                   | Integrante   |
| ------------------------ | -------------------------------------------------------- | ---------------------------------------------------- | ------------ |
| Procedimiento almacenado | `SP_ALTA_`<br>`AREA`                                     | AREA, HISTORIAL_AREA_ESTADO                          | ==🟢I6==     |
| Procedimiento almacenado | `SP_CAMBIAR_`<br>`ESTADO_AREA`                           | HISTORIAL_AREA_ESTADO                                | ==🟢I6==     |
| Vista                    | `VW_ESTADO_`<br>`ACTUAL_AREA`                            | AREA, HISTORIAL_AREA_ESTADO                          | ==🟢I6==     |
| Vista                    | `VW_AREA_ESTADO_`<br>`PERIODO`                           | HISTORIAL_AREA_ESTADO                                | ==🟢I6==     |
| Vista                    | `VW_CONFLICTOS_`<br>`ESTADO_DICTADO`                     | DICTADO, SE_DESARROLLA_EN,<br>VW_AREA_ESTADO_PERIODO | ==🔵I5, I6== |
| Trigger                  | `TR_DICTADO_AREA_`<br>`OPERATIVA_SE_`<br>`DESARROLLA_EN` | ON SE_DESARROLLA_EN                                  | ==🔵I5, I6== |
| Trigger                  | `TR_DICTADO_AREA_`<br>`OPERATIVA_DICTADO`                | ON DICTADO                                           | ==🔵I5, I6== |
| Trigger                  | `TR_DICTADO_AREA_`<br>`OPERATIVA_`<br>`HISTORIAL`        | ON HISTORIAL_AREA_ESTADO                             | ==🔵I6==     |
| Trigger                  | `TR_SE_DESARROLLA_EN_`<br>`AREA_APTA`                    | ON SE_DESARROLLA_EN                                  | ==🔵I5, I6== |
| Trigger                  | `TR_A_CARGO_DE_`<br>`PROF_HABILITADO`                    | ON A_CARGO_DE                                        | ==I5==       |


Total:
- 5 triggers.
- 2 procedimientos almacenados.
- 3 vistas.

Aclaraciones:
- `VW_CONFLICTOS_ESTADO_DICTADO` utiliza `VW_AREA_ESTADO_PERIODO`, que es otra vista, además de las tablas indicadas.
- Los objetos que involucran a `DICTADO` y `SE_DESARROLLA_EN` se asocian a I5; los que involucran áreas e historial de estados se asocian a I6.
- I3 aparece porque `TR_A_CARGO_DE_PROF_HABILITADO` y `TR_SE_DESARROLLA_EN_AREA_APTA` consultan `ACTIVIDAD` mediante sus relaciones.

Así mantenemos el mismo criterio de asignación que utilizamos en el cuadro anterior.