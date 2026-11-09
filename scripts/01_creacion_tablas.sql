USE ClubDeportivo;
GO

-- Eliminar las tablas si ya existen
DROP TABLE IF EXISTS CUOTA_ARANCEL;
DROP TABLE IF EXISTS SE_DESARROLLA_EN;
DROP TABLE IF EXISTS A_CARGO_DE;
DROP TABLE IF EXISTS DICTADO_DIA;
DROP TABLE IF EXISTS DICTADO;
DROP TABLE IF EXISTS APTA_PARA;
DROP TABLE IF EXISTS PUEDE_DESEMPENIARSE_EN;
DROP TABLE IF EXISTS AREA;
DROP TABLE IF EXISTS PROFESIONAL;
DROP TABLE IF EXISTS INSCRIPCION;
DROP TABLE IF EXISTS HABILITADA_PARA;
DROP TABLE IF EXISTS ACTIVIDAD_GRATUITA;
DROP TABLE IF EXISTS ACTIVIDAD_ARANCELADA;
DROP TABLE IF EXISTS ACTIVIDAD;
DROP TABLE IF EXISTS CUOTA_SOCIAL;
DROP TABLE IF EXISTS SOCIO;
DROP TABLE IF EXISTS GRUPO_FAMILIAR;
DROP TABLE IF EXISTS VALOR_CUOTA_SOCIAL;
DROP TABLE IF EXISTS CATEGORIA;
GO


-- CATEGORIA (nombre_categoria, porcentaje_mod_cuota) 
-- PK = CK = {nombre_categoria}
CREATE TABLE CATEGORIA(
    nombre_categoria VARCHAR(30),
    porcentaje_mod_cuota DECIMAL(5,2),

    -- Clave Primaria
    CONSTRAINT PK_CATEGORIA PRIMARY KEY(nombre_categoria),

    -- §4.2: las categorías son únicamente infantiles, mayores y vitalicios
    CONSTRAINT CK_CATEGORIA_NOMBRE
        CHECK (nombre_categoria IN ('infantiles', 'mayores', 'vitalicios'))

);
GO

-- GRUPO_FAMILIAR (nro_socio_base, domicilio, telefono) 
-- PK = CK = {nro_socio_base}
CREATE TABLE GRUPO_FAMILIAR (
    nro_socio_base INT IDENTITY(1,1),
    telefono VARCHAR(20) NOT NULL,
    domicilio VARCHAR(100) NOT NULL,
    
    -- Clave Primaria
    CONSTRAINT PK_GRUPO_FAMILIAR PRIMARY KEY (nro_socio_base)
);
GO

--SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
-- PK = CK = (nro_socio_base, nro_orden)
-- FK = {nro_socio_base, nombre_categoria}
CREATE TABLE SOCIO(
    nro_socio_base INT NOT NULL,
    nro_orden INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    correo_electronico VARCHAR(50),
    celular VARCHAR(20),
    nombre_categoria VARCHAR(30) NOT NULL,

    --Clave Primaria Compuesta (Entidad Debil)
    CONSTRAINT PK_SOCIO PRIMARY KEY (nro_socio_base, nro_orden),

    --Claves Foráneas
    CONSTRAINT FK_SOCIO_GRUPO_FAMILIAR FOREIGN KEY(nro_socio_base)
        REFERENCES GRUPO_FAMILIAR(nro_socio_base)
        ON DELETE CASCADE,

    CONSTRAINT FK_SOCIO_CATEGORIA FOREIGN KEY(nombre_categoria)
        REFERENCES CATEGORIA(nombre_categoria),

    -- H1 y §4.2: el titular tiene nro_orden = 0, los integrantes numeran desde 1
    CONSTRAINT CK_SOCIO_NRO_ORDEN CHECK (nro_orden >= 0)

);
GO

--VALOR_CUOTA_SOCIAL (fecha_desde, fecha_hasta, monto_base) PK = CK = {fecha_desde}
CREATE TABLE VALOR_CUOTA_SOCIAL(
    fecha_desde DATE NOT NULL,
    fecha_hasta DATE,
    monto_base DECIMAL(15,2) NOT NULL,

    --Clave Primaria
    CONSTRAINT PK_VALOR_CUOTA_SOCIAL PRIMARY KEY(fecha_desde),

    -- Validación de vigencia: fecha_hasta, si existe, no puede ser anterior a fecha_desde
    CONSTRAINT CK_VALOR_CUOTA_SOCIAL_FECHAS
        CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
);
GO

