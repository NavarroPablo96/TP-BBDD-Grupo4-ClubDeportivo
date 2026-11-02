USE ClubDeportivo;
GO

-- Datos de prueba para los triggers, SP y vistas de 03_logica_socios_cuotas.sql.
-- Se ejecuta después de 02 (base recién creada por 00). Usa nro_socio_base generados por SP_ALTA_GRUPO_FAMILIAR.
-- Los grupos de 02 no tienen titular con nro_orden = 0 y por eso no aparecen en VW_TITULARES_DEUDA_ANIO_ACTUAL.

DECLARE @id_a INT;
DECLARE @id_b INT;
DECLARE @id_c INT;

-- Actividades: 201 y 202 gratuitas, 301 arancelada (tipo coherente con la subentidad)
INSERT INTO ACTIVIDAD (cod_actividad, nombre, tipo)
VALUES (201, 'Caminata', 'G'),
       (202, 'Yoga comunitario', 'G'),
       (301, 'Natación', 'A');

INSERT INTO ACTIVIDAD_GRATUITA (cod_actividad)
VALUES (201), (202);

INSERT INTO ACTIVIDAD_ARANCELADA (cod_actividad, arancel, meses_por_cuota)
VALUES (301, 5000.00, 1);

INSERT INTO HABILITADA_PARA (cod_actividad, nombre_categoria)
VALUES (201, 'Infantil'),
       (201, 'Juvenil'),
       (201, 'Adulto'),
       (201, 'Jubilado'),
       (202, 'Adulto'),
       (202, 'Jubilado'),
       (301, 'Adulto'),
       (301, 'Juvenil');

-- Grupo A: titular Adulto con un integrante Infantil
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000001',
    @domicilio = 'Calle Mitre 400',
    @nombre_titular = 'Marta Ruiz',
    @fecha_nacimiento = '1980-03-10',
    @nombre_categoria = 'Adulto',
    @nro_socio_base = @id_a OUTPUT;

INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
VALUES (@id_a, 1, 'Tomas Ruiz', '2014-07-22', NULL, '2236000011', 'Infantil');

-- Grupo B: titular Adulto sin integrantes
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000002',
    @domicilio = 'Calle Moreno 120',
    @nombre_titular = 'Pablo Diaz',
    @fecha_nacimiento = '1982-05-05',
    @nombre_categoria = 'Adulto',
    @nro_socio_base = @id_b OUTPUT;

-- Grupo C: titular Jubilado con un integrante Adulto
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000003',
    @domicilio = 'Av. Luro 800',
    @nombre_titular = 'Elena Sosa',
    @fecha_nacimiento = '1952-09-14',
    @nombre_categoria = 'Jubilado',
    @nro_socio_base = @id_c OUTPUT;

INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
VALUES (@id_c, 1, 'Raul Sosa', '1978-01-30', NULL, '2236000033', 'Adulto');

-- Cuotas sociales de enero a marzo 2026 para todos los grupos (incluye los de 02)
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = 2026, @mes = 1;
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = 2026, @mes = 2;
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = 2026, @mes = 3;

-- Grupo A: paga todo (sin deuda)
UPDATE CUOTA_SOCIAL
SET monto_abonado = monto_a_pagar,
    fecha_pago = '2026-01-10'
WHERE nro_socio_base = @id_a
  AND anio = 2026;

-- Grupo B: paga sólo enero (deuda de febrero y marzo)
UPDATE CUOTA_SOCIAL
SET monto_abonado = monto_a_pagar,
    fecha_pago = '2026-01-12'
WHERE nro_socio_base = @id_b
  AND anio = 2026
  AND mes = 1;

-- Grupo C: pago parcial de enero, sin pagos el resto del año
UPDATE CUOTA_SOCIAL
SET monto_abonado = 5000.00,
    fecha_pago = '2026-01-15'
WHERE nro_socio_base = @id_c
  AND anio = 2026
  AND mes = 1;

-- Inscripciones del año anterior (2025): Marta en las dos gratuitas, Raul en las dos, Tomas y Pablo sólo en una
INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
VALUES (@id_a, 0, 201, '2025-03-01'),
       (@id_a, 0, 202, '2025-03-02'),
       (@id_a, 1, 201, '2025-03-01'),
       (@id_b, 0, 201, '2025-04-10'),
       (@id_c, 1, 201, '2025-05-05'),
       (@id_c, 1, 202, '2025-05-05');

-- Inscripción de 2026 de Pablo: no cuenta para la consulta del año anterior
INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
VALUES (@id_b, 0, 202, '2026-02-01');
GO

-- Resultados esperados:
--   SP_CONSULTA_TITULARES_DEUDA 2026: Pablo Diaz 30000.00 (1 integrante); Elena Sosa 78250.00 (2 integrantes).
--   SP_CONSULTA_SOCIOS_GRATUITAS 2025: Adulto 2 (Marta, Raul); el resto 0.
EXEC SP_CONSULTA_TITULARES_DEUDA @anio = 2026;
EXEC SP_CONSULTA_SOCIOS_GRATUITAS @anio = 2025;
GO
