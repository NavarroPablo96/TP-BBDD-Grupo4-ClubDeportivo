_1_ 

_Diseño de Base de Datos Relacionales_ 

_<u>Modelización:</u> Proceso para obtener un  diseño de Base de Datos, partiendo de un relevamiento de datos y análisis de requerimientos_ 



<!-- Start of picture text -->
Proceso de Diseño Relevamiento y análisis<br>de requerimientos<br>Diseño conceptual de la<br>Base de Datos<br>Esquema lógico de Base de Datos<br>formado por esquemas de relación y<br>restricciones. Medida de calidad<br>Diseño lógico de la<br>Ej:  de un diseño:<br>EMPLEADO (nro-leg, nombre, tel) Base de Datos<br>Formas Normales<br>-<br>DEPTO (nro d, nombre-d)<br>- -<br>TRABAJO (nro leg, nro d, período)<br>Diseño físico de la Base<br>de Datos<br><!-- End of picture text -->

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_2_ 

# **_<u>Modelo Lógico Relacional</u>_** _<u>:</u> Considera a la Base de Datos como una colección de relaciones._ 

_<u>Relación:</u> Intuitivamente puede asociarse con una TABLA, conformada por filas y columnas_ 

### **_Nombre de la relación_** 

### **EMPLEADO** 

|_Nro_legajo_|_Nombre_|_Apellido_|**. . .**|_Fecha_nacimiento_||
|---|---|---|---|---|---|
|1102|Martín|Gómez||25/01/1980||
|1105|Natalia|Paz||05/04/1975|**_Fila – tupla_**|
|1110|Manuel|Pereira||03/10/1979|_(hecho de la realidad)_|



**_Columna – Atributo_** _(asociado a un DOMINIO)_ 

_Esquema de Relación: describe la relación   -_ **_R(A1, A2, …, An)_** 

#### **EMPLEADO(Nro-legajo, Nombre, Apellido, Fecha_nacimiento)** 

_Instancia de Relación o Relación r de un esquema de relación R(A1, A2, …, An): r(R) es un subconjunto del producto cartesiano de los dominios que definen R, r(R)_ ⊆ _(dom(A1)  X  dom(A2)  X  … X  dom(An))_ 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_3_ 

# **_<u>Modelo Lógico Relacional</u>_** 

# _<u>Restricciones:</u>_ 

- _Dominio_ 

- _Clave (Superclave – Clave candidata – Clave primaria)_ 

_Dado R, para cualquier r(R), t1 y t2 dos tuplas distintas cualesquiera, SK conjunto de_ 

_atributos que constiutyen una superclave en R:   t1[SK]_ ≠ _t2[SK]_ 

- _Integridad referencial (Clave foránea)_ 

_Sean R . FK es 1 y R2 dos esquemas de relación y FK un subconjunto de atributos en R2. clave foránea en R2 si:_ 

_* Los atributos en FK tienen el mismo dominio que los atributos de la clave primaria de R1_ 

_* Un valor para FK en una tupla t2 en R2 debe existir como valor de clave primaria para alguna tupla t1 en R1, o en caso que no exista debe tomar valor nulo._ 

## • _Dependencias de datos (ej: dependencias funcionales)_ 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_4_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _1. Conjuntos de Entidades Fuertes_ 



<!-- Start of picture text -->
Apellido Nombre<br>N° LU<br>ESTUDIANTE (DER)<br><!-- End of picture text -->

### **ESTUDIANTE (N°LU, Apellido, Nombre)** 

(MR) 

### _2. Conjuntos de Entidades Débiles_ 



<!-- Start of picture text -->
N° Importe N°Pago Fecha-Pago<br>prestamo<br>Importe-<br>1 N pago (DER)<br>PRESTAMO PAGO<br>Asociado-a<br><!-- End of picture text -->

### **PRESTAMO(N°prestamo, Importe) PAGO(N°prestamo, N°Pago, Fecha-Pago, Importe-Pago)** 

(MR) 

PRESTAMO.N°prestamo puede no estar en PAGO.N°prestamo PAGO.N°prestamo debe estar en PRESTAMO.N°prestamo 

PRESTAMO   CK={(N°Prestamo)} - PK={(N°Prestamo)} 

PAGO             CK={(N°Prestamo,N°Pago)} - PK={(N°Prestamo,N°Pago)} – FK = {(N°Prestamo)} 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_5_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _3. Interrelaciones 1:1_ 



<!-- Start of picture text -->
Apellido Fecha- Nombre<br>N° legajo Nombre ini-dir N°<br>Proyecto<br>1 1<br>Sueldo EMPLEADO PROYECTO<br>Fecha- Dirige<br>Nacimiento<br><!-- End of picture text -->

### **EMPLEADO(N°legajo, Apellido, Nombre, Fecha-Nacimiento, Sueldo) PROYECTO(N°Proyecto, Nombre, N°legajoDirector, Fecha-ini-dir)** 

PROYECTO.NºlegajoDirector puede ser nulo EMPLEADO.N°legajo puede no estar en PROYECTO.N°legajoDirector 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_6_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _4. Interrelaciones 1:N_ 



<!-- Start of picture text -->
Apellido Nombre<br>N° legajo Nombre N°<br>Proyecto<br>N 1<br>Sueldo EMPLEADO PROYECTO<br>Fecha-<br>Nacimiento Trabaja-en<br><!-- End of picture text -->

### **EMPLEADO(N°legajo,Apellido,Nombre,Fecha-Nacimiento, Sueldo, N°Proyecto) PROYECTO(N°Proyecto, Nombre)** 

EMPLEADO.N°Proyecto no puede ser nulo y debe estar en PROYECTO.N°Proyecto PROYECTO.NºProyecto puede no estar en EMPLEADO.N°Proyecto 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_7_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _5. Interrelaciones M:N_ 



<!-- Start of picture text -->
Apellido Nombre Nombre<br>N° legajo N°<br>Proyecto<br>M N<br>Sueldo EMPLEADO PROYECTO<br>Trabaja-en<br>Fecha-<br>Nacimiento<br><!-- End of picture text -->

**EMPLEADO(N°legajo, Apellido, Nombre, Fecha-Nacimiento, Sueldo) PROYECTO(N°Proyecto, Nombre)** 

### **TRABAJA-EN(N°legajo, N°Proyecto)** 

PROYECTO.NºProyecto puede no estar en TRABAJA-EN.NºProyecto EMPLEADO.N°legajo debe estar en TRABAJA-EN.N°legajo 

TRABAJA-EN.N°legajo debe estar en EMPLEADO.N°legajo TRABAJA-EN.N°Proyecto debe estar en PROYECTO.N°Proyecto 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_8_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _6. Interrelaciones unarias_ 



<!-- Start of picture text -->
Apellido Nombre<br>Es supervisor<br>N°legajo<br>1<br>EMPLEADO<br>Supervisa<br>N<br>Es<br>supervisado<br><!-- End of picture text -->

#### **EMPLEADO(N°legajo, Apellido, Nombre, N°legSupervisor)** 

EMPLEADO.N°legajo puede no estar en EMPLEADO.N°legSupervisor EMPLEADO.N°legSupervisor no puede ser nulo 

EMPLEADO.N°legSupervisor debe estar en EMPLEADO.N°legajo 



<!-- Start of picture text -->
Cod- Nombre<br>Origen Km<br>ciudad<br>M<br>Ubicación-<br>CIUDAD<br>geográfica<br>N<br>Destino<br><!-- End of picture text -->

#### **CIUDAD(Cod-ciudad, Nombre, Ubicación-geografica) DISTA-DE(Cod-ciudad-origen, Cod-ciudad-destino, Km)** 

DISTA-DE.Cod-ciudad-origen debe estar en CIUDAD.Cod-ciudad DISTA-DE.Cod-ciudad-destino debe estar en CIUDAD.Cod-ciudad CIUDAD.Cod-ciudad puede no estar en DISTA-DE.Cod-ciudad-origen CIUDAD.Cod-ciudad puede no estar en DISTA-DE.Cod-ciudad-destino 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_9_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 



