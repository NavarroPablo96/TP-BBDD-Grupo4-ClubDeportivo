USE ClubDeportivo;
GO

-- Datos de prueba para los triggers, SP y vistas de 03_logica_socios_cuotas.sql y 04_logica_areas_profesionales.sql.
-- Se ejecuta después de 04 (base recién creada por 00). Usa nro_socio_base generados por SP_ALTA_GRUPO_FAMILIAR.
-- Los titulares de los grupos de 02 tienen nro_orden = 0, así que también aparecen en SP_CONSULTA_TITULARES_DEUDA.

DECLARE @id_a INT;
DECLARE @id_b INT;
DECLARE @id_c INT;

-- Actividades: 201 y 202 gratuitas, 301 arancelada. Se crean con los SP que garantizan la jerarquía.
EXEC SP_ALTA_ACTIVIDAD_GRATUITA @cod_actividad = 201, @nombre = 'Caminata';
EXEC SP_ALTA_ACTIVIDAD_GRATUITA @cod_actividad = 202, @nombre = 'Yoga comunitario';
EXEC SP_ALTA_ACTIVIDAD_ARANCELADA @cod_actividad = 301, @nombre = 'Natación', @arancel = 5000.00, @meses_por_cuota = 1;

INSERT INTO HABILITADA_PARA (cod_actividad, nombre_categoria)
VALUES (201, 'infantiles'),
       (201, 'mayores'),
       (201, 'vitalicios'),
       (202, 'mayores'),
       (202, 'vitalicios'),
       (301, 'mayores');

-- Grupo A: titular mayores con un integrante infantiles
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000001',
    @domicilio = 'Calle Mitre 400',
    @nombre_titular = 'Marta Ruiz',
    @fecha_nacimiento = '1980-03-10',
    @nombre_categoria = 'mayores',
    @nro_socio_base = @id_a OUTPUT;

INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
VALUES (@id_a, 1, 'Tomas Ruiz', '2014-07-22', NULL, '2236000011', 'infantiles');

-- Grupo B: titular mayores sin integrantes
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000002',
    @domicilio = 'Calle Moreno 120',
    @nombre_titular = 'Pablo Diaz',
    @fecha_nacimiento = '1982-05-05',
    @nombre_categoria = 'mayores',
    @nro_socio_base = @id_b OUTPUT;

-- Grupo C: titular vitalicios con un integrante mayores
EXEC SP_ALTA_GRUPO_FAMILIAR
    @telefono = '2236000003',
    @domicilio = 'Av. Luro 800',
    @nombre_titular = 'Elena Sosa',
    @fecha_nacimiento = '1952-09-14',
    @nombre_categoria = 'vitalicios',
    @nro_socio_base = @id_c OUTPUT;

INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
VALUES (@id_c, 1, 'Raul Sosa', '1978-01-30', NULL, '2236000033', 'mayores');

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
VALUES ('AREA-01', 'Gimnasio planta baja', 30, 'Bueno');

INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad)
VALUES (30111222, 201);

INSERT INTO APTA_PARA (cod_area, cod_actividad)
VALUES ('AREA-01', 201);

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
VALUES (@id_dictado, 'AREA-01');

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
--   SP_CONSULTA_TITULARES_DEUDA 2026: Juan Perez 121500.00 (3); Carlos Gomez 90000.00 (2); Sofia Rodriguez 45000.00 (1);
--     Roberto Fernandez 38250.00 (1); Laura Martinez 45000.00 (1); Pablo Diaz 30000.00 (1); Elena Sosa 78250.00 (2).
--   SP_CONSULTA_SOCIOS_GRATUITAS 2025: mayores 2 (Marta, Raul); el resto 0.
EXEC SP_CONSULTA_TITULARES_DEUDA @anio = 2026;
EXEC SP_CONSULTA_SOCIOS_GRATUITAS @anio = 2025;
GO

-- Pruebas de rechazo y control. Cada bloque corre en una transacción que se revierte.
-- Usa dni 1001 y área 'AREA-99', distintos de los datos de arriba, para no chocar con ellos.

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
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES ('AREA-99', 'Pileta', 10, 'Bueno');
    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (SCOPE_IDENTITY(), 'AREA-99');
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
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES ('AREA-99', 'Pileta', 10, 'Bueno');
    INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad) VALUES (1001, 201);
    INSERT INTO APTA_PARA (cod_area, cod_actividad) VALUES ('AREA-99', 201);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    DECLARE @d1 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@d1, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@d1, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@d1, 'AREA-99');

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
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES ('AREA-99', 'Pileta', 10, 'Bueno');
    INSERT INTO PUEDE_DESEMPENIARSE_EN (dni, cod_actividad) VALUES (1001, 201);
    INSERT INTO APTA_PARA (cod_area, cod_actividad) VALUES ('AREA-99', 201);

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '10:00', '11:00', 201);
    DECLARE @e1 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@e1, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@e1, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@e1, 'AREA-99');

    INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad) VALUES ('2026-03-01', '2026-03-31', '11:00', '12:00', 201);
    DECLARE @e2 INT = SCOPE_IDENTITY();
    INSERT INTO DICTADO_DIA (cod_dictado, dia_semana) VALUES (@e2, 1);
    INSERT INTO A_CARGO_DE (cod_dictado, dni) VALUES (@e2, 1001);
    INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area) VALUES (@e2, 'AREA-99');
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
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000009', @domicilio = 'Calle Test 1', @nombre_titular = 'Titular Test', @fecha_nacimiento = '1980-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @f OUTPUT;
    INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
    VALUES (@f, 1, 'Integrante Test', '2010-01-01', NULL, NULL, 'infantiles');
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
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000010', @domicilio = 'Calle Test 2', @nombre_titular = 'Titular Solo', @fecha_nacimiento = '1980-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @g OUTPUT;
    DELETE FROM SOCIO WHERE nro_socio_base = @g AND nro_orden = 0;
    PRINT 'G: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'G: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- H: actividad de tipo G en ACTIVIDAD_ARANCELADA -> rechaza 50011
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO ACTIVIDAD (cod_actividad, nombre, tipo) VALUES (901, 'Test H', 'G');
    INSERT INTO ACTIVIDAD_ARANCELADA (cod_actividad, arancel, meses_por_cuota) VALUES (901, 100.00, 1);
    PRINT 'H: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'H: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- I: actividad de tipo A en ACTIVIDAD_GRATUITA -> rechaza 50012
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO ACTIVIDAD (cod_actividad, nombre, tipo) VALUES (902, 'Test I', 'A');
    INSERT INTO ACTIVIDAD_GRATUITA (cod_actividad) VALUES (902);
    PRINT 'I: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'I: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- J: cambiar el tipo de una actividad que ya tiene subentidad (301, arancelada) -> rechaza 50013
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE ACTIVIDAD SET tipo = 'G' WHERE cod_actividad = 301;
    PRINT 'J: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'J: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- K (control): alta por SP de una actividad gratuita y una arancelada -> pasan
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC SP_ALTA_ACTIVIDAD_GRATUITA @cod_actividad = 903, @nombre = 'Test K gratuita';
    EXEC SP_ALTA_ACTIVIDAD_ARANCELADA @cod_actividad = 904, @nombre = 'Test K arancelada', @arancel = 100.00, @meses_por_cuota = 1;
    PRINT 'K: control OK (pasó sin rechazo)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'K: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- L: dni no positivo -> rechaza por CK_PROFESIONAL_DNI; cod_area en blanco o con espacios al borde -> rechaza por CK_AREA_COD_AREA.
-- Cada caso corre en una transacción que se revierte, por si un CHECK dejara pasar el dato.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo) VALUES (0, 'Prof Test', 'Calle 1', '123', 'Lic');
    PRINT 'L1: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'L1: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES ('  ', 'Pileta', 10, 'Bueno');
    PRINT 'L2: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'L2: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES (' A1', 'Pileta', 10, 'Bueno');
    PRINT 'L3: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'L3: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- M: categoría fuera de las tres del enunciado -> rechaza por CK_CATEGORIA_NOMBRE
-- N: nro_orden negativo -> rechaza por CK_SOCIO_NRO_ORDEN
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO CATEGORIA (nombre_categoria, porcentaje_mod_cuota) VALUES ('juveniles', -10.00);
    PRINT 'M: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'M: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
    VALUES ((SELECT MIN(nro_socio_base) FROM GRUPO_FAMILIAR), -1, 'Socio Test', '1990-01-01', NULL, NULL, 'mayores');
    PRINT 'N: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'N: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO
