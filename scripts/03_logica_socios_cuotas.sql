USE ClubDeportivo;
GO

-- Triggers, procedimientos almacenados y vistas de socios y cuotas sociales.
-- Se pueden volver a crear con CREATE OR ALTER.


-- TR_INSCRIPCION_CATEGORIA_HABILITADA
-- §4.2: un socio sólo puede inscribirse en una actividad habilitada para su categoría.
-- Sólo valida las inscripciones activas: la baja por cambio de categoría (H12) no debe rechazarse a sí misma.
CREATE OR ALTER TRIGGER TR_INSCRIPCION_CATEGORIA_HABILITADA
ON INSCRIPCION
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN SOCIO s
            ON s.nro_socio_base = i.nro_socio_base
           AND s.nro_orden = i.nro_orden
        LEFT JOIN HABILITADA_PARA h
            ON h.cod_actividad = i.cod_actividad
           AND h.nombre_categoria = s.nombre_categoria
        WHERE i.estado = 'Activa'
          AND h.cod_actividad IS NULL
    ) > 0
    BEGIN
        THROW 50001, 'El socio no puede inscribirse: la actividad no está habilitada para su categoría.', 1;
    END;
END;
GO


-- TR_INSCRIPCION_VIGENTE_UNICA
-- H6: cada socio tiene como máximo una inscripción vigente (activa) por actividad.
-- Se usa un trigger y no un índice único filtrado porque sqlcmd corre con QUOTED_IDENTIFIER OFF.
CREATE OR ALTER TRIGGER TR_INSCRIPCION_VIGENTE_UNICA
ON INSCRIPCION
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT n.nro_socio_base,
                   n.nro_orden,
                   n.cod_actividad
            FROM INSCRIPCION n
            INNER JOIN (
                SELECT DISTINCT nro_socio_base, nro_orden, cod_actividad
                FROM inserted
                WHERE estado = 'Activa'
            ) i
                ON i.nro_socio_base = n.nro_socio_base
               AND i.nro_orden = n.nro_orden
               AND i.cod_actividad = n.cod_actividad
            WHERE n.estado = 'Activa'
            GROUP BY n.nro_socio_base, n.nro_orden, n.cod_actividad
            HAVING COUNT(*) > 1
        ) repetidas
    ) > 0
    BEGIN
        THROW 50014, 'El socio ya tiene una inscripción activa en esta actividad.', 1;
    END;
END;
GO


-- TR_VALOR_CUOTA_SOCIAL_VIGENCIA
-- §4.2: los períodos de VALOR_CUOTA_SOCIAL no se superponen ni dejan huecos.
-- Cada período debe terminar el día anterior al inicio del siguiente.
-- Sólo el último período puede no tener fecha_hasta.
CREATE OR ALTER TRIGGER TR_VALOR_CUOTA_SOCIAL_VIGENCIA
ON VALOR_CUOTA_SOCIAL
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT fecha_desde,
                   fecha_hasta,
                   LEAD(fecha_desde) OVER (ORDER BY fecha_desde) AS siguiente_desde
            FROM VALOR_CUOTA_SOCIAL
        ) periodos
        WHERE (siguiente_desde IS NOT NULL
               AND (fecha_hasta IS NULL OR fecha_hasta <> DATEADD(DAY, -1, siguiente_desde)))
    ) > 0
    BEGIN
        THROW 50002, 'Los períodos de VALOR_CUOTA_SOCIAL se superponen o dejan huecos.', 1;
    END;
END;
GO


-- TR_SOCIO_TITULAR_CATEGORIA
-- §4.2: el titular de un grupo no puede pertenecer a la categoría infantiles.
CREATE OR ALTER TRIGGER TR_SOCIO_TITULAR_CATEGORIA
ON SOCIO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted
        WHERE nro_orden = 0
          AND nombre_categoria = 'infantiles'
    ) > 0
    BEGIN
        THROW 50003, 'El titular de un grupo familiar no puede pertenecer a la categoría infantiles.', 1;
    END;
END;
GO


-- TR_SOCIO_CAMBIO_CATEGORIA
-- H12: al cambiar la categoría de un socio se dan de baja sus inscripciones activas a actividades
-- no habilitadas para la nueva categoría. Las compatibles se conservan.
-- fecha_baja es la fecha actual (o la de inscripción si ésta es posterior, para respetar CK_INSCRIPCION_FECHA_BAJA).
CREATE OR ALTER TRIGGER TR_SOCIO_CAMBIO_CATEGORIA
ON SOCIO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(nombre_categoria)
        RETURN;

    UPDATE i
    SET estado = 'Baja',
        fecha_baja = CASE WHEN CAST(GETDATE() AS DATE) < i.fecha_inscripcion
                          THEN i.fecha_inscripcion
                          ELSE CAST(GETDATE() AS DATE)
                     END
    FROM INSCRIPCION i
    INNER JOIN inserted s
        ON s.nro_socio_base = i.nro_socio_base
       AND s.nro_orden = i.nro_orden
    INNER JOIN deleted d
        ON d.nro_socio_base = s.nro_socio_base
       AND d.nro_orden = s.nro_orden
    LEFT JOIN HABILITADA_PARA h
        ON h.cod_actividad = i.cod_actividad
       AND h.nombre_categoria = s.nombre_categoria
    WHERE i.estado = 'Activa'
      AND s.nombre_categoria <> d.nombre_categoria
      AND h.cod_actividad IS NULL;
END;
GO


-- TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA
-- §4.2 y H9: sólo las inscripciones a actividades aranceladas generan cuotas de arancel.
CREATE OR ALTER TRIGGER TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA
ON CUOTA_ARANCEL
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        LEFT JOIN ACTIVIDAD_ARANCELADA a
            ON a.cod_actividad = i.cod_actividad
        WHERE a.cod_actividad IS NULL
    ) > 0
    BEGIN
        THROW 50008, 'Sólo las inscripciones a actividades aranceladas pueden generar cuotas de arancel.', 1;
    END;
END;
GO


-- SP_ALTA_GRUPO_FAMILIAR
-- H1 y §4.2: todo grupo familiar tiene un titular con nro_orden = 0.
-- Crea el grupo y su titular en una misma transacción.
CREATE OR ALTER PROCEDURE SP_ALTA_GRUPO_FAMILIAR
    @telefono VARCHAR(20),
    @domicilio VARCHAR(100),
    @nombre_titular VARCHAR(50),
    @fecha_nacimiento DATE,
    @nombre_categoria VARCHAR(30),
    @correo_electronico VARCHAR(50) = NULL,
    @celular VARCHAR(20) = NULL,
    @nro_socio_base INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO GRUPO_FAMILIAR (telefono, domicilio)
        VALUES (@telefono, @domicilio);

        SET @nro_socio_base = SCOPE_IDENTITY();

        INSERT INTO SOCIO (nro_socio_base, nro_orden, nombre, fecha_nacimiento, correo_electronico, celular, nombre_categoria)
        VALUES (@nro_socio_base, 0, @nombre_titular, @fecha_nacimiento, @correo_electronico, @celular, @nombre_categoria);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- SP_LIQUIDAR_CUOTA_SOCIAL
-- H8, H10 y §4.2: genera la cuota social de un mes para cada grupo que no la tenga.
-- Monto = suma, sobre cada integrante, del monto base vigente el primer día del mes
-- afectado por el porcentaje de su categoría. Se fija al generar.
-- Supuesto: fecha_vencimiento = último día del mes (pendientes_diseno.md TODO 7).
CREATE OR ALTER PROCEDURE SP_LIQUIDAR_CUOTA_SOCIAL
    @anio INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @primer_dia DATE = DATEFROMPARTS(@anio, @mes, 1);
    DECLARE @vencimiento DATE = EOMONTH(@primer_dia);
    DECLARE @monto_base DECIMAL(15,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @monto_base = monto_base
        FROM VALOR_CUOTA_SOCIAL
        WHERE fecha_desde <= @primer_dia
          AND (fecha_hasta IS NULL OR fecha_hasta >= @primer_dia);

        IF @monto_base IS NULL
            THROW 50004, 'No hay valor de cuota social vigente para el período liquidado.', 1;

        INSERT INTO CUOTA_SOCIAL (nro_socio_base, anio, mes, monto_a_pagar, monto_abonado, fecha_vencimiento, fecha_pago)
        SELECT s.nro_socio_base,
               @anio,
               @mes,
               SUM(ROUND(@monto_base * (1 + c.porcentaje_mod_cuota / 100.0), 2)),
               NULL,
               @vencimiento,
               NULL
        FROM SOCIO s
        INNER JOIN CATEGORIA c
            ON c.nombre_categoria = s.nombre_categoria
        LEFT JOIN CUOTA_SOCIAL cs
            ON cs.nro_socio_base = s.nro_socio_base
           AND cs.anio = @anio
           AND cs.mes = @mes
        WHERE cs.nro_socio_base IS NULL
        GROUP BY s.nro_socio_base;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- Las consultas 1 y 2 son vistas (decisión del usuario, pendientes_diseno.md TODO 8 y 9).
-- Se eliminan los SP que las implementaban antes, por si se re-corre este script sobre una base existente.
DROP PROCEDURE IF EXISTS SP_CONSULTA_TITULARES_DEUDA;
DROP PROCEDURE IF EXISTS SP_CONSULTA_SOCIOS_GRATUITAS;
GO


-- VW_TITULARES_DEUDA_ANIO_ACTUAL
-- Consulta 1 del enunciado: titulares de grupos con cuotas sociales adeudadas del año en curso,
-- con el importe total adeudado y la cantidad de integrantes del grupo.
-- La deuda no se almacena: es monto_a_pagar - monto_abonado (§4.2).
CREATE OR ALTER VIEW VW_TITULARES_DEUDA_ANIO_ACTUAL
AS
SELECT t.nro_socio_base,
       t.nombre AS nombre_titular,
       deuda.importe_adeudado,
       integrantes.cantidad_integrantes
FROM (
    SELECT nro_socio_base,
           SUM(monto_a_pagar - ISNULL(monto_abonado, 0)) AS importe_adeudado
    FROM CUOTA_SOCIAL
    WHERE anio = YEAR(GETDATE())
    GROUP BY nro_socio_base
    HAVING SUM(monto_a_pagar - ISNULL(monto_abonado, 0)) > 0
) deuda
INNER JOIN SOCIO t
    ON t.nro_socio_base = deuda.nro_socio_base
   AND t.nro_orden = 0
INNER JOIN (
    SELECT nro_socio_base,
           COUNT(*) AS cantidad_integrantes
    FROM SOCIO
    GROUP BY nro_socio_base
) integrantes
    ON integrantes.nro_socio_base = deuda.nro_socio_base;
GO


-- VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR
-- Consulta 2 del enunciado: cantidad de socios por categoría inscriptos en todas las
-- actividades gratuitas durante el año pasado (YEAR(GETDATE()) - 1, según fecha_inscripcion).
-- Cuenta también las inscripciones dadas de baja: el socio estuvo inscripto ese año (supuesto, TODO 5).
-- Sólo muestra las categorías con al menos un socio que cumple: si nadie cumple, o no hay actividades
-- gratuitas, la vista no devuelve filas (decisión del usuario, TODO 8).
CREATE OR ALTER VIEW VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR
AS
SELECT c.nombre_categoria,
       COUNT(q.nro_socio_base) AS cantidad_socios
FROM CATEGORIA c
INNER JOIN (
    SELECT s.nombre_categoria,
           s.nro_socio_base,
           s.nro_orden
    FROM SOCIO s
    INNER JOIN (
        SELECT i.nro_socio_base,
               i.nro_orden
        FROM INSCRIPCION i
        INNER JOIN ACTIVIDAD_GRATUITA g
            ON g.cod_actividad = i.cod_actividad
        WHERE YEAR(i.fecha_inscripcion) = YEAR(GETDATE()) - 1
        GROUP BY i.nro_socio_base, i.nro_orden
        HAVING COUNT(DISTINCT i.cod_actividad) = (SELECT COUNT(*) FROM ACTIVIDAD_GRATUITA)
    ) todas
        ON todas.nro_socio_base = s.nro_socio_base
       AND todas.nro_orden = s.nro_orden
) q
    ON q.nombre_categoria = c.nombre_categoria
GROUP BY c.nombre_categoria;
GO


-- VW_CONFLICTOS_DICTADO
-- §4.2: un área o un profesional no puede estar en dos dictados que coincidan en día, horario y período.
-- Lista los pares de dictados en conflicto. Los triggers de cronograma consultan esta vista.
CREATE OR ALTER VIEW VW_CONFLICTOS_DICTADO
AS
WITH coincidencias_dia_horario AS (
    SELECT DISTINCT d1.cod_dictado AS cod_dictado_1,
                    d2.cod_dictado AS cod_dictado_2
    FROM DICTADO d1
    INNER JOIN DICTADO d2
        ON d2.cod_dictado > d1.cod_dictado
    INNER JOIN DICTADO_DIA x
        ON x.cod_dictado = d1.cod_dictado
    INNER JOIN DICTADO_DIA y
        ON y.cod_dictado = d2.cod_dictado
       AND y.dia_semana = x.dia_semana
    WHERE d1.fecha_desde <= d2.fecha_fin
      AND d2.fecha_desde <= d1.fecha_fin
      AND d1.hora_inicio < d2.hora_fin
      AND d2.hora_inicio < d1.hora_fin
)
SELECT c.cod_dictado_1,
       c.cod_dictado_2
FROM coincidencias_dia_horario c
INNER JOIN SE_DESARROLLA_EN x
    ON x.cod_dictado = c.cod_dictado_1
INNER JOIN SE_DESARROLLA_EN y
    ON y.cod_dictado = c.cod_dictado_2
   AND y.cod_area = x.cod_area
UNION
SELECT c.cod_dictado_1,
       c.cod_dictado_2
FROM coincidencias_dia_horario c
INNER JOIN A_CARGO_DE x
    ON x.cod_dictado = c.cod_dictado_1
INNER JOIN A_CARGO_DE y
    ON y.cod_dictado = c.cod_dictado_2
   AND y.dni = x.dni;
GO


-- Los triggers de profesional habilitado y área apta (TR_A_CARGO_DE_PROF_HABILITADO y
-- TR_SE_DESARROLLA_EN_AREA_APTA) están en 04_logica_areas_profesionales.sql.


-- TR_DICTADO_SOLAPAMIENTO (una por tabla que participa del conflicto)
-- §4.2: sin solapamiento de día, horario y período para áreas y profesionales.
CREATE OR ALTER TRIGGER TR_DICTADO_SOLAPAMIENTO_DICTADO
ON DICTADO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_DICTADO) > 0
        THROW 50007, 'El dictado se solapa con otro en día, horario y período, con un área o profesional en común.', 1;
