USE ClubDeportivo;
GO

-- Datos de prueba para los triggers, SP y vistas de 03_logica_socios_cuotas.sql y 04_logica_areas_profesionales.sql.
-- Se ejecuta después de 04 (base recién creada por 00). Usa nro_socio_base generados por SP_ALTA_GRUPO_FAMILIAR.
-- Los titulares de los grupos de 02 tienen nro_orden = 0, así que también aparecen en VW_TITULARES_DEUDA_ANIO_ACTUAL.
-- Las fechas son relativas al año actual (@anio) y al anterior (@anio - 1), igual que los valores de cuota de 02,
-- para que las vistas, que usan YEAR(GETDATE()), den los mismos resultados cualquiera sea el año en que se corra.

DECLARE @anio INT = YEAR(GETDATE());
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

-- Cuotas sociales de enero a marzo del año actual para todos los grupos (incluye los de 02)
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = @anio, @mes = 1;
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = @anio, @mes = 2;
EXEC SP_LIQUIDAR_CUOTA_SOCIAL @anio = @anio, @mes = 3;

-- Grupo A: paga todo (sin deuda)
UPDATE CUOTA_SOCIAL
SET monto_abonado = monto_a_pagar,
    fecha_pago = DATEFROMPARTS(@anio, 1, 10)
WHERE nro_socio_base = @id_a
  AND anio = @anio;

-- Grupo B: paga sólo enero (deuda de febrero y marzo)
UPDATE CUOTA_SOCIAL
SET monto_abonado = monto_a_pagar,
    fecha_pago = DATEFROMPARTS(@anio, 1, 12)
WHERE nro_socio_base = @id_b
  AND anio = @anio
  AND mes = 1;

-- Grupo C: pago parcial de enero, sin pagos el resto del año
UPDATE CUOTA_SOCIAL
SET monto_abonado = 5000.00,
    fecha_pago = DATEFROMPARTS(@anio, 1, 15)
WHERE nro_socio_base = @id_c
  AND anio = @anio
  AND mes = 1;

-- Inscripciones del año anterior: Marta en las dos gratuitas, Raul en las dos, Tomas y Pablo sólo en una
INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
VALUES (@id_a, 0, 201, DATEFROMPARTS(@anio - 1, 3, 1)),
       (@id_a, 0, 202, DATEFROMPARTS(@anio - 1, 3, 2)),
       (@id_a, 1, 201, DATEFROMPARTS(@anio - 1, 3, 1)),
       (@id_b, 0, 201, DATEFROMPARTS(@anio - 1, 4, 10)),
       (@id_c, 1, 201, DATEFROMPARTS(@anio - 1, 5, 5)),
       (@id_c, 1, 202, DATEFROMPARTS(@anio - 1, 5, 5));

-- Inscripción del año actual de Pablo: no cuenta para la consulta del año anterior
INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
VALUES (@id_b, 0, 202, DATEFROMPARTS(@anio, 2, 1));

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
DECLARE @fecha_marta DATE = DATEFROMPARTS(@anio, 1, 15);

EXEC SP_ALTA_DICTADO
    @cod_actividad = 201,
    @fecha_desde = '2026-03-01',
    @fecha_fin = '2026-06-30',
    @hora_inicio = '10:00',
    @hora_fin = '11:00',
    @dia_semana = 1,
    @dni = 30111222,
    @cod_area = 'AREA-01',
    @cod_dictado = @id_dictado OUTPUT;

-- Arancel: Marta se inscribe en la arancelada 301 (cuota 1 por adelantado) y se liquidan febrero y marzo
EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @id_a, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @fecha_marta;
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio, @mes = 2;
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio, @mes = 3;

-- Cuota 1 paga todo, cuota 2 pago parcial, cuota 3 sin pagar
UPDATE CUOTA_ARANCEL
SET monto_abonado = monto_a_pagar,
    fecha_pago = DATEFROMPARTS(@anio, 1, 15)
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 1;

