USE ClubDeportivo;
GO


DELETE FROM SOCIO;
DELETE FROM CATEGORIA;
DELETE FROM VALOR_CUOTA_SOCIAL;
DELETE FROM CUOTA_SOCIAL;
DELETE FROM GRUPO_FAMILIAR;
GO

DBCC CHECKIDENT ('GRUPO_FAMILIAR', RESEED, 0);
GO


INSERT INTO CATEGORIA (nombre_categoria, porcentaje_mod_couta)
VALUES
    ('Infantil', -30.00),
    ('Juvenil', -15.00),
    ('Adulto', 0.00),
    ('Jubilado', -15.00);
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
    (1, 1, 'Juan Perez', '1985-04-12', 'juan.perez@email.com', '2235000001', 'Adulto'),
    (1, 2, 'Maria Lopez', '1987-09-23', 'maria.lopez@email.com', '2235000002', 'Adulto'),
    (1, 3, 'Lucas Perez', '2012-06-15', NULL, '2235000003', 'Infantil'),

    (2, 1, 'Carlos Gomez', '1975-02-18', 'carlos.gomez@email.com', '2235000004', 'Adulto'),
    (2, 2, 'Ana Gomez', '1978-11-30', 'ana.gomez@email.com', '2235000005', 'Adulto'),
    
    (3, 1, 'Sofia Rodriguez', '2008-08-07', 'sofia.rodriguez@email.com', '2235000006', 'Juvenil'),
    
    (4, 1, 'Roberto Fernandez', '1955-01-25', 'roberto.fernandez@email.com', '2235000007', 'Jubilado'),
    
    (5, 1, 'Laura Martinez', '1990-12-03', 'laura.martinez@email.com', '2235000008', 'Adulto');
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