--CUOTA_SOCIAL (nro_socio_base, anio, mes, monto_a_pagar, monto_abonado, fecha_vencimiento, fecha_pago)
-- PK = CK = {(nro socio _base, anio, mes)} 
-- FK = {nro_socio_base}
CREATE TABLE CUOTA_SOCIAL(
    nro_socio_base INT NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,

    monto_a_pagar DECIMAL(15,2) NOT NULL,
    monto_abonado DECIMAL(15,2) NULL,
    fecha_vencimiento DATE NOT NULL,
    fecha_pago DATE,

    --Clae Primaria
    CONSTRAINT PK_CUOTA_SOCIAL PRIMARY KEY(nro_socio_base, anio,mes),

    --Claves Foráneas
    CONSTRAINT FK_CUOTA_GRUPO_FAMILIAR FOREIGN KEY(nro_socio_base)
        REFERENCES GRUPO_FAMILIAR(nro_socio_base),

    -- Validación mes y importes no negativos:
    CONSTRAINT CK_CUOTA_MES
        CHECK (mes BETWEEN 1 AND 12),

    CONSTRAINT CK_CUOTA_IMPORTES
        CHECK (
            monto_a_pagar >= 0
            AND monto_abonado >= 0
        ),

    -- §4.2: el monto abonado no supera el monto a pagar (NULL = cuota sin pagos)
    CONSTRAINT CK_CUOTA_SOCIAL_ABONADO
        CHECK (monto_abonado IS NULL OR monto_abonado <= monto_a_pagar)

);
GO

--ACTIVIDAD (cod_actividad, nombre, tipo)
-- PK = CK = {cod_actividad}
CREATE TABLE ACTIVIDAD(
    cod_actividad INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    tipo CHAR(1) NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_ACTIVIDAD PRIMARY KEY (cod_actividad),

    -- Validación tipo de actividad
    -- La jerarquía (coherencia, exclusividad, totalidad) se garantiza en 03: TR_ACTIVIDAD_*_TIPO y SP_ALTA_ACTIVIDAD_*.
    CONSTRAINT CK_ACTIVIDAD_tipo CHECK (tipo in ('A', 'G'))

);
GO

--ACTIVIDAD_ARANCELADA (cod_actividad, arancel, meses_por_cuota) 
-- PK = CK = FK = {cod_actividad}
CREATE TABLE ACTIVIDAD_ARANCELADA(
    cod_actividad INT NOT NULL,
    arancel DECIMAL(15, 2) NOT NULL,
    meses_por_cuota INT NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_ACTIVIDAD_ARANCELADA
        PRIMARY KEY (cod_actividad),

    -- Clave foránea
    CONSTRAINT FK_ACTIVIDAD_ARANCELADA
        FOREIGN KEY (cod_actividad) 
        REFERENCES ACTIVIDAD(cod_actividad),

    -- Verificación de arancel
    CONSTRAINT CK_ACTIVIDAD_ARANCELADA_ARANCEL
        CHECK (arancel >= 0),

    -- Verificación de meses por cuota (periodicidades admitidas: decisión del usuario, ver pendientes_diseno.md TODO 1)
    CONSTRAINT CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA
        CHECK (meses_por_cuota IN (1, 2, 3, 6, 12))
);
GO

-- ACTIVIDAD_GRATUITA (cod_actividad)
-- PK = CK = FK = {cod_actividad}
CREATE TABLE ACTIVIDAD_GRATUITA(
    cod_actividad INT NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_ACTIVIDAD_GRATUITA
        PRIMARY KEY (cod_actividad),

    -- Clave foránea
    CONSTRAINT FK_ACTIVIDAD_GRATUITA
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad)
);
GO

-- HABILITADA_PARA (cod_actividad, nombre_categoria)
-- PK = CK = {(cod_actividad, nombre_categoria)} FK = {cod_actividad, nombre_categoria}
CREATE TABLE HABILITADA_PARA(
    cod_actividad INT NOT NULL,
    nombre_categoria VARCHAR(30) NOT NULL,

    CONSTRAINT PK_HABILITADA_PARA
        PRIMARY KEY (cod_actividad, nombre_categoria),

    CONSTRAINT FK_HABILITADA_PARA_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad),

    CONSTRAINT FK_HABILITADA_PARA_CATEGORIA
        FOREIGN KEY (nombre_categoria)
        REFERENCES CATEGORIA(nombre_categoria)
);
GO

-- INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, estado, fecha_baja)
-- PK = CK = {(nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)} FK = {(nro_socio_base, nro_orden), cod_actividad}
-- La PK incluye fecha_inscripcion para permitir reinscribirse tras una baja (H6, H12; pendientes_diseno.md TODO 5).
-- Que haya a lo sumo una inscripción 'Activa' por socio y actividad lo garantiza TR_INSCRIPCION_VIGENTE_UNICA en 03.
CREATE TABLE INSCRIPCION(
    nro_socio_base INT NOT NULL,
    nro_orden INT NOT NULL,
    cod_actividad INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(10) NOT NULL
        CONSTRAINT DF_INSCRIPCION_ESTADO DEFAULT 'Activa',
    fecha_baja DATE NULL,

    CONSTRAINT PK_INSCRIPCION
        PRIMARY KEY (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion),

    CONSTRAINT FK_INSCRIPCION_SOCIO
        FOREIGN KEY (nro_socio_base, nro_orden)
        REFERENCES SOCIO(nro_socio_base, nro_orden),

    CONSTRAINT FK_INSCRIPCION_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad),

    -- H12: una inscripción está activa o dada de baja
    CONSTRAINT CK_INSCRIPCION_ESTADO
        CHECK (estado IN ('Activa', 'Baja')),

    -- Activa: sin fecha de baja. Baja: con fecha de baja no anterior a la inscripción.
    CONSTRAINT CK_INSCRIPCION_FECHA_BAJA
        CHECK ((estado = 'Activa' AND fecha_baja IS NULL)
            OR (estado = 'Baja' AND fecha_baja IS NOT NULL AND fecha_baja >= fecha_inscripcion))
);
GO

-- PROFESIONAL (dni, nombre, domicilio, telefono, titulo)
-- PK = CK = {dni}
CREATE TABLE PROFESIONAL(
    dni INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    domicilio VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    titulo VARCHAR(50) NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_PROFESIONAL PRIMARY KEY (dni),

    -- Validación DNI: numérico positivo (la unicidad la da la PK)
    CONSTRAINT CK_PROFESIONAL_DNI CHECK (dni > 0)
);
GO

-- AREA (cod_area, ubicacion, capacidad, estado_mantenimiento)
-- PK = CK = {cod_area}
CREATE TABLE AREA(
    cod_area VARCHAR(20) NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    capacidad INT NOT NULL,
    -- TODO: definir dominio de estado_mantenimiento (no especificado en el enunciado).
    estado_mantenimiento VARCHAR(30) NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_AREA PRIMARY KEY (cod_area),

    -- Código de área no vacío y sin espacios al inicio ni al final (la unicidad la da la PK)
    CONSTRAINT CK_AREA_COD_AREA
        CHECK (LEN(LTRIM(RTRIM(cod_area))) > 0
               AND DATALENGTH(cod_area) = DATALENGTH(LTRIM(RTRIM(cod_area)))),

    -- Validación capacidad (supuesto: no negativa)
    CONSTRAINT CK_AREA_CAPACIDAD CHECK (capacidad >= 0)
);
GO

-- PUEDE_DESEMPENIARSE_EN (dni, cod_actividad)
-- PK = CK = {(dni, cod_actividad)} FK = {dni, cod_actividad}
CREATE TABLE PUEDE_DESEMPENIARSE_EN(
    dni INT NOT NULL,
    cod_actividad INT NOT NULL,

    CONSTRAINT PK_PUEDE_DESEMPENIARSE_EN
        PRIMARY KEY (dni, cod_actividad),

    CONSTRAINT FK_PUEDE_DESEMPENIARSE_EN_PROFESIONAL
        FOREIGN KEY (dni)
        REFERENCES PROFESIONAL(dni),

    CONSTRAINT FK_PUEDE_DESEMPENIARSE_EN_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad)
);
GO

-- APTA_PARA (cod_area, cod_actividad)
-- PK = CK = {(cod_area, cod_actividad)} FK = {cod_area, cod_actividad}
CREATE TABLE APTA_PARA(
    cod_area VARCHAR(20) NOT NULL,
    cod_actividad INT NOT NULL,

    CONSTRAINT PK_APTA_PARA
        PRIMARY KEY (cod_area, cod_actividad),

    CONSTRAINT FK_APTA_PARA_AREA
        FOREIGN KEY (cod_area)
        REFERENCES AREA(cod_area),

    CONSTRAINT FK_APTA_PARA_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad)
);
GO

