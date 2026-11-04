Facultad de Ingeniería 



<!-- Start of picture text -->
UNIVERSIDAD NACIONAL<br>de MAR DEL PLATA<br><!-- End of picture text -->

_Bases de Datos y Diseño de Base de Datos_ 

# **Trabajo Práctico** 

## **Introducción** 

El trabajo práctico tiene como objetivo que los alumnos implementen una solución para un problema de Diseño de Base de Datos extraído del mundo real utilizando las herramientas conceptuales y procedimentales vistas en clase, sobre algún motor de base de datos. El motor en el que se va a efectuar la entrega puede ser de tipo _open source_ o no. En todos los casos los alumnos deberán asegurarse de contar con el software necesario para poder mostrar el trabajo práctico en las fechas y lugar de entrega. 

Al momento de la corrección se tendrán en cuenta tanto la calidad de la solución (según características estudiadas) como el uso de las herramientas disponibles en el motor elegido. 

La entrega deberá constar, como mínimo, de la siguiente documentación: 

- **a)** Modelo de Entidad Relación y Modelo Relacional derivado, utilizados para implementar la solución. 

- **b)** Detalle de los supuestos asumidos para la resolución del problema. 

- **c)** Diseño físico correspondiente a la solución implementada. 

- **d)** Restricciones adicionales al modelo. 

- **e)** Código correspondiente a los _stored procedures/ triggers_ que se hayan implementado en la solución. 

Además, la base que se use para efectuar la demostración deberá contener datos de prueba cargados de forma tal de poder evaluar las consultas que forman parte de los requerimientos. 

No es necesario entregar una interfaz para ejecutar las consultas, las mismas podrán ser ejecutadas directamente desde el motor de base de datos elegido. 

### **_Recomendamos la consulta periódica con los docentes sobre el avance del trabajo, antes de la fecha de entrega_** . 

_Prof. Dra. Leticia M. Seijas_ 

_1_ 

Facultad de Ingeniería 



_Bases de Datos y Diseño de Base de Datos_ 

## **Descripción del problema** 

En un club deportivo, se necesita informatizar la operatoria referida a los socios, actividades que desarrollan y aranceles y cuotas. 

De cada socio se registra su nombre, domicilio, teléfono, fecha de nacimiento, dirección de correo electrónico y número de celular si correspondiere. Además, a cada individuo se le asigna un número de socio. Para los grupos familiares, es necesario designar un titular. De esta forma se asigna un número de socio base, y luego un número de orden para los socios dentro del grupo. Por ejemplo, el socio titular puede ser el número 504/00, el cónyuge 504/01, y los hijos 504/02 y 504/03. En el caso de titulares sin familiares el número asignado es 504/00. Se asume que el grupo familiar tiene un domicilio y teléfono en común. Además, existen distintas categorías de socios, a saber: infantiles, mayores y vitalicios. Un socio titular debe pertenecer a la categoría ‘mayores’ o ‘vitalicios’. 

El club ofrece a sus socios actividades, que pueden ser aranceladas o gratuitas. Hay actividades específicas para cada categoría de socio, por ejemplo, eventos recreativos para infantiles. En cambio, otras actividades pueden ser practicadas por socios pertenecientes a distintas categorías, como por ejemplo natación. 

Todas las actividades están a cargo de profesionales especializados (en general profesores de educación física). El club lleva registro de los datos  personales de los mismos, y además de las actividades en las cuales podrían desempeñarse. 

Por otro lado, para administrar adecuadamente el espacio disponible, la institución lleva registro de las distintas zonas/áreas: dónde están ubicadas dentro del predio, capacidad, estado de mantenimiento, actividades que se pueden desarrollar. 

De esta manera, se realiza un cronograma donde se indica la actividad, a cargo de qué profesionales estará, el área donde se va a desarrollar, el turno (días y horario), y el período. Se registran las inscripciones de los socios en las distintas actividades, (registrando la fecha de la inscripción) siendo necesario verificar que la categoría del socio coincida con la categoría asociada a la actividad en la que se inscribe. Puede ocurrir, sobre todo cuando se inicia la actividad, que no tenga socios inscriptos. Una actividad puede desarrollarse en distintas áreas simultáneamente. Por ejemplo, las clases de tenis de los lunes y miércoles de 9 a 11, en el primer semestre del año en curso, a cargo de cuatro profesores, se desarrollan en las canchas 1 a 3 y en la 9. 

Una vez inscripto el socio, es necesario llevar el control de los pagos de arancel (sólo para actividades aranceladas), a través del registro del monto abonado, la fecha y el cálculo de la deuda si existiera, teniendo en cuenta el arancel estipulado para cada actividad. Según la actividad los pagos pueden ser mensuales, bimestrales, o como se defina. 

_Prof. Dra. Leticia M. Seijas_ 

_2_ 

Facultad de Ingeniería 



<!-- Start of picture text -->
UNIVERSIDAD NACIONAL<br>de MAR DEL PLATA<br><!-- End of picture text -->

_Bases de Datos y Diseño de Base de Datos_ 

Independientemente de los pagos de arancel de las actividades, mensualmente se liquida la cuota social. Para esto el club define un monto base para todos los socios, el período de vigencia, y un porcentaje de incremento/descuento asociado a cada categoría de socio. De esta forma se calcula la cuota mensual para cada grupo familiar, y se liquida a nombre del titular, registrando el monto a pagar, monto abonado, fecha de vencimiento y deuda si existiera. 

### **Comentario de la cátedra:** 

Las funcionalidades que se esperan implementadas (stored procedures/triggers/vistas/SQL embebido/transacciones) son: 



<!-- Start of picture text -->
><br><!-- End of picture text -->

- Los datos del socio titular de grupos familiares que adeuden cuotas sociales del año en curso, junto con el importe total adeudado, y la cantidad de integrantes del grupo. 



<!-- Start of picture text -->
><br><!-- End of picture text -->

- La cantidad de socios por categoría que se hayan inscripto en todas las actividades gratuitas durante el año pasado. 



<!-- Start of picture text -->
><br><!-- End of picture text -->

- Resolución de alguna de las implicancias del problema utilizando triggers. 



<!-- Start of picture text -->
><br><!-- End of picture text -->

- Desarrollar un aplicación sencilla en un lenguaje host que acceda a la base de datos y permita realizar una operación sobre la misma, justificando el uso de transacciones. Por ejemplo, la inscripción de socios a actividades. 

_Prof. Dra. Leticia M. Seijas_ 

_3_ 

