# Hipotesis y a que integrante corresponden
## Lista completa de hipotesis
- H1. Se considera que todo socio pertenece a un único grupo familiar. Los titulares sin familiares asociados constituyen un grupo de un solo integrante. El titular tiene el número de orden 00 dentro de su grupo. 
- H2. Se considera que todos los integrantes de un grupo familiar comparten un único domicilio y un único teléfono. Estos datos se registran para el grupo y se consideran comunes a todos sus integrantes. 
- H3. Se interpreta que la expresión «si correspondiere» se aplica tanto al correo electrónico como al número de celular del socio, por lo que ambos datos son opcionales. 
- H4. Se supone que las categorías infantil, mayor y vitalicio constituyen una clasificación de los socios y que no existen atributos ni interrelaciones exclusivos de los socios de cada categoría. 
- H5. Se interpreta que el dato nombre comprende el nombre y el apellido de la persona, y se registra en un único atributo tanto para los socios como para los profesionales. 
- H6. La inscripción de un socio se realiza a una actividad, independientemente de sus dictados. Cada socio puede tener como máximo una inscripción vigente por actividad. 
- H7. Se supone que, dentro de un mismo dictado, todos los días programados comparten el mismo horario, las mismas áreas y los mismos profesionales responsables. Cuando alguna de estas condiciones varía según el día, se registran dictados separados. 
- H8. Se supone que el monto a pagar de cada cuota social o de arancel se fija al momento de su generación. Los cambios posteriores en el monto base, los porcentajes por categoría o los aranceles de las actividades no modifican los importes de las cuotas ya generadas. 
- H9. Se supone que los aranceles de las actividades se abonan por adelantado. La primera cuota vence en la fecha de inscripción y las siguientes vencen a partir de esa fecha, según la periodicidad de pago definida para la actividad. Se generan cuotas mientras la inscripción permanezca vigente. 
- H10. Se supone que un grupo familiar puede estar registrado sin tener todavía cuotas sociales generadas. Una vez realizada la liquidación correspondiente, se registra una única cuota social por grupo y por mes. 
- H11. Se supone que la categoría de cada socio es asignada y actualizada administrativamente por el club, sin derivarse automáticamente de su fecha de nacimiento. 
- H12. Se supone que, al cambiar la categoría de un socio, se dan de baja sus inscripciones a las actividades que no estén habilitadas para la nueva categoría. Las inscripciones compatibles se conservan. 
- H13. Se supone que los profesionales responsables se asignan a cada dictado de una actividad. Todo dictado debe contar con al menos un profesional a cargo. 
- H14. Se supone que el sistema administra exclusivamente la operatoria de un único club deportivo

## Integrante responsable

| Hipótesis | Integrante responsable | Módulo                                       |
| --------- | ---------------------- | -------------------------------------------- |
| H1        | Integrante 1           | Socios y grupos familiares                   |
| H2        | Integrante 1           | Socios y grupos familiares                   |
| H3        | Integrante 1           | Socios y grupos familiares                   |
| H4        | Integrante 1 y 3       | Socios y actividades                         |
| H5        | Integrante 1 y 5       | Socios y profesionales                       |
| H6        | Integrante 4           | Inscripciones y aranceles                    |
| H7        | Integrante 5 y 6       | Cronograma y áreas                           |
| H8        | Integrante 2, 3 y 4    | Cuotas sociales, actividades e inscripciones |
| H9        | Integrante 4           | Inscripciones y aranceles                    |
| H10       | Integrante 2           | Cuotas sociales                              |
| H11       | Integrante 1           | Socios y grupos familiares                   |
| H12       | Integrante 1 y 4       | Socios e inscripciones                       |
| H13       | Integrante 5           | Profesionales y cronograma                   |
| H14       | Todos                  | Sistema completo                             |

## Resumen por integrante
- Integrante 1 — Socios: H1, H2, H3, H4, H5, H11 y H12.
	- [[Hipotesis i1]]
- Integrante 2 — Cuotas sociales: H8 y H10.
	- [[Hipotesis i2]]
- Integrante 3 — Actividades: H4 y H8.
	- [[Hipotesis i3]]
- Integrante 4 — Inscripciones y aranceles: H6, H8, H9 y H12.
	- [[Hipotesis i4]]
- Integrante 5 — Profesionales y cronograma: H5, H7 y H13.
	- [[Hipotesis i5]]
- Integrante 6 — Áreas e instalaciones: H7.
	- [[Hipotesis i6]]
- Todos: H14.

Dos aclaraciones importantes:
1. H7 corresponde principalmente al integrante 5, porque DICTADO y DICTADO_DIA están en su módulo, pero también involucra al integrante 6 por las áreas.
2. H13 corresponde al integrante 5, aunque la asignación de profesionales también debe coordinarse con la lógica de DICTADO.