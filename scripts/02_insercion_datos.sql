USE ClubDeportivo;
GO


-- Orden inverso de dependencias. Incluye las tablas que cargan 03 y 04.
DELETE FROM CUOTA_ARANCEL;
DELETE FROM A_CARGO_DE;
DELETE FROM SE_DESARROLLA_EN;
DELETE FROM DICTADO_DIA;
DELETE FROM DICTADO;
DELETE FROM APTA_PARA;
DELETE FROM PUEDE_DESEMPENIARSE_EN;
DELETE FROM INSCRIPCION;
DELETE FROM HABILITADA_PARA;
DELETE FROM ACTIVIDAD_GRATUITA;
DELETE FROM ACTIVIDAD_ARANCELADA;
DELETE FROM ACTIVIDAD;
DELETE FROM CUOTA_SOCIAL;
-- Borra SOCIO por ON DELETE CASCADE de GRUPO_FAMILIAR
DELETE FROM GRUPO_FAMILIAR;
DELETE FROM VALOR_CUOTA_SOCIAL;
DELETE FROM CATEGORIA;
DELETE FROM AREA;
DELETE FROM PROFESIONAL;
GO

-- Sin DBCC CHECKIDENT: con RESEED 0 la primera fila queda con nro_socio_base = 0
-- y los SOCIO (que referencian 1..5) fallan la FK. Se asume base recreada por 00.
GO


INSERT INTO CATEGORIA (nombre_categoria, porcentaje_mod_cuota)
VALUES
    ('infantiles', -30.00),
    ('mayores', 0.00),
    ('vitalicios', -15.00);
GO

USE ClubDeportivo;
GO
INSERT INTO GRUPO_FAMILIAR (telefono, domicilio)
VALUES
    ('2234567890', 'Av. Independencia 1250'),
    ('2234567891', 'Calle San Martin 845'),
    ('2234567892', 'Av. Colon 2300'),
    ('2234567893', 'Calle Rivadavia 1570'),
    ('2234567894', 'Calle Belgrano 920');
GO


USE ClubDeportivo;
GO
INSERT INTO SOCIO (nro_socio_base,nro_orden,nombre,fecha_nacimiento,correo_electronico,celular,nombre_categoria)
VALUES
    (1, 0, 'Juan Perez', '1985-04-12', 'juan.perez@email.com', '2235000001', 'mayores'),
    (1, 1, 'Maria Lopez', '1987-09-23', 'maria.lopez@email.com', '2235000002', 'mayores'),
    (1, 2, 'Lucas Perez', '2012-06-15', NULL, '2235000003', 'infantiles'),

    (2, 0, 'Carlos Gomez', '1975-02-18', 'carlos.gomez@email.com', '2235000004', 'mayores'),
    (2, 1, 'Ana Gomez', '1978-11-30', 'ana.gomez@email.com', '2235000005', 'mayores'),

    (3, 0, 'Sofia Rodriguez', '2008-08-07', 'sofia.rodriguez@email.com', '2235000006', 'mayores'),

    (4, 0, 'Roberto Fernandez', '1955-01-25', 'roberto.fernandez@email.com', '2235000007', 'vitalicios'),

    (5, 0, 'Laura Martinez', '1990-12-03', 'laura.martinez@email.com', '2235000008', 'mayores');
GO

USE ClubDeportivo;
GO
INSERT INTO VALOR_CUOTA_SOCIAL (fecha_desde,fecha_hasta,monto_base)
VALUES
    ('2025-01-01', '2025-06-30', 10000.00),
    ('2025-07-01', '2025-12-31', 12000.00),
    ('2026-01-01', '2026-06-30', 15000.00),
    ('2026-07-01', NULL,         18000.00);
GO