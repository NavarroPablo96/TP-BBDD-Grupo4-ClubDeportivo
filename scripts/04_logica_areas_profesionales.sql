USE ClubDeportivo;
GO

-- Triggers de profesionales y áreas de los dictados, SP y vistas del historial de estados de las áreas
-- y regla del estado operativo (un dictado sólo en un área operativa durante todo su período).

---------------------------------------------------------------------
------------------------SECCION Integrante 6-------------------------
---------------------------------------------------------------------

-- Historial de estados de mantenimiento de las áreas
-- Que un área tiene un único estado por fecha lo garantiza la PK de HISTORIAL_AREA_ESTADO y que el estado
-- exista en el catálogo, la FK a ESTADO_AREA.
-- Limitación: que todo área tenga al menos un estado sólo lo garantiza SP_ALTA_AREA; un INSERT directo
-- en AREA lo saltea y el área figura sin estado en VW_ESTADO_ACTUAL_AREA.

-- SP_ALTA_AREA
-- Crea el área y su primer estado en una transacción. Si @fecha_desde es NULL, rige la fecha actual.
CREATE OR ALTER PROCEDURE SP_ALTA_AREA
    @cod_area VARCHAR(20),
    @ubicacion VARCHAR(100),
    @capacidad INT,
    @nombre_estado VARCHAR(30),
    @fecha_desde DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO AREA (cod_area, ubicacion, capacidad)
        VALUES (@cod_area, @ubicacion, @capacidad);

        INSERT INTO HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)
        VALUES (@cod_area, ISNULL(@fecha_desde, CAST(GETDATE() AS DATE)), @nombre_estado);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- SP_CAMBIAR_ESTADO_AREA
-- Registra un nuevo estado de un área desde una fecha (por defecto, la actual). El área puede volver a un
-- estado anterior; en una misma fecha tiene un único estado (PK).
CREATE OR ALTER PROCEDURE SP_CAMBIAR_ESTADO_AREA
    @cod_area VARCHAR(20),
    @nombre_estado VARCHAR(30),
    @fecha_desde DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO HISTORIAL_AREA_ESTADO (cod_area, fecha_desde, nombre_estado)
        VALUES (@cod_area, ISNULL(@fecha_desde, CAST(GETDATE() AS DATE)), @nombre_estado);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- VW_ESTADO_ACTUAL_AREA
-- Estado vigente de cada área: el de mayor fecha_desde que no sea futura. Las áreas sin historial
-- (cargadas con un INSERT directo) aparecen con estado NULL.
CREATE OR ALTER VIEW VW_ESTADO_ACTUAL_AREA
AS
SELECT a.cod_area,
       a.ubicacion,
       a.capacidad,
       h.nombre_estado,
       h.fecha_desde
FROM AREA a
LEFT JOIN (
    SELECT cod_area,
           nombre_estado,
           fecha_desde,
           ROW_NUMBER() OVER (PARTITION BY cod_area ORDER BY fecha_desde DESC) AS posicion
    FROM HISTORIAL_AREA_ESTADO
    WHERE fecha_desde <= CAST(GETDATE() AS DATE)
) h
    ON h.cod_area = a.cod_area
   AND h.posicion = 1;
GO


-- Regla del estado operativo
-- un dictado sólo puede desarrollarse en un área que esté 'Operativa' durante todo su período.
-- Un área sin historial de estados (cargada con un INSERT directo en AREA) no se restringe.

-- VW_AREA_ESTADO_PERIODO
-- Intervalos de vigencia de cada estado: desde su fecha_desde hasta el día anterior al siguiente estado.
-- El último estado queda abierto (hasta 9999-12-31).
CREATE OR ALTER VIEW VW_AREA_ESTADO_PERIODO
AS
SELECT cod_area,
       nombre_estado,
       fecha_desde AS desde,
       ISNULL(DATEADD(DAY, -1, LEAD(fecha_desde) OVER (PARTITION BY cod_area ORDER BY fecha_desde)),
              CAST('9999-12-31' AS DATE)) AS hasta
FROM HISTORIAL_AREA_ESTADO;
GO




---------------------------------------------------------------------
------------------SECCION COMUN Integrante 5 y 6---------------------
---------------------------------------------------------------------
-- VW_CONFLICTOS_ESTADO_DICTADO
-- Pares (dictado, área) en los que el área está en un estado distinto de 'Operativa' en algún momento del
-- período del dictado. Los triggers TR_DICTADO_AREA_OPERATIVA_* consultan esta vista.
CREATE OR ALTER VIEW VW_CONFLICTOS_ESTADO_DICTADO
AS
SELECT d.cod_dictado,
       s.cod_area,
       p.nombre_estado,
       p.desde,
       p.hasta
FROM DICTADO d
INNER JOIN SE_DESARROLLA_EN s
    ON s.cod_dictado = d.cod_dictado
INNER JOIN VW_AREA_ESTADO_PERIODO p
    ON p.cod_area = s.cod_area
WHERE p.nombre_estado <> 'Operativa'
  AND p.desde <= d.fecha_fin
  AND d.fecha_desde <= p.hasta;
GO


-- TR_DICTADO_AREA_OPERATIVA_* (una por tabla que puede crear el conflicto)
-- Al asignar un área a un dictado, al cambiar las fechas de un dictado y al cambiar el historial de estados.
CREATE OR ALTER TRIGGER TR_DICTADO_AREA_OPERATIVA_SE_DESARROLLA_EN
ON SE_DESARROLLA_EN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_ESTADO_DICTADO) > 0
        THROW 50015, 'El área no está operativa durante todo el período del dictado.', 1;
END;
GO

CREATE OR ALTER TRIGGER TR_DICTADO_AREA_OPERATIVA_DICTADO
ON DICTADO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_ESTADO_DICTADO) > 0
        THROW 50015, 'El área no está operativa durante todo el período del dictado.', 1;
END;
GO

CREATE OR ALTER TRIGGER TR_DICTADO_AREA_OPERATIVA_HISTORIAL
ON HISTORIAL_AREA_ESTADO
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_ESTADO_DICTADO) > 0
        THROW 50015, 'El cambio de estado deja al área sin operar durante el período de un dictado que se desarrolla en ella.', 1;
END;
GO


-- TR_SE_DESARROLLA_EN_AREA_APTA
-- toda área en la que se desarrolla un dictado debe ser apta para la actividad de ese dictado.
CREATE OR ALTER TRIGGER TR_SE_DESARROLLA_EN_AREA_APTA
ON SE_DESARROLLA_EN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN DICTADO d
            ON d.cod_dictado = i.cod_dictado
        LEFT JOIN APTA_PARA a
            ON a.cod_area = i.cod_area
           AND a.cod_actividad = d.cod_actividad
        WHERE a.cod_area IS NULL
    ) > 0
    BEGIN
        THROW 50006, 'El área no es apta para la actividad del dictado.', 1;
    END;
END;
GO

---------------------------------------------------------------------
------------------------SECCION Integrante 5-------------------------
---------------------------------------------------------------------

-- TR_A_CARGO_DE_PROF_HABILITADO
-- todo profesional a cargo de un dictado debe poder desempeñarse en la actividad de ese dictado.
CREATE OR ALTER TRIGGER TR_A_CARGO_DE_PROF_HABILITADO
ON A_CARGO_DE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN DICTADO d
            ON d.cod_dictado = i.cod_dictado
        LEFT JOIN PUEDE_DESEMPENIARSE_EN p
            ON p.dni = i.dni
           AND p.cod_actividad = d.cod_actividad
        WHERE p.dni IS NULL
    ) > 0
    BEGIN
        THROW 50005, 'El profesional no puede dictar esta actividad: no está habilitado para desempeñarse en ella.', 1;
    END;
END;
GO