-- DICTADO (cod_dictado, fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad)
-- PK = CK = {cod_dictado} FK = {cod_actividad}
CREATE TABLE DICTADO(
    cod_dictado INT IDENTITY(1,1) NOT NULL,
    fecha_desde DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cod_actividad INT NOT NULL,

    CONSTRAINT PK_DICTADO
        PRIMARY KEY (cod_dictado),

    CONSTRAINT FK_DICTADO_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad),

    -- §4.2: fecha_desde <= fecha_fin y hora_inicio < hora_fin
    CONSTRAINT CK_DICTADO_FECHAS
        CHECK (fecha_desde <= fecha_fin),

    CONSTRAINT CK_DICTADO_HORARIO
        CHECK (hora_inicio < hora_fin)
);
GO

-- DICTADO_DIA (cod_dictado, dia_semana)
-- PK = CK = {(cod_dictado, dia_semana)} FK = {cod_dictado}
CREATE TABLE DICTADO_DIA(
    cod_dictado INT NOT NULL,
    dia_semana INT NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_DICTADO_DIA
        PRIMARY KEY (cod_dictado, dia_semana),

    -- Clave foránea
    CONSTRAINT FK_DICTADO_DIA_DICTADO
        FOREIGN KEY (cod_dictado)
        REFERENCES DICTADO(cod_dictado),

    -- Validación del día de la semana
    CONSTRAINT CK_DICTADO_DIA_SEMANA
        CHECK (dia_semana BETWEEN 1 AND 7)
);
GO


-- A_CARGO_DE (cod_dictado, dni)
-- PK = CK = {(cod_dictado,dni)} FK = {cod_dictado,dni}.
CREATE TABLE A_CARGO_DE(
    cod_dictado INT NOT NULL,
    dni INT NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_A_CARGO_DE
        PRIMARY KEY (cod_dictado,dni),

    -- Clave foránea
    CONSTRAINT FK_A_CARGO_DE_DICTADO
        FOREIGN KEY (cod_dictado)
        REFERENCES DICTADO(cod_dictado),

    -- Clave foránea
    CONSTRAINT FK_A_CARGO_DE_PROFESIONAL
        FOREIGN KEY (dni)
        REFERENCES PROFESIONAL(dni)
);
GO


-- SE_DESARROLLA_EN (cod_dictado, cod_area)
-- PK = CK = {(cod_dictado,cod_area)} FK = {cod_dictado,cod_area}.
CREATE TABLE SE_DESARROLLA_EN(
    cod_dictado INT NOT NULL,
    cod_area VARCHAR(20) NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_SE_DESARROLLA_EN
        PRIMARY KEY (cod_dictado,cod_area),

    -- Clave foránea
    CONSTRAINT FK_SE_DESARROLLA_EN_DICTADO
        FOREIGN KEY (cod_dictado)
        REFERENCES DICTADO(cod_dictado),

    -- Clave foránea
    CONSTRAINT FK_SE_DESARROLLA_EN_AREA
        FOREIGN KEY (cod_area)
        REFERENCES AREA(cod_area)
);
GO

-- CUOTA ARANCEL esto es la agregación de SE_INSCRIBE
-- CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)
-- PK = CK = {(nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota)}
-- FK = {(nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)}
CREATE TABLE CUOTA_ARANCEL(
    nro_socio_base INT NOT NULL,
    nro_orden INT NOT NULL,
    cod_actividad INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    nro_cuota INT NOT NULL,

    monto_a_pagar DECIMAL(15,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    monto_abonado DECIMAL(15,2),
    fecha_pago DATE,

    -- Clave primaria compuesta
    CONSTRAINT PK_CUOTA_ARANCEL
        PRIMARY KEY (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota),

    -- Clave foránea hacia la agregación INSCRIPCION
    CONSTRAINT FK_CUOTA_ARANCEL_INSCRIPCION
        FOREIGN KEY (nro_socio_base,nro_orden,cod_actividad,fecha_inscripcion)
        REFERENCES INSCRIPCION(nro_socio_base,nro_orden,cod_actividad,fecha_inscripcion),

    -- Validación del número de cuota
    CONSTRAINT CK_CUOTA_ARANCEL_NRO_CUOTA
        CHECK (nro_cuota > 0),

    -- Validación de importes
    CONSTRAINT CK_CUOTA_ARANCEL_IMPORTES
        CHECK ( monto_a_pagar >= 0 AND (monto_abonado IS NULL OR monto_abonado >= 0)),

    -- El monto abonado no puede superar el monto a pagar
    CONSTRAINT CK_CUOTA_ARANCEL_ABONADO
        CHECK (monto_abonado IS NULL OR monto_abonado <= monto_a_pagar)
);
GO
