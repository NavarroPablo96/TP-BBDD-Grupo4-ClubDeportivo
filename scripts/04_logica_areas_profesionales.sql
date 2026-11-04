USE ClubDeportivo;
GO

-- Triggers de profesionales y áreas de los dictados. Se pueden volver a crear con CREATE OR ALTER.
-- Se ejecuta después de 03 y antes de 05, porque los datos de prueba de 05 verifican su rechazo.


-- TR_A_CARGO_DE_PROF_HABILITADO
-- §4.2: todo profesional a cargo de un dictado debe poder desempeñarse en la actividad de ese dictado.
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


-- TR_SE_DESARROLLA_EN_AREA_APTA
-- §4.2: toda área en la que se desarrolla un dictado debe ser apta para la actividad de ese dictado.
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