END;
GO

CREATE OR ALTER TRIGGER TR_DICTADO_SOLAPAMIENTO_DICTADO_DIA
ON DICTADO_DIA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_DICTADO) > 0
        THROW 50007, 'El dictado se solapa con otro en día, horario y período, con un área o profesional en común.', 1;
END;
GO

CREATE OR ALTER TRIGGER TR_DICTADO_SOLAPAMIENTO_A_CARGO_DE
ON A_CARGO_DE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_DICTADO) > 0
        THROW 50007, 'El dictado se solapa con otro en día, horario y período, con un área o profesional en común.', 1;
END;
GO

CREATE OR ALTER TRIGGER TR_DICTADO_SOLAPAMIENTO_SE_DESARROLLA_EN
ON SE_DESARROLLA_EN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM VW_CONFLICTOS_DICTADO) > 0
        THROW 50007, 'El dictado se solapa con otro en día, horario y período, con un área o profesional en común.', 1;
END;
GO


-- TR_SOCIO_BAJA_GRUPO
-- H1, H13 y §4.2: el titular no se da de baja mientras el grupo tenga integrantes,
-- y un grupo no queda sin integrantes. Al borrar el grupo completo (cascada), no aplica.
CREATE OR ALTER TRIGGER TR_SOCIO_BAJA_GRUPO
ON SOCIO
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM deleted d
        INNER JOIN SOCIO s
            ON s.nro_socio_base = d.nro_socio_base
        WHERE d.nro_orden = 0
    ) > 0
    BEGIN
        THROW 50009, 'No se puede dar de baja el titular mientras el grupo tenga integrantes.', 1;
    END;

    IF (
        SELECT COUNT(*)
        FROM deleted d
        INNER JOIN GRUPO_FAMILIAR g
            ON g.nro_socio_base = d.nro_socio_base
        LEFT JOIN SOCIO s
            ON s.nro_socio_base = d.nro_socio_base
        WHERE s.nro_socio_base IS NULL
    ) > 0
    BEGIN
        THROW 50010, 'No se puede dar de baja el último integrante de un grupo familiar.', 1;
    END;
END;
GO


-- SP_INSCRIBIR_ACTIVIDAD
-- §4.2 y H9: inscribe a un socio. Si la actividad es arancelada, genera la primera cuota,
-- que vence en la fecha de inscripción (se paga por adelantado). Todo en una transacción.
CREATE OR ALTER PROCEDURE SP_INSCRIBIR_ACTIVIDAD
    @nro_socio_base INT,
    @nro_orden INT,
    @cod_actividad INT,
    @fecha_inscripcion DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @arancel DECIMAL(15,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO INSCRIPCION (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion)
        VALUES (@nro_socio_base, @nro_orden, @cod_actividad, @fecha_inscripcion);

        SELECT @arancel = arancel
        FROM ACTIVIDAD_ARANCELADA
        WHERE cod_actividad = @cod_actividad;

        IF @arancel IS NOT NULL
            INSERT INTO CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)
            VALUES (@nro_socio_base, @nro_orden, @cod_actividad, @fecha_inscripcion, 1, @arancel, @fecha_inscripcion, NULL, NULL);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- SP_LIQUIDAR_CUOTA_ARANCEL