<!-- Start of picture text -->
7. Interrelaciones ternarias 1:1:1 Fecha-<br>N°legajo nacimiento Descripción<br>Supervisa N°Proyecto<br>Nombre EMPLEADO 1 1 PROYECTO<br>Fecha-<br>inicio<br>Apellido<br>1<br>PLANTA<br>EMPLEADO(N°legajo, Nombre, Apellido, Fecha-nacimiento) N°Planta<br>PROYECTO(N°Proyecto, Descripción, Fecha-inicio) Ubicación Descripción<br>PLANTA(N°Planta, Descripción, Ubicación)<br>SUPERVISA(N°legajo, N°Proyecto, N°Planta)<br><!-- End of picture text -->

SUPERVISA CK = {(N°legajo, N°Proyecto), (N°legajo, N°Planta), (N°Planta, N°Proyecto)} 

SUPERVISA.N°legajo debe estar en EMPLEADO.N°legajo SUPERVISA.N°Proyecto debe estar en PROYECTO.N°Proyecto SUPERVISA.N°Planta debe estar en PLANTA.N°Planta 

(SUPERVISA.N°Planta NO puede ser nulo, por definición de interrelación ternaria) EMPLEADO.N°legajo puede estar en SUPERVISA.N°legajo PROYECTO.N°Proyecto debe estar en SUPERVISA.N°Proyecto PLANTA.N°Planta debe estar en SUPERVISA.N°Planta 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_10_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 



<!-- Start of picture text -->
8. Interrelaciones ternarias 1:1:N Fecha-<br>N°legajo nacimiento Descripción<br>Supervisa N°Proyecto<br>Nombre EMPLEADO 1 N PROYECTO<br>Fecha-<br>inicio<br>Apellido<br>1<br>PLANTA<br>N°legajo, Nombre, Apellido, Fecha-nacimiento)°legajo, Nombre, Apellido, Fecha-nacimiento)legajo, Nombre, Apellido, Fecha-nacimiento), Nombre, Apellido, Fecha-nacimiento) Nombre, Apellido, Fecha-nacimiento) N°Planta<br>(N°Proyecto, Descripción, Fecha-inicio)°Proyecto, Descripción, Fecha-inicio)Proyecto, Descripción, Fecha-inicio), Descripción, Fecha-inicio) Descripción, Fecha-inicio) Ubicación Descripción<br><!-- End of picture text -->

**EMPLEADO(N°legajo, Nombre, Apellido, Fecha-nacimiento)°legajo, Nombre, Apellido, Fecha-nacimiento)legajo, Nombre, Apellido, Fecha-nacimiento), Nombre, Apellido, Fecha-nacimiento) Nombre, Apellido, Fecha-nacimiento) PROYECTO(N°Proyecto, Descripción, Fecha-inicio)°Proyecto, Descripción, Fecha-inicio)Proyecto, Descripción, Fecha-inicio), Descripción, Fecha-inicio) Descripción, Fecha-inicio) PLANTA(N°Planta, Descripción, Ubicación) SUPERVISA(N°legajo, N°Proyecto, N°Planta)** 

SUPERVISA CK = {(N°legajo, N°Proyecto), (N°Planta, N°Proyecto)} 

SUPERVISA.N°legajo debe estar en EMPLEADO.N°legajo SUPERVISA.N°Proyecto debe estar en PROYECTO.N°Proyecto SUPERVISA.N°Planta debe estar en PLANTA.N°Planta 

(SUPERVISA.N°Planta NO puede ser nulo, por definición de interrelación ternaria) EMPLEADO.N°legajo puede estar en SUPERVISA.N°legajo PROYECTO.N°Proyecto debe estar en SUPERVISA.N°Proyecto PLANTA.N°Planta debe estar en SUPERVISA.N°Planta 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_11_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _9. Interrelaciones ternarias 1:M:N_ 



<!-- Start of picture text -->
N° Razón-<br>Proveedor social Descripción<br>N° Reparación<br>Provee<br>Dirección PROVEEDOR 1 M REPARACION<br>Fecha-<br>pedido<br>Teléfono-<br>contacto<br>N<br>REPUESTO<br>Cod-<br>Repuesto<br>Precio<br>Descripción<br><!-- End of picture text -->

**PROVEEDOR(N°Proveedor, Razón-Social, Dirección, Teléfono-contacto) REPARACION(N°Reparación, Descripción, Fecha-pedido)** Precio **REPUESTO(N°Repuesto, Descripción, Precio) PROVEE(N°Reparación, N°Repuesto, N°Proveedor)** 

