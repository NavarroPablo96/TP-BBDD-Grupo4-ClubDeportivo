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

-- Cronograma: profesional y área aptos para la actividad 201, y un dictado válido
INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo)
VALUES (30111222, 'Ana Torres', 'Calle 9 de Julio 300', '2237000001', 'Profesora de Educación Física');

INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento)
VALUES (1, 'Gimnasio planta baja', 30, 'Bueno');

INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad)
VALUES (30111222, 201);

INSERT INTO APTA_PARA (cod_area, cod_actividad)
VALUES (1, 201);

DECLARE @id_dictado INT;

EXEC SP_ALTA_DICTADO
    @cod_actividad = 201,
    @fecha_desde = '2026-03-01',
    @fecha_fin = '2026-06-30',
    @hora_inicio = '10:00',
    @hora_fin = '11:00',
    @dia_semana = 1,
    @dni = 30111222,
    @cod_dictado = @id_dictado OUTPUT;

INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area)
VALUES (@id_dictado, 1);

-- Arancel: Marta se inscribe en la arancelada 301 (cuota 1 por adelantado) y se liquidan febrero y marzo
EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @id_a, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = '2026-01-15';
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = 2026, @mes = 2;
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = 2026, @mes = 3;

-- Cuota 1 paga todo, cuota 2 pago parcial, cuota 3 sin pagar
UPDATE CUOTA_ARANCEL
SET monto_abonado = monto_a_pagar,
    fecha_pago = '2026-01-15'
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 1;

UPDATE CUOTA_ARANCEL
SET monto_abonado = 2000.00,
    fecha_pago = '2026-02-16'
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 2;

-- Resultado esperado: 8000.00 (3000 de la cuota 2 + 5000 de la cuota 3)
SELECT SUM(monto_a_pagar - ISNULL(monto_abonado, 0)) AS deuda_arancel_marta
FROM CUOTA_ARANCEL
WHERE nro_socio_base = @id_a AND cod_actividad = 301;
GO

-- Resultados esperados:
--   SP_CONSULTA_TITULARES_DEUDA 2026: Pablo Diaz 30000.00 (1 integrante); Elena Sosa 78250.00 (2 integrantes).
--   SP_CONSULTA_SOCIOS_GRATUITAS 2025: Adulto 2 (Marta, Raul); el resto 0.
EXEC SP_CONSULTA_TITULARES_DEUDA @anio = 2026;
EXEC SP_CONSULTA_SOCIOS_GRATUITAS @anio = 2025;
GO

-- Pruebas de rechazo y control. Cada bloque corre en una transacción que se revierte.
-- Usa dni 1001 y área 99, distintos de los datos de arriba, para no chocar con ellos.

-- A: profesional sin PUEDE_DESEMPENIARSE_EN para la actividad -> rechaza 50005
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo) VALUES (1001, 'Prof Test', 'Calle 1', '123', 'Lic');
    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (SCOPE_IDENTITY(), 1001);
    PRINT 'A: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'A: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- B: área no apta para la actividad -> rechaza 50006
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES (99, 'Pileta', 10, 'Bueno');
    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (SCOPE_IDENTITY(), 99);
    PRINT 'B: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'B: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- C: mismo día, horario que se pisa, área y profesional en común -> rechaza 50007
-- D (control): mismo día y área, horario contiguo -> pasa
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo) VALUES (1001, 'Prof Test', 'Calle 1', '123', 'Lic');
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES (99, 'Pileta', 10, 'Bueno');
    INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad) VALUES (1001, 201);
    INSERT INTO APTA_PARA (cod_area, cod_actividad) VALUES (99, 201);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    DECLARE @d1 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@d1, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@d1, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@d1, 99);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:30', '11:30', 201);
    DECLARE @d2 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@d2, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@d2, 1001);
    PRINT 'C: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'C: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo) VALUES (1001, 'Prof Test', 'Calle 1', '123', 'Lic');
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES (99, 'Pileta', 10, 'Bueno');
    INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad) VALUES (1001, 201);
    INSERT INTO APTA_PARA (cod_area, cod_actividad) VALUES (99, 201);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    DECLARE @e1 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@e1, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@e1, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@e1, 99);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '11:00', '12:00', 201);
    DECLARE @e2 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@e2, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@e2, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@e2, 99);
    PRINT 'D: control OK (pasó sin rechazo)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'D: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- E: cuota de arancel sobre una actividad gratuita -> rechaza 50008
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)
    VALUES ((SELECT nro_socio_base FROM SOCIO WHERE nombre = 'Marta Ruiz'), 0, 201, 1, 100.00, '2025-03-01', NULL, NULL);
    PRINT 'E: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'E: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- F: titular con integrantes -> rechaza 50009. Grupo nuevo con titular e integrante.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @f INT;
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000009', @domicilio = 'Calle Test 1', @nombre_titular = 'Titular Test', @fecha_nacimiento = '1980-01-01', @nombre_categoria = 'Adulto', @nro_socio_base = @f OUTPUT;
    INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
    VALUES (@f, 1, 'Integrante Test', '2010-01-01', NULL, NULL, 'Infantil');
    DELETE FROM SOCIO WHERE nro_socio_base = @f AND nro_orden = 0;
    PRINT 'F: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'F: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- G: titular solo, último integrante del grupo -> rechaza 50010
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @g INT;
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000010', @domicilio = 'Calle Test 2', @nombre_titular = 'Titular Solo', @fecha_nacimiento = '1980-01-01', @nombre_categoria = 'Adulto', @nro_socio_base = @g OUTPUT;
    DELETE FROM SOCIO WHERE nro_socio_base = @g AND nro_orden = 0;
    PRINT 'G: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'G: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO
