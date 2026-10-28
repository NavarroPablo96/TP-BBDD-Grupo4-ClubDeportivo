USE ClubDeportivo;
GO

-- Eliminar las tablas si ya existen
DROP TABLE IF EXISTS SOCIO;
DROP TABLE IF EXISTS CATEGORIA;
DROP TABLE IF EXISTS VALOR_CUOTA_SOCIAL;
DROP TABLE IF EXISTS CUOTA_SOCIAL;
DROP TABLE IF EXISTS GRUPO_FAMILIAR;
DROP TABLE IF EXISTS ACTIVIDAD;
DROP TABLE IF EXISTS ACTIVIDAD_ARANCELADA;
DROP TABLE IF EXISTS ACTIVIDAD_GRATUITA;
DROP TABLE IF EXISTS HABILITADA_PARA;
DROP TABLE IF EXISTS INSCRIPCION;
GO


-- CATEGORIA (nombre_categoria, porcentaje_mod_cuota) 
-- PK = CK = {nombre_categoria}
CREATE TABLE CATEGORIA(
    nombre_categoria VARCHAR(30),
    porcentaje_mod_couta DECIMAL(5,2),

    -- Clave Primaria
    CONSTRAINT PK_CATEGORIA PRIMARY KEY(nombre_categoria)
    
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
        REFERENCES CATEGORIA(nombre_categoria)

);
GO

--VALOR_CUOTA_SOCIAL (fecha_desde, fecha_hasta, monto_base) PK = CK = {fecha_desde}
CREATE TABLE VALOR_CUOTA_SOCIAL(
    fecha_desde DATE NOT NULL,
    fecha_hasta DATE,
    monto_base DECIMAL(15,2) NOT NULL,

    --Clave Primaria
    CONSTRAINT PK_VALOR_CUOTA_SOCIAL PRIMARY KEY(fecha_desde)
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
        )

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
    -- TODO: garantizar la jerarquía total, exclusiva y coherente con tipo.
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

    -- Verificación de meses por cuota
    -- TODO: acordar que periodicidadades se admiten.
    CONSTRAINT CK_ACTIVIDAD_ARANCELADA_MESES_POR_CUOTA
        CHECK (meses_por_cuota > 0),
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
        REFERENCES ACTIVIDAD(cod_actividad),
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
        REFERENCES CATEGORIA(nombre_categoria),
);
GO

-- INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
-- PK = CK = {(nro_socio_base, nro_orden, cod_actividad)} FK = {(nro_socio_base, nro_orden), cod_actividad}
CREATE TABLE INSCRIPCION(
    nro_socio_base INT NOT NULL,
    nro_orden INT NOT NULL,
    cod_actividad INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,

    CONSTRAINT PK_INSCRIPCION
        PRIMARY KEY (nro_socio_base, nro_orden, cod_actividad),

    CONSTRAINT FK_INSCRIPCION_SOCIO
        FOREIGN KEY (nro_socio_base, nro_orden)
        REFERENCES SOCIO(nro_socio_base, nro_orden),
    
    CONSTRAINT FK_INSCRIPCION_ACTIVIDAD
        FOREIGN KEY (cod_actividad)
        REFERENCES ACTIVIDAD(cod_actividad)
);
GO