PROVEE  CK = {(N°Reparación, N°Repuesto)} 

PROVEE.N°Reparación debe estar en REPARACION.N°Reparación PROVEE.N°Repuesto debe estar en REPUESTO.N°Repuesto PROVEE.N°Proveedor debe estar en PROVEEDOR.N°Proveedor REPARACION.N°Reparación debe estar en PROVEE.N°Reparación REPUESTO.N°Repuesto debe estar en PROVEE.N°Repuesto PROVEEDOR.N°Proveedor debe estar en PROVEE.N°Proveedor 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

_12_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 

### _10. Interrelaciones ternarias M:N:P_ 



<!-- Start of picture text -->
N° Razón-<br>Proveedor social Descripción<br>N° Reparación<br>Provee<br>Dirección PROVEEDOR M N REPARACION<br>Fecha-<br>pedido<br>Teléfono-<br>contacto<br>P<br>REPUESTO<br>Cod-<br>Repuesto<br>Precio<br>Descripción<br><!-- End of picture text -->

**PROVEEDOR(N°Proveedor, Razón-Social, Dirección, Teléfono-contacto) REPARACION(N°Reparación, Descripción, Fecha-pedido)** Precio **REPUESTO(N°Repuesto, Descripción, Precio) PROVEE(N°Reparación, N°Repuesto, N°Proveedor)** 

PROVEE  CK = {(N°Reparación, N°Repuesto, N°Proveedor)} 

PROVEE.N°Reparación debe estar en REPARACION.N°Reparación PROVEE.N°Repuesto debe estar en REPUESTO.N°Repuesto PROVEE.N°Proveedor debe estar en PROVEEDOR.N°Proveedor REPARACION.N°Reparación debe estar en PROVEE.N°Reparación REPUESTO.N°Repuesto debe estar en PROVEE.N°Repuesto PROVEEDOR.N°Proveedor debe estar en PROVEE.N°Proveedor 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 



<!-- Start of picture text -->
Oe<br><!-- End of picture text -->



<!-- Start of picture text -->
M u<br>DOCENTE e <> ( ) MATERIA<br>EVALUADO CON<br>u<br>ENCUESTA<br><!-- End of picture text -->

_14_ 

# _Transformación del Modelo Entidad Relación al Modelo Lógico Relacional_ 



<!-- Start of picture text -->
MATERIA CON  MATERIA SIN<br>Cant-<br>LABORATORI LABORATORI<br>hs-labo<br>O O<br>12. Jerarquías de Especialización /Generalización<br>d<br>MATERIA(Cod-materia, Nombre, Cant-hs-semana, modalidad) Modalidad<br>MATERIA-CON-LABORATORIO(Cod-materia, Cant-hs-labo)<br>Cod-materia<br>MATERIA<br>MATERIA-TURNO-MAÑANA(Cod-materia, Cupo-max) Cant-hs-<br>semana<br>MATERIA-TURNO-TARDE(Cod-materia, Cupo-max) Nombre<br>Turno<br>MATERIA-TURNO-NOCHE(Cod-materia, Cupo-max, Fecha-finalización) o<br>MATERIA  MATERIA  MATERIA<br>Fecha-<br>TURNO  TURNO TARDE TURNO<br>MAÑANA NOCHE finalizacion<br>Cupo-max Cupo-max<br>Cupo-max<br><!-- End of picture text -->

MATERIA-CON-LABORATORIO.Cod-materia debe estar en MATERIA.Cod-materia MATERIA-TURNO-MAÑANA.Cod-materia debe estar en MATERIA.Cod-materia MATERIA-TURNO-TARDE.Cod-materia debe estar en MATERIA.Cod-materia MATERIA-TURNO-NOCHE.Cod-materia debe estar en MATERIA.Cod-materia MATERIA.Cod-materia puede estar en MATERIA-TURNO-MAÑANA.Cod-materia, y/o MATERIA-TURNO-TARDE.Cod-materia y/o  MATERIA-TURNO-NOCHE.Cod-materia (debe estar al menos en alguna). 

**_MODELIZACIÓN_** _- BASE DE DATOS_ 

_Leticia M. Seijas_ 