-- H8, H9 y §4.2: genera las cuotas de arancel vencidas hasta el mes indicado que todavía no existan.
-- La cuota n (n >= 1) vence (n - 1) * meses_por_cuota meses después de la inscripción (H9: la primera
-- vence en la fecha de inscripción). Es una "puesta al día": si no se corrió en un mes, la próxima corrida
-- completa las cuotas faltantes y la numeración queda correlativa. No duplica.
-- Sólo genera cuotas de inscripciones activas; las dadas de baja (H12) únicamente las vencidas hasta su fecha de baja.
-- Las cuotas ya generadas se mantienen (H8).
CREATE OR ALTER PROCEDURE SP_LIQUIDAR_CUOTA_ARANCEL
    @anio INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @max_k INT = (
        SELECT ISNULL(MAX(((@anio * 12 + @mes) - (YEAR(i.fecha_inscripcion) * 12 + MONTH(i.fecha_inscripcion)))
                          / a.meses_por_cuota), 0)
        FROM INSCRIPCION i
        INNER JOIN ACTIVIDAD_ARANCELADA a
            ON a.cod_actividad = i.cod_actividad
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH numeros AS (
            SELECT 0 AS k
            UNION ALL
            SELECT k + 1
            FROM numeros
            WHERE k < @max_k
        ),
        inscripciones AS (
            SELECT i.nro_socio_base,
                   i.nro_orden,
                   i.cod_actividad,
                   i.fecha_inscripcion,
                   i.estado,
                   i.fecha_baja,
                   a.arancel,
                   a.meses_por_cuota,
                   (@anio * 12 + @mes) - (YEAR(i.fecha_inscripcion) * 12 + MONTH(i.fecha_inscripcion)) AS meses_transcurridos
            FROM INSCRIPCION i
            INNER JOIN ACTIVIDAD_ARANCELADA a
                ON a.cod_actividad = i.cod_actividad
        ),
        vencimientos AS (
            SELECT v.nro_socio_base,
                   v.nro_orden,
                   v.cod_actividad,
                   v.fecha_inscripcion,
                   n.k + 1 AS nro_cuota,
                   v.arancel,
                   DATEADD(MONTH, n.k * v.meses_por_cuota, v.fecha_inscripcion) AS fecha_vencimiento
            FROM inscripciones v
            INNER JOIN numeros n
                ON n.k * v.meses_por_cuota <= v.meses_transcurridos
            WHERE v.estado = 'Activa'
               OR DATEADD(MONTH, n.k * v.meses_por_cuota, v.fecha_inscripcion) <= v.fecha_baja
        )
        INSERT INTO CUOTA_ARANCEL (nro_socio_base, nro_orden, cod_actividad, fecha_inscripcion, nro_cuota, monto_a_pagar, fecha_vencimiento, monto_abonado, fecha_pago)
        SELECT v.nro_socio_base,
               v.nro_orden,
               v.cod_actividad,
               v.fecha_inscripcion,
               v.nro_cuota,
               v.arancel,
               v.fecha_vencimiento,
               NULL,
               NULL
        FROM vencimientos v
        LEFT JOIN CUOTA_ARANCEL c
            ON c.nro_socio_base = v.nro_socio_base
           AND c.nro_orden = v.nro_orden
           AND c.cod_actividad = v.cod_actividad
           AND c.fecha_inscripcion = v.fecha_inscripcion
           AND c.nro_cuota = v.nro_cuota
        WHERE c.nro_socio_base IS NULL
        OPTION (MAXRECURSION 0);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- Jerarquía de ACTIVIDAD (pendientes_diseno.md TODO 2).
-- Coherencia: la subentidad sólo admite actividades de su tipo. Eso garantiza también la exclusividad.
-- Totalidad: SP_ALTA_ACTIVIDAD_* crean la actividad y su subentidad juntas.
-- Limitación: un INSERT directo en ACTIVIDAD, o borrar una subentidad, puede dejar una actividad sin clasificar.

-- TR_ACTIVIDAD_ARANCELADA_TIPO
CREATE OR ALTER TRIGGER TR_ACTIVIDAD_ARANCELADA_TIPO
ON ACTIVIDAD_ARANCELADA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN ACTIVIDAD a
            ON a.cod_actividad = i.cod_actividad
        WHERE a.tipo <> 'A'
    ) > 0
    BEGIN
        THROW 50011, 'Una actividad arancelada debe tener tipo A.', 1;
    END;
