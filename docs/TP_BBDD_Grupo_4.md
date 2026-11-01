# 

# Universidad Nacional de Mar del Plata

# Facultad de Ingeniería

# Bases de Datos

# 

# 

# Club deportivo

# Trabajo práctico 

# 

# Grupo 4

# Aliende, Bautista Joaquín

# Cazorla Martinez, Nicolas

# Delgado, Facundo

# Pablo Navarro

# Palladino, Sofia

# Parise, Thiago

# Raimondi Pazos, Lucio

# 

# 

1. #  **Enunciado**

   ## **Introducción**

     
   El trabajo práctico tiene como objetivo que los alumnos implementen una solución para un problema de Diseño de Base de Datos extraído del mundo real utilizando las herramientas conceptuales y procedimentales vistas en clase, sobre algún motor de base de datos. El motor en el que se va a efectuar la entrega puede ser de tipo open source o no. En todos los casos los alumnos deberán asegurarse de contar con el software necesario para poder mostrar el trabajo práctico en las fechas y lugar de entrega.  
     
   Al momento de la corrección se tendrán en cuenta tanto la calidad de la solución (según características estudiadas) como el uso de las herramientas disponibles en el motor elegido.   
     
   La entrega deberá constar, como mínimo, de la siguiente documentación:  
1) Modelo de Entidad Relación y Modelo Relacional derivado, utilizados para implementar la solución.   
2) Detalle de los supuestos asumidos para la resolución del problema.  
3) Diseño físico correspondiente a la solución implementada.  
4) Restricciones adicionales al modelo.  
5) Código correspondiente a los stored procedures/ triggers que se hayan implementado en la solución.

   Además, la base que se use para efectuar la demostración deberá contener datos de prueba cargados de forma tal de poder evaluar las consultas que forman parte de los requerimientos.

   

   No es necesario entregar una interfaz para ejecutar las consultas, las mismas podrán ser ejecutadas directamente desde el motor de base de datos elegido.

   

## **Descripción del problema** 

## En un club deportivo, se necesita informatizar la operatoria referida a los socios, actividades que desarrollan y aranceles y cuotas.

De cada socio se registra su nombre, domicilio, teléfono, fecha de nacimiento, dirección de correo electrónico y número de celular si correspondiere. Además, a cada individuo se le asigna un número de socio. Para los grupos familiares, es necesario designar un titular. De esta forma se asigna un número de socio base, y luego un número de orden para los socios dentro del grupo. Por ejemplo, el socio titular puede ser el número 504/00, el cónyuge 504/01, y los hijos 504/02 y 504/03. En el caso de titulares sin familiares el número asignado es 504/00. Se asume que el grupo familiar tiene un domicilio y teléfono en común. Además, existen distintas categorías de socios, a saber: infantiles, mayores y vitalicios. Un socio titular debe pertenecer a la categoría ‘mayores’ o ‘vitalicios’.

El club ofrece a sus socios actividades, que pueden ser aranceladas o gratuitas. Hay actividades específicas para cada categoría de socio, por ejemplo, eventos recreativos infantiles. En cambio, otras actividades pueden ser practicadas por socios pertenecientes a distintas categorías, como por ejemplo natación.

Todas las actividades están a cargo de profesionales especializados (en general profesores de educación física). El club lleva registro de los datos personales de los mismos, y además de las actividades en las cuales podrían desempeñarse.

Por otro lado, para administrar adecuadamente el espacio disponible, la institución lleva registro de las distintas zonas/áreas: dónde están ubicadas dentro del predio, capacidad, estado de mantenimiento, actividades que se pueden desarrollar.

De esta manera, se realiza un cronograma donde se indica la actividad, a cargo de qué profesionales estará, el área donde se va a desarrollar, el turno (días y horario), y el período. Se registran las inscripciones de los socios en las distintas actividades, (registrando la fecha de la inscripción) siendo necesario verificar que la categoría del socio coincida con la categoría asociada a la actividad en la que se inscribe. Puede ocurrir, sobre todo cuando se inicia la actividad, que no tenga socios inscriptos. Una actividad puede desarrollarse en distintas áreas simultáneamente. Por ejemplo, las clases de tenis de los lunes y miércoles de 9 a 11, en el primer semestre del año en curso, a cargo de cuatro profesores, se desarrollan en las canchas 1 a 3 y en la 9\.  
Una vez inscripto el socio, es necesario llevar el control de los pagos de arancel (sólo para actividades aranceladas), a través del registro del monto abonado, la fecha y el cálculo de la deuda si existiera, teniendo en cuenta el arancel estipulado para cada actividad. Según la actividad los pagos pueden ser mensuales, bimestrales, o como se defina. 

