# Guía para entender el proyecto

## Objetivo

* Entender como está dividido el proyecto
  * Entender la consigna que le toca a cada uno. Y ademas la consigna que no es asignada a nadie porque es global.
  * Entender la solución que hicimos
    * DER, las entidades son sus atributos
    * MR, restricciones del MR sobre participación.
    * Entender las restricciones adicionales y las hipotesis que corresponden.
  * Entender cómo todo eso se define en el código
    * en el archivo 01 se crean las tablas, ahí están algunas restricciones
    * ¿Donde estan programadas las restricciones de participación total?
    * Entender que triggers, stores procedures y vistas corresponden.
      * (Opcional o tal vez no) Entender la sintaxis asociada a los create table, triggers, stores procedures y vistas.
  * Creo que nada mas.

# División tablas:

Integrante 1 (CATEGORIA, GRUPO_FAMILIAR, SOCIO)
Integrante 2 (VALOR_CUOTA_SOCIAL, CUOTA_SOCIAL)
Integrante 3 (ACTIVIDAD, ACTIVIDAD_ARANCELADA, ACTIVIDAD_GRATUITA, HABILITADA_PARA)
Integrante 4 (INSCRIPCION, CUOTA_ARANCEL)
Integrante 5 (PROFESIONAL, PUEDE_DESEMPENIARSE_EN, DICTADO, DICTADO_DIA, A_CARGO_DE, SE_DESARROLLA_EN)
Integrante 6 (AREA, ESTADO_AREA, HISTORIAL_AREA_ESTADO, APTA_PARA)

# [CONSIGNA DIVISION](CONSIGNA/CONSIGNA%20DIVISION.md)

# [HIPOTESIS division](HIPOTESIS/HIPOTESIS%20division.md)

# [DER completo](DER/DER%20completo.md)

* INFORME vs CODIGO, Leer antes las hipotesis,
* Cambiar informe en caso de que no coincida con codigo.

# [MR division](MR/MR%20division.md)

* INFORME vs CODIGO
* Cambiar informe en caso de que no coincida con código.
  * Buscar en el codigo donde se implementan las restricciones de participación total y parcial.

# [CODIGO](Codigo/CODIGO.md)

## 1. Entender el modelo de datos

**Por dónde empezar:** por las tablas y sus relaciones.
Necesitamos entender:

* Qué tablas existen.
* Qué información almacena cada tabla.
* Cómo se relacionan entre sí.
* Cuáles son las claves primarias y foráneas.

**Archivo para comenzar:**

* [01_creacion_tablas_sql](Codigo\Archivo%2001\01_creacion_tablas_sql.md)

## 2. Conocer la estructura del repositorio

El repositorio tiene cuatro partes principales:

|Carpeta / Archivo|Contenido|
|-----------------|---------|
|`scripts/`|Archivos SQL. Implementación de la base de datos.|
|`docs/`|Documentación y pendientes de diseño.|
|`app-host/`|Aplicación que interactúa con la base de datos.|
|`README.md`|Explicación general e instrucciones del proyecto.|

### Secuencia de archivos SQL

|Archivo|Función|
|-------|-------|
|[00_creacion_bd_sql](Codigo\00_creacion_bd_sql.md)|Crea la base de datos.|
|[01_creacion_tablas_sql](Codigo\Archivo%2001\01_creacion_tablas_sql.md)|Crea las tablas y sus relaciones.|
|[02_insercion_datos_sql](Codigo\Archivo%2002\02_insercion_datos_sql.md)|Carga los datos de prueba.|
|[03_logica_socios_cuotas_sql](Codigo\Archivo%2003\03_logica_socios_cuotas_sql.md)|Implementa lógica relacionada con socios y cuotas.|
|[04_logica_areas_profesionales_sql](Codigo\Archivo%2004\04_logica_areas_profesionales_sql.md)|Implementa lógica de áreas y profesionales.|
|[05_datos_logica_socios_cuota_sql](Codigo\05_datos_logica_socios_cuota_sql.md)|Datos y lógica adicional.|

## 3. ==Entender las operaciones principales==

Una vez comprendidas las tablas, estudiar cómo funciona el sistema.

Operaciones importantes:

* Inscripción de socios a actividades.
* Registro de pagos de actividades.
* Liquidación de cuotas sociales.
* Cálculo y control de deudas.

**Objetivo:** entender qué sucede en la base de datos cuando se realiza cada operación.

## 4. Entender las consultas y reglas de negocio

Identificar dónde están implementadas las reglas del sistema.

Elementos a estudiar:

* Stored Procedures.
* Triggers.
* Vistas.
* Consultas SQL.

También debemos identificar las consultas específicas solicitadas por la cátedra.

**Objetivo:** comprender qué resuelve cada elemento y por qué se implementó de esa manera.

## 5. Entender la aplicación

Por último, estudiar la aplicación que se conecta a la base de datos.

Necesitamos entender:

* Cómo se conecta con SQL Server.
* Cómo ejecuta operaciones sobre la base.
* Cómo interactúa con los procedimientos almacenados.
* Cómo utiliza las transacciones.

**Objetivo:** entender cómo la aplicación utiliza la base de datos y qué operación permite realizar.

## Orden recomendado de lectura

1. `01_creacion_tablas.sql` → entender las tablas.
1. DER → reconocer las relaciones y actualizarlo.
1. `02_insercion_datos.sql` → conocer los datos de prueba.
1. Scripts de lógica → entender las operaciones.
1. Aplicación (`app-host/`) → entender la conexión y las transacciones.

**Importante:** avanzar por etapas. No pasar a la siguiente hasta tener una comprensión general de la anterior.

|Etapa|Archivo / tema|Estado|
|-----|--------------|------|
|1|Estructura del repositorio|Listo|
|2|`01_creacion_tablas.sql`|Revisión general|
|3|Comparación MR vs. SQL|Inicial|
|4|`02_insercion_datos.sql`|Siguiente|
|5|Lógica de socios y cuotas|Pendiente|
|6|Lógica de áreas y profesionales|Pendiente|
|7|Aplicación y transacciones|Pendiente|