END;
GO


-- TR_ACTIVIDAD_GRATUITA_TIPO
CREATE OR ALTER TRIGGER TR_ACTIVIDAD_GRATUITA_TIPO
ON ACTIVIDAD_GRATUITA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN ACTIVIDAD a
            ON a.cod_actividad = i.cod_actividad
        WHERE a.tipo <> 'G'
    ) > 0
    BEGIN
        THROW 50012, 'Una actividad gratuita debe tener tipo G.', 1;
    END;
END;
GO


-- TR_ACTIVIDAD_TIPO_INMUTABLE
-- El tipo de una actividad con subentidad no puede cambiar: contradiría la subentidad existente.
CREATE OR ALTER TRIGGER TR_ACTIVIDAD_TIPO_INMUTABLE
ON ACTIVIDAD
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (
        SELECT COUNT(*)
        FROM inserted i
        INNER JOIN deleted d
            ON d.cod_actividad = i.cod_actividad
        LEFT JOIN ACTIVIDAD_ARANCELADA ar
            ON ar.cod_actividad = i.cod_actividad
        LEFT JOIN ACTIVIDAD_GRATUITA g
            ON g.cod_actividad = i.cod_actividad
        WHERE i.tipo <> d.tipo
          AND (ar.cod_actividad IS NOT NULL OR g.cod_actividad IS NOT NULL)
    ) > 0
    BEGIN
        THROW 50013, 'No se puede cambiar el tipo de una actividad que ya tiene subentidad.', 1;
    END;
END;
GO


-- SP_ALTA_ACTIVIDAD_ARANCELADA
-- Crea la actividad (tipo A) y su subentidad en una transacción.
CREATE OR ALTER PROCEDURE SP_ALTA_ACTIVIDAD_ARANCELADA
    @cod_actividad INT,
    @nombre VARCHAR(50),
    @arancel DECIMAL(15, 2),
    @meses_por_cuota INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ACTIVIDAD (cod_actividad, nombre, tipo)
        VALUES (@cod_actividad, @nombre, 'A');

        INSERT INTO ACTIVIDAD_ARANCELADA (cod_actividad, arancel, meses_por_cuota)
        VALUES (@cod_actividad, @arancel, @meses_por_cuota);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- SP_ALTA_ACTIVIDAD_GRATUITA
-- Crea la actividad (tipo G) y su subentidad en una transacción.
CREATE OR ALTER PROCEDURE SP_ALTA_ACTIVIDAD_GRATUITA
    @cod_actividad INT,
    @nombre VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ACTIVIDAD (cod_actividad, nombre, tipo)
        VALUES (@cod_actividad, @nombre, 'G');

        INSERT INTO ACTIVIDAD_GRATUITA (cod_actividad)
        VALUES (@cod_actividad);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- SP_ALTA_DICTADO
-- H13 y §4.1: crea un dictado con un día, un profesional a cargo y un área, en una transacción.
-- Un dictado sin profesional ni área no se puede crear: A_CARGO_DE exige @dni y SE_DESARROLLA_EN exige @cod_area.
-- Supuesto: los días, profesionales y áreas adicionales se cargan después en DICTADO_DIA, A_CARGO_DE y SE_DESARROLLA_EN.
CREATE OR ALTER PROCEDURE SP_ALTA_DICTADO
    @cod_actividad INT,
    @fecha_desde DATE,
    @fecha_fin DATE,
    @hora_inicio TIME,
    @hora_fin TIME,
    @dia_semana INT,
    @dni INT,
    @cod_area VARCHAR(20),
    @cod_dictado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO DICTADO (fecha_desde, fecha_fin, hora_inicio, hora_fin, cod_actividad)
        VALUES (@fecha_desde, @fecha_fin, @hora_inicio, @hora_fin, @cod_actividad);

        SET @cod_dictado = SCOPE_IDENTITY();

        INSERT INTO DICTADO_DIA (cod_dictado, dia_semana)
        VALUES (@cod_dictado, @dia_semana);

        INSERT INTO A_CARGO_DE (cod_dictado, dni)
        VALUES (@cod_dictado, @dni);

        INSERT INTO SE_DESARROLLA_EN (cod_dictado, cod_area)
        VALUES (@cod_dictado, @cod_area);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