Independientemente de los pagos de arancel de las actividades, mensualmente se liquida la cuota social. Para esto el club define un monto base para todos los socios, el período de vigencia, y un porcentaje de incremento/descuento asociado a cada categoría de socio. De esta forma se calcula la cuota mensual para cada grupo familiar, y se liquida a nombre del titular, registrando el monto a pagar, monto abonado, fecha de vencimiento y deuda si existiera.

2. #  **Hipótesis definidas**

   H1. Se considera que todo socio pertenece a un único grupo familiar. Los titulares sin familiares asociados constituyen un grupo de un solo integrante. El titular tiene el número de orden 00 dentro de su grupo.  
     
   H2. Se considera que todos los integrantes de un grupo familiar comparten un único domicilio y un único teléfono. Estos datos se registran para el grupo y se consideran comunes a todos sus integrantes.  
     
   H3. Se interpreta que la expresión «si correspondiere» se aplica tanto al correo electrónico como al número de celular del socio, por lo que ambos datos son opcionales.  
     
   H4. Se supone que las categorías infantil, mayor y vitalicio constituyen una clasificación de los socios y que no existen atributos ni interrelaciones exclusivos de los socios de cada categoría.  
     
   H5. Se interpreta que el dato nombre comprende el nombre y el apellido de la persona, y se registra en un único atributo tanto para los socios como para los profesionales.  
     
   H6. La inscripción de un socio se realiza a una actividad, independientemente de sus dictados. Cada socio puede tener como máximo una inscripción vigente por actividad.  
     
   H7. Se supone que, dentro de un mismo dictado, todos los días programados comparten el mismo horario, las mismas áreas y los mismos profesionales responsables. Cuando alguna de estas condiciones varía según el día, se registran dictados separados.  
     
   H8. Se supone que el monto a pagar de cada cuota social o de arancel se fija al momento de su generación. Los cambios posteriores en el monto base, los porcentajes por categoría o los aranceles de las actividades no modifican los importes de las cuotas ya generadas.  
     
   H9. Se supone que los aranceles de las actividades se abonan por adelantado. La primera cuota vence en la fecha de inscripción y las siguientes vencen a partir de esa fecha, según la periodicidad de pago definida para la actividad. Se generan cuotas mientras la inscripción permanezca vigente.  
     
   H10. Se supone que un grupo familiar puede estar registrado sin tener todavía cuotas sociales generadas. Una vez realizada la liquidación correspondiente, se registra una única cuota social por grupo y por mes.  
     
   H11. Se supone que la categoría de cada socio es asignada y actualizada administrativamente por el club, sin derivarse automáticamente de su fecha de nacimiento.  
     
   H12. Se supone que, al cambiar la categoría de un socio, se dan de baja sus inscripciones a las actividades que no estén habilitadas para la nueva categoría. Las inscripciones compatibles se conservan.  
     
   H13. Se supone que los profesionales responsables se asignan a cada dictado de una actividad. Todo dictado debe contar con al menos un profesional a cargo.  
     
   H14. Se supone que el sistema administra exclusivamente la operatoria de un único club deportivo.

3. #  **Diseño conceptual**

## **3.1. Diagrama Entidad–Relación**

