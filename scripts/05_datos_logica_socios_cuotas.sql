USE ClubDeportivo;
GO

---------------------------------------------------------------------
-------------------SECCION 1 ALTA DE ACTIVIDADES---------------------
---------------------------------------------------------------------

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

---------------------------------------------------------------------
----------SECCION 2 ALTA DE GRUPOS FAMILIARES Y SOCIOS---------------
---------------------------------------------------------------------
DECLARE @id_a INT;
DECLARE @id_b INT;
DECLARE @id_c INT;

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

---------------------------------------------------------------------
--------SECCION 3 LIQUIDACIÓN  Y PAGO DE CUOTAS SOCIALES-------------
---------------------------------------------------------------------
DECLARE @anio INT = YEAR(GETDATE());

-- Cuotas sociales de enero a marzo del año actual para todos los grupos
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

---------------------------------------------------------------------
----------SECCION 4 INSCRIPCIÓN A ACTIVIDADES GRATUITAS--------------
---------------------------------------------------------------------

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

---------------------------------------------------------------------
-------SECCION 5 ALTA DE PROFESIONAL Y CONFIGURACIÓN DE AREAS--------
---------------------------------------------------------------------

-- Cronograma: profesional y área aptos para la actividad 201, y un dictado válido
INSERT INTO PROFESIONAL (dni, nombre, domicilio, telefono, titulo)
VALUES (30111222, 'Ana Torres', 'Calle 9 de Julio 300', '2237000001', 'Profesora de Educación Física');

-- Áreas con su historial de estados. AREA-01 siempre operativa; AREA-02 pasa por varios estados, vuelve a
-- un estado anterior y hoy está fuera de servicio.
DECLARE @inicio_anterior DATE = DATEFROMPARTS(@anio - 1, 1, 1);
DECLARE @mantenimiento_1 DATE = DATEFROMPARTS(@anio - 1, 6, 1);
DECLARE @operativa_2 DATE = DATEFROMPARTS(@anio - 1, 9, 1);
DECLARE @fuera_servicio DATE = DATEFROMPARTS(@anio, 1, 1);

EXEC SP_ALTA_AREA @cod_area = 'AREA-01', @ubicacion = 'Gimnasio planta baja', @capacidad = 30,
    @nombre_estado = 'Operativa', @fecha_desde = @inicio_anterior;

EXEC SP_ALTA_AREA @cod_area = 'AREA-02', @ubicacion = 'Pileta cubierta', @capacidad = 25,
    @nombre_estado = 'Operativa', @fecha_desde = @inicio_anterior;
EXEC SP_CAMBIAR_ESTADO_AREA @cod_area = 'AREA-02', @nombre_estado = 'En mantenimiento', @fecha_desde = @mantenimiento_1;
EXEC SP_CAMBIAR_ESTADO_AREA @cod_area = 'AREA-02', @nombre_estado = 'Operativa', @fecha_desde = @operativa_2;
EXEC SP_CAMBIAR_ESTADO_AREA @cod_area = 'AREA-02', @nombre_estado = 'Fuera de servicio', @fecha_desde = @fuera_servicio;

---------------------------------------------------------------------
--------SECCION 6 ALGUNAS RELACIONES Y CREACIÓN DICTADO--------------
---------------------------------------------------------------------


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

------------------------------------------------------------------------
--SECCION 7 INSCRIPCIÓN A ACTIVIDAD ARANCELADA Y LIQUIDACIÓN DE CUOTAS--
------------------------------------------------------------------------

-- Arancel: Marta se inscribe en la arancelada 301 (cuota 1 por adelantado) y se liquidan febrero y marzo
EXEC SP_INSCRIBIR_ACTIVIDAD @nro_socio_base = @id_a, @nro_orden = 0, @cod_actividad = 301, @fecha_inscripcion = @fecha_marta;
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio, @mes = 2;
EXEC SP_LIQUIDAR_CUOTA_ARANCEL @anio = @anio, @mes = 3;

---------------------------------------------------------------------
----------SECCION 8 PAGOS ARANCELADOS Y CALCULO DE DEUDA-------------
---------------------------------------------------------------------

-- Cuota 1 paga todo, cuota 2 pago parcial, cuota 3 sin pagar
UPDATE CUOTA_ARANCEL
SET monto_abonado = monto_a_pagar,
    fecha_pago = DATEFROMPARTS(@anio, 1, 15)
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 1;

UPDATE CUOTA_ARANCEL
SET monto_abonado = 2000.00,
    fecha_pago = DATEFROMPARTS(@anio, 2, 16)
WHERE nro_socio_base = @id_a AND cod_actividad = 301 AND nro_cuota = 2;

---------------------------------------------------------------------
---------SECCION 9 CONSULTAS Y VERIFICACIÓN DE RESULTADOS------------
---------------------------------------------------------------------


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

-- Estado vigente de las áreas (VW_ESTADO_ACTUAL_AREA): AREA-01 Operativa; AREA-02 Fuera de servicio.
-- El historial completo de AREA-02: Operativa, En mantenimiento, Operativa (vuelve a un estado anterior) y Fuera de servicio.
SELECT * FROM VW_ESTADO_ACTUAL_AREA;
SELECT * FROM HISTORIAL_AREA_ESTADO WHERE cod_area = 'AREA-02' ORDER BY fecha_desde;
GO