UPDATE CUOTA_ARANCEL
SET monto_abonado = 2000.00,
    fecha_pago = DATEFROMPARTS(@anio, 2, 16)
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 2;

-- Resultado esperado: 8000.00 (3000 de la cuota 2 + 5000 de la cuota 3)
SELECT SUM(monto_a_pagar - ISNULL(monto_abonado, 0)) AS deuda_arancel_marta
FROM CUOTA_ARANCEL
WHERE nro_socio_base = @id_a AND cod_actividad = 301;
GO

-- Resultados esperados:
--   VW_TITULARES_DEUDA_ANIO_ACTUAL: Juan Perez 121500.00 (3); Carlos Gomez 90000.00 (2); Sofia Rodriguez 45000.00 (1);
--     Roberto Fernandez 38250.00 (1); Laura Martinez 45000.00 (1); Pablo Diaz 30000.00 (1); Elena Sosa 78250.00 (2).
--   VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR: una sola fila, mayores 2 (Marta, Raul); las categorías sin socios no se muestran.
SELECT * FROM VW_TITULARES_DEUDA_ANIO_ACTUAL;
SELECT * FROM VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR;
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
    INSERT INTO CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)
    VALUES ((SELECT nro_socio_base FROM SOCIO WHERE nombre = 'Marta Ruiz'), 0, 201, DATEFROMPARTS(YEAR(GETDATE()) - 1, 3, 1), 1, 100.00, DATEFROMPARTS(YEAR(GETDATE()) - 1, 3, 1), NULL, NULL);
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

-- O (H12): al cambiar la categoría, se da de baja la inscripción no habilitada para la nueva y se conserva la compatible.
-- El socio es mayores y se inscribe en 202 (mayores y vitalicios) y 301 (sólo mayores); al pasar a vitalicios, 301 queda en Baja.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @o INT;
    DECLARE @hoy_o DATE = CAST(GETDATE() AS DATE);
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000011', @domicilio = 'Calle Test 3', @nombre_titular = 'Titular O', @fecha_nacimiento = '1970-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @o OUTPUT;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @o, @nro_orden = 0, @cod_actividad = 202, @fecha_inscripcion = @hoy_o;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @o, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @hoy_o;
    UPDATE SOCIO SET nombre_categoria = 'vitalicios' WHERE nro_socio_base = @o AND nro_orden = 0;
    IF (SELECT estado FROM INSCRIPCION WHERE nro_socio_base = @o AND cod_actividad = 202) = 'Activa'
       AND (SELECT estado FROM INSCRIPCION WHERE nro_socio_base = @o AND cod_actividad = 301) = 'Baja'
       AND (SELECT COUNT(*) FROM CUOTA_ARANCEL WHERE nro_socio_base = @o AND cod_actividad = 301) = 1
        PRINT 'O: control OK (202 Activa, 301 Baja, cuota 1 conservada)';
    ELSE
        PRINT 'O: control FALLÓ';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'O: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- P1 (control): tras una baja, el socio puede reinscribirse en la misma actividad (otra fecha_inscripcion).
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @p1 INT;
    DECLARE @hoy_p1 DATE = CAST(GETDATE() AS DATE);
    DECLARE @manana_p1 DATE = DATEADD(DAY, 1, @hoy_p1);
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000012', @domicilio = 'Calle Test 4', @nombre_titular = 'Titular P1', @fecha_nacimiento = '1970-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @p1 OUTPUT;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @p1, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @hoy_p1;
    UPDATE SOCIO SET nombre_categoria = 'vitalicios' WHERE nro_socio_base = @p1 AND nro_orden = 0;
    UPDATE SOCIO SET nombre_categoria = 'mayores' WHERE nro_socio_base = @p1 AND nro_orden = 0;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @p1, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @manana_p1;
    IF (SELECT COUNT(*) FROM INSCRIPCION WHERE nro_socio_base = @p1 AND cod_actividad = 301 AND estado = 'Activa') = 1
       AND (SELECT COUNT(*) FROM INSCRIPCION WHERE nro_socio_base = @p1 AND cod_actividad = 301 AND estado = 'Baja') = 1
        PRINT 'P1: control OK (reinscripción tras la baja)';
    ELSE
        PRINT 'P1: control FALLÓ';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'P1: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- P2: dos inscripciones activas del mismo socio en la misma actividad -> rechaza 50014
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @p2 INT;
    DECLARE @hoy_p2 DATE = CAST(GETDATE() AS DATE);
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000013', @domicilio = 'Calle Test 5', @nombre_titular = 'Titular P2', @fecha_nacimiento = '1970-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @p2 OUTPUT;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @p2, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @hoy_p2;
    INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
    VALUES (@p2, 0, 301, DATEADD(DAY, 1, @hoy_p2));
    PRINT 'P2: NO RECHAZADO (error)';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'P2: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- Q (control): puesta al día. El socio se inscribe en 301 en enero y se liquida directamente abril:
-- se generan las cuotas 1 a 4 sin huecos, y correr de nuevo no duplica.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @q INT;
    DECLARE @anio_q INT = YEAR(GETDATE());
    DECLARE @enero_q DATE = DATEFROMPARTS(@anio_q, 1, 10);
    EXEC SP_ALTA_GRUPO_FAMILIAR @telefono = '2236000014', @domicilio = 'Calle Test 6', @nombre_titular = 'Titular Q', @fecha_nacimiento = '1970-01-01', @nombre_categoria = 'mayores', @nro_socio_base = @q OUTPUT;
    EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @q, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @enero_q;
    EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio_q, @mes = 4;
    EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio_q, @mes = 4;
    IF (SELECT COUNT(*) FROM CUOTA_ARANCEL WHERE nro_socio_base = @q) = 4
       AND (SELECT MAX(nro_cuota) FROM CUOTA_ARANCEL WHERE nro_socio_base = @q) = 4
       AND (SELECT MAX(fecha_vencimiento) FROM CUOTA_ARANCEL WHERE nro_socio_base = @q) = DATEFROMPARTS(@anio_q, 4, 10)
        PRINT 'Q: control OK (cuotas 1 a 4 correlativas, sin duplicar)';
    ELSE
        PRINT 'Q: control FALLÓ';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'Q: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- S (control): sin actividades gratuitas la consulta 2 no devuelve filas.
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM ACTIVIDAD_GRATUITA;
    IF (SELECT COUNT(*) FROM VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR) = 0
        PRINT 'S: control OK (sin gratuitas, la vista no devuelve filas)';
    ELSE
        PRINT 'S: control FALLÓ';
    ROLLBACK;
END TRY
BEGIN CATCH
    PRINT 'S: control FALLÓ ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK;
END CATCH;
GO

-- R: SP_ALTA_DICTADO con un área no apta para la actividad -> rechaza 50006 y no deja filas.
-- El área de prueba se inserta fuera de la transacción del SP y se borra al final.
INSERT INTO AREA (cod_area, ubicacion, capacidad, estado_mantenimiento) VALUES ('AREA-98', 'Pileta', 10, 'Bueno');
DECLARE @dictados_antes INT = (SELECT COUNT(*) FROM DICTADO);
DECLARE @id_r INT;
BEGIN TRY
    EXEC SP_ALTA_DICTADO @cod_actividad = 201, @fecha_desde = '2026-03-01', @fecha_fin = '2026-06-30', @hora_inicio = '15:00', @hora_fin = '16:00', @dia_semana = 3, @dni = 30111222, @cod_area = 'AREA-98', @cod_dictado = @id_r OUTPUT;
    PRINT 'R: NO RECHAZADO (error)';
END TRY
BEGIN CATCH
    PRINT 'R: rechazo ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' ' + ERROR_MESSAGE();
END CATCH;
IF (SELECT COUNT(*) FROM DICTADO) = @dictados_antes
    PRINT 'R: sin filas nuevas en DICTADO';
ELSE
    PRINT 'R: quedaron filas en DICTADO (error)';
DELETE FROM AREA WHERE cod_area = 'AREA-98';
GO