LINK al Diseño: [https\://drive.google.com/file/d/12LT2\_KQ9QhMuFKNt1ivG6c5fGiHx8Sge/view?usp=sharing](https://drive.google.com/file/d/12LT2_KQ9QhMuFKNt1ivG6c5fGiHx8Sge/view?usp=sharing)

## **3.2. Restricciones adicionales**

4. #  **Diseño lógico**

## **4.1. Esquemas de relación**

CATEGORIA (nombre\_categoria, porcentaje\_mod\_cuota) PK \= CK \= {nombre\_categoria}

GRUPO\_FAMILIAR (nro socio \_base, domicilio, telefono) PK \= CK \= {nro\_socio\_base}

PROFESIONAL (dni, nombre, domicilio, telefono, titulo) PK \= CK \= {dni}

AREA (cod\_area, ubicacion, capacidad, estado\_mantenimiento) PK \= CK \= {cod\_area}

VALOR\_CUOTA\_SOCIAL (fecha\_desde, fecha\_hasta, monto\_base) PK \= CK \= {fecha\_desde}

SOCIO (nro\_socio\_base, nro\_orden, nombre, fecha\_nacimiento, correo\_electronico, celular, nombre\_categoria)  
 PK \= CK \= {(nro\_socio\_base, nro\_orden)} FK \= {nro socio \_base, nombre\_categoria}

* SOCIO.nro\_socio\_base debe estar en GRUPO\_FAMILIAR.nro\_socio\_base  
* GRUPO\_FAMILIAR.nro\_socio\_base debe estar en SOCIO.nro\_socio\_base  
* SOCIO.nombre\_categoria debe estar en CATEGORIA.nombre\_categoria  
* CATEGORIA.nombre\_categoria puede no estar en SOCIO.nombre\_categoria  
* SOCIO.nombre\_categoria no puede tomar valor nulo.  
    
  CUOTA\_SOCIAL (nro\_socio\_base, anio, mes, monto\_a\_pagar, monto\_abonado, fecha\_vencimiento, fecha\_pago)  
   PK \= CK \= {(nro socio \_base, anio, mes)} FK \= {nro\_socio\_base}  
* CUOTA\_SOCIAL.nro\_socio\_base debe estar en GRUPO\_FAMILIAR.nro\_socio\_base  
* GRUPO\_FAMILIAR.nro\_socio\_base puede no estar en CUOTA\_SOCIAL.nro\_socio\_base  
    
  ACTIVIDAD (cod\_actividad, nombre, tipo) PK \= CK \= {cod\_actividad}  
  ACTIVIDAD\_ARANCELADA (cod\_actividad, arancel, meses\_por\_cuota) PK \= CK \= FK \= {cod\_actividad}  
  ACTIVIDAD\_GRATUITA (cod\_actividad) PK \= CK \= FK \= {cod\_actividad}  
* ACTIVIDAD\_ARANCELADA.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* ACTIVIDAD\_GRATUITA.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* ACTIVIDAD.cod\_actividad debe estar en ACTIVIDAD\_ARANCELADA.cod\_actividad o (exclusivo) en ACTIVIDAD\_GRATUITA.cod\_actividad. La jerarquía es total, por eso "debe" y sin la opción "en ninguno".  
* ACTIVIDAD.tipo ∈ {'A', 'G'} y es coherente con la subentidad en la que figura.  
    
  HABILITADA\_PARA (cod\_actividad, nombre\_categoria) PK \= CK \= {(cod\_actividad, nombre\_categoria)} FK \= {cod\_actividad, nombre\_categoria}  
* HABILITADA\_PARA.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* HABILITADA\_PARA.nombre\_categoria debe estar en CATEGORIA.nombre\_categoria  
* ACTIVIDAD.cod\_actividad debe estar en HABILITADA\_PARA.cod\_actividad  
* CATEGORIA.nombre\_categoria puede no estar en HABILITADA\_PARA.nombre\_categoria  
    
  PUEDE\_DESEMPENIARSE\_EN (dni, cod\_actividad) PK \= CK \= {(dni, cod\_actividad)} FK \= {dni, cod\_actividad}  
* PUEDE\_DESEMPENIARSE\_EN.dni debe estar en PROFESIONAL.dni  
* PUEDE\_DESEMPENIARSE\_EN.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* PROFESIONAL.dni debe estar en PUEDE\_DESEMPENIARSE\_EN.dni  
* ACTIVIDAD.cod\_actividad puede no estar en PUEDE\_DESEMPENIARSE\_EN.cod\_actividad  
    
  APTA\_PARA (cod\_area, cod\_actividad) PK \= CK \= {(cod\_area, cod\_actividad)} FK \= {cod\_area, cod\_actividad}  
* APTA\_PARA.cod\_area debe estar en AREA.cod\_area  
* APTA\_PARA.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* AREA.cod\_area debe estar en APTA\_PARA.cod\_area  
* ACTIVIDAD.cod\_actividad puede no estar en APTA\_PARA.cod\_actividad  
    
  DICTADO (cod\_dictado, fecha\_desde, fecha\_fin, hora\_inicio, hora\_fin, cod\_actividad) PK \= CK \= {cod\_dictado} FK \= {cod\_actividad}  
* DICTADO.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad y no puede tomar valor nulo.  
* ACTIVIDAD.cod\_actividad puede no estar en DICTADO.cod\_actividad  
  DICTADO\_DIA (cod\_dictado, dia\_semana) PK \= CK \= {(cod\_dictado, dia\_semana)} FK \= {cod\_dictado}  
* DICTADO\_DIA.cod\_dictado debe estar en DICTADO.cod\_dictado  
* DICTADO.cod\_dictado debe estar en DICTADO\_DIA.cod\_dictado  
    
  A\_CARGO\_DE (cod\_dictado, dni) PK \= CK \= {(cod\_dictado, dni)} FK \= {cod\_dictado, dni}  
* A\_CARGO\_DE.cod\_dictado debe estar en DICTADO.cod\_dictado  
* A\_CARGO\_DE.dni debe estar en PROFESIONAL.dni  
* DICTADO.cod\_dictado debe estar en A\_CARGO\_DE.cod\_dictado  
* PROFESIONAL.dni puede no estar en A\_CARGO\_DE.dni  
    
  SE\_DESARROLLA\_EN (cod\_dictado, cod\_area) PK \= CK \= {(cod\_dictado, cod\_area)} FK \= {cod\_dictado, cod\_area}  
* SE\_DESARROLLA\_EN.cod\_dictado debe estar en DICTADO.cod\_dictado  
* SE\_DESARROLLA\_EN.cod\_area debe estar en AREA.cod\_area  
* DICTADO.cod\_dictado debe estar en SE\_DESARROLLA\_EN.cod\_dictado  
* AREA.cod\_area puede no estar en SE\_DESARROLLA\_EN.cod\_area  
    
  INSCRIPCION (nro\_socio\_base, nro\_orden, cod\_actividad, fecha\_inscripcion)  
   PK \= CK \= {(nro\_socio\_base, nro\_orden, cod\_actividad)} FK \= {(nro\_socio\_base, nro\_orden), cod\_actividad}  
* (INSCRIPCION.nro\_socio\_base, INSCRIPCION.nro\_orden) debe estar en (SOCIO.nro\_socio\_base, SOCIO.nro\_orden)  
* INSCRIPCION.cod\_actividad debe estar en ACTIVIDAD.cod\_actividad  
* (SOCIO.nro\_socio\_base, SOCIO.nro\_orden) puede no estar en (INSCRIPCION.nro\_socio\_base, INSCRIPCION.nro\_orden)  
* ACTIVIDAD.cod\_actividad puede no estar en INSCRIPCION.cod\_actividad  
    
  CUOTA\_ARANCEL (nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota, monto\_a\_pagar, fecha\_vencimiento, monto\_abonado, fecha\_pago)  
   PK \= CK \= {(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota)} FK \= {(nro\_socio\_base, nro\_orden, cod\_actividad)}  
* (CUOTA\_ARANCEL.nro\_socio\_base, CUOTA\_ARANCEL.nro\_orden, CUOTA\_ARANCEL.cod\_actividad) debe estar en (INSCRIPCION.nro\_socio\_base, INSCRIPCION.nro\_orden, INSCRIPCION.cod\_actividad)  
* (INSCRIPCION.nro\_socio\_base, INSCRIPCION.nro\_orden, INSCRIPCION.cod\_actividad) puede no estar en (CUOTA\_ARANCEL.nro\_socio\_base, CUOTA\_ARANCEL.nro\_orden, CUOTA\_ARANCEL.cod\_actividad)  
* Como en el ejemplo de Encuesta del apunte (3.2.10), la FK apunta a la agregación y no por separado a SOCIO y ACTIVIDAD.

## **4.2. Restricciones adicionales**

**Sobre socios y categorías:**

* "Todo grupo familiar tiene exactamente un socio con nro\_orden \= 0, que es su titular."  
* "El titular de un grupo familiar no puede pertenecer a la categoría infantiles."  
* "Las categorías son únicamente: infantiles, mayores y vitalicios."  
* "Un socio sólo puede inscribirse en una actividad habilitada para su categoría."

  **Sobre cuotas:**

* "Sólo generan cuota de arancel las inscripciones a actividades aranceladas."  
* "El monto abonado de una cuota está entre 0 y su monto a pagar. La deuda es la diferencia entre ambos y no se almacena."  
* "La cuota social de un grupo en un mes es la suma, sobre cada integrante, del monto base vigente en ese mes afectado por el porcentaje de su categoría."  
* "Los períodos de vigencia de VALOR\_CUOTA\_SOCIAL no se superponen ni dejan huecos."  
* "Las cuotas de una inscripción se numeran en forma correlativa desde 1, y la cuota k vence a los k × meses\_por\_cuota meses de la fecha de inscripción."

  **Sobre el cronograma de dictados:**

* "Todo profesional a cargo de un dictado debe poder desempeñarse en la actividad de ese dictado."  
* "Toda área en la que se desarrolla un dictado debe ser apta para la actividad de ese dictado."  
* "Un área o un profesional no puede estar asignado a dos dictados que coincidan en día, horario y período."  
* "En todo dictado, hora\_inicio \< hora\_fin y fecha\_desde ≤ fecha\_fin. dia\_semana toma valores de 1 a 7."							  
5.  **Normalización**

**5.1. Análisis de cada esquema**

**5.1.1 CUOTA\_SOCIAL**  
	  
CUOTA\_SOCIAL(nro\_socio\_base, anio, mes, deuda, fecha\_vencimiento,  monto\_a\_pagar, monto\_abonado, fecha\_pago)

CK \= {(nro\_socio\_base, anio, mes)}

FCUOTA\_SOCIAL \= {  
(nro\_socio\_base, anio, mes) → deuda, fecha\_vencimiento, monto\_a\_pagar, monto\_abonado, fecha\_pago  
}

		Atributos Primos: nro\_socio\_base, anio, mes	  
Atributos No Primos: deuda, fecha\_vencimiento, monto\_a\_pagar, monto\_abonado, fecha\_pago

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN. Dado que todos los atributos no primos dependen funcionalmente en su totalidad de la clave candidata compuesta (nro\_socio\_base, anio, mes), no es posible eliminar ningún componente del lado izquierdo de las dependencias sin perder la funcionalidad, lo que descarta la existencia de dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nro\_socio\_base, anio, mes) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
	**5.1.2 VALOR\_CUOTA\_SOCIAL**

VALOR\_CUOTA\_SOCIAL(fecha\_desde, fecha\_hasta, monto\_base)   
	CK \= {fecha\_desde}

FVALOR\_CUOTA\_SOCIAL \= {  
    fecha\_desde → fecha\_hasta, monto\_base  
}  
Atributos Primos: fecha\_desde  
Atributos No Primos: fecha\_hasta, monto\_base

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (fecha\_desde) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.

**5.1.3 GRUPO\_FAMILIAR**

GRUPO\_FAMILIAR(nro\_socio\_base, domicilio, telefono)   
CK \= {nro\_socio\_base}

FGRUPO\_FAMILIAR \= {  
	nro\_socio\_base → domicilio, telefono  
}  
		  
	Atributos Primos: nro\_socio\_base  
Atributos No Primos: domicilio, telefono

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nro\_socio\_base) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
**5.1.4 SOCIO**  
SOCIO(nro\_socio\_base, nro\_orden, nombre, fecha\_nacimiento, correo\_electronico, celular, nombre\_categoria)   
CK \= {(nro\_socio\_base, nro\_orden)}

FSOCIO \= {  
	nro\_socio\_base, nro\_orden → nombre, fecha\_nacimiento, correo\_electronico, celular, nombre\_categoria  
}

Atributos Primos: nro\_socio\_base, nro\_orden  
Atributos No Primos: nombre, fecha\_nacimiento, correo\_electronico, celular, nombre\_categoria

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal)**: Se encuentra en 2FN. Dado que todos los atributos no primos dependen funcionalmente en su totalidad de la clave candidata compuesta (nro\_socio\_base, nro\_orden), no es posible eliminar ningún componente del lado izquierdo de las dependencias sin perder la funcionalidad, lo que descarta la existencia de dependencias parciales.  
- **3FN (Tercera Forma Normal)**: Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nro\_socio\_base, nro\_orden) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd)**: Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
**5.1.5 SE\_INSCRIBE**  
	  
SE\_INSCRIBE(nro\_socio\_base, nro\_orden, cod\_actividad, fecha\_inscripcion)  
CK={((nro\_socio\_base, nro\_orden), cod\_actividad)} 

	FSE\_INSCRIBE \= {  
	(nro\_socio\_base, nro\_orden, cod\_actividad) → fecha\_inscripcion  
}  
Atributos Primos: nro\_socio\_base, nro\_orden, cod\_actividad  
Atributos No Primos: fecha\_inscripcion

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN. Dado que todos los atributos no primos dependen funcionalmente en su totalidad de la clave candidata compuesta (nro\_socio\_base, nro\_orden, cod\_actividad), no es posible eliminar ningún componente del lado izquierdo de las dependencias sin perder la funcionalidad, lo que descarta la existencia de dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nro\_socio\_base, nro\_orden, cod\_actividad) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
**5.1.6 ACTIVIDAD**  
	  
ACTIVIDAD(cod\_actividad, nombre, tipo)   
CK \= {cod\_actividad}

FACTIVIDAD \= {  
	cod\_actividad → nombre, tipo  
}  
	  
Atributos Primos: cod\_actividad  
Atributos No Primos: nombre, tipo

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (cod\_actividad) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.

**5.1.7 HABILITADA\_PARA**

	HABILITADA\_PARA(cod\_actividad, nombre\_categoria)   
	CK \= {(cod\_actividad, nombre\_categoria)} 

	FHABILITADA\_PARA \= ∅

