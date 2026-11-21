
## El objetivo del archivo
- El objetivo del archivo es ==cargar datos== de prueba en la base de datos y ==ejecutar operaciones== que permitan verificar el correcto funcionamiento 
	- de las ==dos consultas principales== exigidas por la cátedra: 
		- titulares de grupos familiares con deuda de cuotas sociales del año actual y 
		- cantidad de socios por categoría inscriptos en todas las actividades gratuitas del año anterior.
- Por lo tanto, busca cumplir principalmente con el requisito de la consigna de contar con datos de prueba cargados para evaluar las consultas solicitadas.

# Orden del archivo 9 secciones:

|N.º|Nombre de la sección|
|---|---|
|1|Alta de actividades|
|2|Alta de grupos familiares y socios|
|3|Liquidación y pago de cuotas sociales|
|4|Inscripción a actividades gratuitas|
|5|Alta de profesional y configuración de áreas|
|6|Relaciones y creación de dictado|
|7|Inscripción a actividad arancelada y liquidación de cuotas|
|8|Pagos arancelados y cálculo de deuda|
|9|Consultas y verificación de resultados|

Aclaración: este archivo es diferente de los anteriores porque no define triggers, procedimientos almacenados ni vistas nuevas. Utiliza procedimientos ya creados, inserta y actualiza datos, y consulta vistas existentes.

# Asociación archivo 05 con ==consigna==
## 1. Correspondencia con los requerimientos de la cátedra

| Parte exacta de la consigna                                                                                                                                            | ¿Dónde se cumple en tu archivo?                                                                                   |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Datos de prueba cargados para evaluar las consultas requeridas.                                                                                                        | Secciones 1 a 8.                                                                                                  |
| Datos del socio titular de grupos familiares que adeuden cuotas sociales del año en curso, junto con el importe total adeudado y la cantidad de integrantes del grupo. | ==Sección 3== (genera las cuotas y simula los pagos) y ==sección 9== (consulta `VW_TITULARES_DEUDA_ANIO_ACTUAL`). |
| Cantidad de socios por categoría que se hayan inscripto en todas las actividades gratuitas durante el año pasado.                                                      | ==Sección 4== (carga las inscripciones) y ==sección 9== (consulta `VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR`).           |
| Llevar control de pagos de aranceles, registrando monto abonado, fecha y deuda.                                                                                        | Secciones 7, 8 y 9.                                                                                               |
| Liquidación mensual de la cuota social, registrando los importes abonados y la deuda.                                                                                  | Sección 3.                                                                                                        |
| Registro de profesionales, áreas, actividades y cronogramas.                                                                                                           | Secciones 1, 5 y 6.                                                                                               |
| Inscripciones de socios en actividades, registrando la fecha de inscripción.                                                                                           | Secciones 4 y 7.                                                                                                  |

## 2. Las dos consultas principales que exige la cátedra
Estas son las ==dos partes más importantes== que tu archivo permite demostrar:

Primera consulta:
> Los datos del socio titular de grupos familiares que adeuden cuotas sociales del año en curso, junto con el importe total adeudado, y la cantidad de integrantes del grupo.

Se verifica mediante:
``` SQL
--- SECCION 3 (Carga datos) y SECCION 9 ejecuta esta consulta
SELECT * FROM VW_TITULARES_DEUDA_ANIO_ACTUAL;
```

Segunda consulta:
> La cantidad de socios por categoría que se hayan inscripto en todas las actividades gratuitas durante el año pasado.

Se verifica mediante:
```SQL
--- SECCION 4 carga datos y Seccion 9 ejeccuta→
SELECT * FROM VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR;
```
