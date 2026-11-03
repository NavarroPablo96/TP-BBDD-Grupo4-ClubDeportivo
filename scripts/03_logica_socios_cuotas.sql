USE ClubDeportivo;
GO

-- Triggers, procedimientos almacenados y vistas de socios y cuotas sociales.
-- Se pueden volver a crear con CREATE OR ALTER.


-- TR_INSCRIPCION_CATEGORIA_HABILITADA
-- §4.2: un socio sólo puede inscribirse en una actividad habilitada para su categoría.
CREATE OR ALTER TRIGGER TR_INSCRIPCION_CATEGORIA_HABILITADA
ON INSCRIPCION
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN SOCIO s
            ON s.nro_socio_base = i.nro_socio_base
           AND s.nro_orden = i.nro_orden
        WHERE NOT EXISTS (
            SELECT 1
            FROM HABILITADA_PARA h
            WHERE h.cod_actividad = i.cod_actividad
              AND h.nombre_categoria = s.nombre_categoria
        )
    )
    BEGIN
        THROW 50001, 'El socio no puede inscribirse: la actividad no está habilitada para su categoría.', 1;
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

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT fecha_desde,
                   fecha_hasta,
                   LEAD(fecha_desde) OVER (ORDER BY fecha_desde) AS siguiente_desde
            FROM VALOR_CUOTA_SOCIAL
        ) periodos
        WHERE (siguiente_desde IS NOT NULL
               AND (fecha_hasta IS NULL OR fecha_hasta <> DATEADD(DAY, -1, siguiente_desde)))
    )
    BEGIN
        THROW 50002, 'Los períodos de VALOR_CUOTA_SOCIAL se superponen o dejan huecos.', 1;
    END;
END;
GO


-- TR_SOCIO_TITULAR_CATEGORIA
-- §4.2: el titular de un grupo no puede pertenecer a la categoría infantiles.
-- TODO: el nombre de la categoría ('Infantil') sigue los datos actuales; §4.2 dice 'infantiles'. Ver pendientes_diseno.md TODO 6.
CREATE OR ALTER TRIGGER TR_SOCIO_TITULAR_CATEGORIA
ON SOCIO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE nro_orden = 0
          AND nombre_categoria = 'Infantil'
    )
    BEGIN
        THROW 50003, 'El titular de un grupo familiar no puede pertenecer a la categoría Infantil.', 1;
    END;
END;
GO
-- TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA
-- §4.2: Sólo generan cuota de arancel las inscripciones a actividades aranceladas
CREATE OR ALTER TRIGGER TR_CUOTA_ARANCEL_ACTIVIDAD_ARANCELADA
ON CUOTA_ARANCEL
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM ACTIVIDAD_ARANCELADA a
            WHERE a.cod_actividad = i.cod_actividad
        )
    )
    BEGIN
        THROW 50004, 'Solo las inscripciones a actividades aranceladas generan cuotas de arancel.', 1;
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
        WHERE NOT EXISTS (
            SELECT 1
            FROM CUOTA_SOCIAL cs
            WHERE cs.nro_socio_base = s.nro_socio_base
              AND cs.anio = @anio
              AND cs.mes = @mes
        )
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


-- SP_CONSULTA_TITULARES_DEUDA
-- Consulta 1 del enunciado: titulares de grupos con cuotas sociales adeudadas del año indicado,
-- con el importe total adeudado y la cantidad de integrantes del grupo.
-- La deuda no se almacena: es monto_a_pagar - monto_abonado (§4.2).
CREATE OR ALTER PROCEDURE SP_CONSULTA_TITULARES_DEUDA
    @anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.nro_socio_base,
       t.nombre AS nombre_titular,
       deuda.importe_adeudado,
       integrantes.cantidad_integrantes
FROM (
    SELECT nro_socio_base,
           SUM(monto_a_pagar - ISNULL(monto_abonado, 0)) AS importe_adeudado
    FROM CUOTA_SOCIAL
    WHERE anio = @anio
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
END;
GO


-- SP_CONSULTA_SOCIOS_GRATUITAS
-- Consulta 2 del enunciado: cantidad de socios por categoría inscriptos en todas las
-- actividades gratuitas durante el año indicado (año anterior al que se consulta).
-- Supuesto: si no hay actividades gratuitas, nadie cumple (el INNER JOIN deja el conjunto vacío).
CREATE OR ALTER PROCEDURE SP_CONSULTA_SOCIOS_GRATUITAS
    @anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.nombre_categoria,
       COUNT(q.nro_socio_base) AS cantidad_socios
FROM CATEGORIA c
LEFT JOIN (
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
        WHERE YEAR(i.fecha_inscripcion) = @anio
        GROUP BY i.nro_socio_base, i.nro_orden
        HAVING COUNT(DISTINCT i.cod_actividad) = (SELECT COUNT(*) FROM ACTIVIDAD_GRATUITA)
    ) todas
        ON todas.nro_socio_base = s.nro_socio_base
       AND todas.nro_orden = s.nro_orden
) q
    ON q.nombre_categoria = c.nombre_categoria
GROUP BY c.nombre_categoria;
END;
GO
