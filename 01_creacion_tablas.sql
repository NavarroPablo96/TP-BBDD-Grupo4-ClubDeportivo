USE ClubDeportivo;
GO

-- Eliminar las tablas si ya existen
DROP TABLE IF EXISTS SOCIO;
DROP TABLE IF EXISTS CATEGORIA;
DROP TABLE IF EXISTS VALOR_CUOTA_SOCIAL;
DROP TABLE IF EXISTS CUOTA_SOCIAL;
DROP TABLE IF EXISTS GRUPO_FAMILIAR;
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