Atributos Primos: cod\_actividad, nombre\_categoria  
Atributos No Primos: \-

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal)**: Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal)**: Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd)**: Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.


  

**5.1.8** **CATEGORIA**  
	  
CATEGORIA(nombre\_categoria, porcentaje\_mod\_cuota) CK={nombre\_categoria}

FCATEGORIA \= {  
		nombre\_categoria → porcentaje\_mod\_cuota  
}

Atributos Primos: nombre\_categoria  
Atributos No Primos: porcentaje\_mod\_cuota

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nombre\_categoria) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.

	**5.1.9 ACTIVIDAD\_ARANCELADA**  
	  
ACTIVIDAD\_ARANCELADA (cod\_actividad, arancel, meses\_por\_cuota)   
	CK \={cod\_actividad}  
	  
	FACTIVIDAD\_ARANCELADA  \= {  
		cod\_actividad → arancel, meses\_por\_cuota  
	}

		Atributos Primos: cod\_actividad  
Atributos No Primos: arancel, meses\_por\_cuota

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (cod\_actividad) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
	**5.1.10 ACTIVIDAD\_GRATUITA**  
	  
	ACTIVIDAD\_GRATUITA (cod\_actividad)   
	CK \= {cod\_actividad}

	FACTIVIDAD\_GRATUITA  \= ∅

		Atributos Primos: cod\_actividad  
Atributos No Primos: Ninguno

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.

**5.1.11 PROFESIONAL**   
		  
	PROFESIONAL(dni, domicilio, titulo, telefono, nombre)   
	CK \= {dni}

FPROFESIONAL \= { dni → domicilio, titulo, telefono, nombre }

Atributos Primos: dni  
	Atributos No Primos: domicilio, titulo, telefono, nombre

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (dni) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.

	**5.1.12 AREA**

	AREA(cod\_area, capacidad, estado\_mantenimiento, ubicacion)  
CK \= {cod\_area}

FAREA  \= {  
		cod\_area → capacidad, estado\_mantenimiento, ubicacion  
}

	Atributos Primos: cod\_area  
Atributos No Primos: capacidad, estado\_mantenimiento, ubicacion

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (cod\_area) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  
	**5.1.13 APTA\_PARA**  
	  
APTA\_PARA(cod\_actividad, cod\_area)  
PK \= {(cod\_actividad, cod\_area)}

	FAPTA\_PARA \= ∅

		Atributos Primos: cod\_actividad, cod\_area  
Atributos No Primos: \-

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal)**: Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal)**: Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.

	**5.1.14 PUEDE\_DESEMPEÑARSE\_EN**

PUEDE\_DESEMPEÑARSE\_EN(cod\_actividad, dni)  
CK \= {(cod\_actividad, dni)}

	FPUEDE\_DESEMPEÑARSE\_EN \= ∅

		Atributos Primos: cod\_actividad, dni  
Atributos No Primos: Ninguno.

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal)**: Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.

  

	**5.1.15 DICTADO**

	DICTADO(cod\_dictado, fecha\_desde, fecha\_fin, hora\_inicio, hora\_fin, dia\_semana, cod\_actividad)   
CK \= {cod\_dictado}

	FDICTADO\={   
		cod\_dictado → fecha\_desde, fecha\_fin, hora\_inicio, hora\_fin, dia\_semana, cod\_actividad } 

	Atributos Primos: cod\_dictado  
Atributos No Primos: fecha\_desde, fecha\_fin, hora\_inicio, hora\_fin, dia\_semana, cod\_actividad

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN, ya que al tratarse de una clave candidata simple, se satisface de forma automática al no existir subconjuntos propios que generen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (cod\_dictado) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.


  

	  
	  
**5.1.16 A\_CARGO\_DE**  
	  
A\_CARGO\_DE(cod\_dictado, dni)   
	CK \= {(cod\_dictado, dni)}  
	  
	FA\_CARGO\_DE \= ∅

		Atributos Primos: cod\_dictado, dni  
Atributos No Primos: \-

- **1FN (Primera Forma Normal)**: Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.


  

	**5.1.17 SE\_DESARROLLA\_EN**  
	  
SE\_DESARROLLA\_EN(cod\_dictado, cod\_area)   
	CK \= {(cod\_dictado, cod\_area)}

	FSE\_DESARROLLA\_EN \= ∅

	Atributos Primos: cod\_dictado, cod\_area  
Atributos No Primos: \-

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN de manera vacua, ya que al carecer totalmente de atributos no primos, no existen dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a la ausencia de dependencias funcionales no triviales, cumpliendo vacuamente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que no existen dependencias funcionales no triviales que vulneren la condición de Boyce-Codd.

	**5.1.18 CUOTA\_ARANCEL**  
	  
	CUOTA\_ARANCEL(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota, fecha\_vencimiento, monto\_abonado, monto\_a\_pagar, fecha\_pago)

CK \= {nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota}

FCUOTA\_ARANCEL{  
(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota) →  fecha\_vencimiento;  
(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota) →  monto\_abonado;  
(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota) →  monto\_a\_pagar;  
(nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota) →  fecha\_pago;  
}

	Atributos Primos: nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota  
	Atributos No Primos: fecha\_vencimiento, monto\_abonado, monto\_a\_pagar, fecha\_pago

- **1FN (Primera Forma Normal):** Se encuentra en 1FN ya que todos los atributos contienen valores atómicos y no existen grupos repetitivos.  
- **2FN (Segunda Forma Normal):** Se encuentra en 2FN. Dado que todos los atributos no primos dependen funcionalmente en su totalidad de la clave candidata compuesta (nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota), no es posible eliminar ningún componente del lado izquierdo de las dependencias sin perder la funcionalidad, lo que descarta la existencia de dependencias parciales.  
- **3FN (Tercera Forma Normal):** Se encuentra en 3FN, debido a que para toda dependencia funcional no trivial $X\rightarrow Y$, el determinante $X$ (nro\_socio\_base, nro\_orden, cod\_actividad, nro\_cuota) es una superclave de la relación, cumpliendo formalmente con la condición requerida.  
- **FNBC (Forma Normal de Boyce-Codd):** Se encuentra en FNBC, ya que el único determinante de las dependencias funcionales no triviales es la clave candidata, la cual es superclave por definición.  
  

  **5.2. Forma normal del diseño completo**  
  El diseño relacional completo del sistema se encuentra normalizado hasta la Forma Normal de Boyce-Codd (BCNF), ya que cada uno de los esquemas individuales que lo componen cumple con los requisitos teóricos desde la Primera Forma Normal (1FN) hasta la BCNF, garantizando la consistencia absoluta de los datos y la ausencia de anomalías de inserción, borrado y modificación.