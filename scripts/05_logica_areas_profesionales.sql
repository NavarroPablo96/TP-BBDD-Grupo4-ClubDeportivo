-- TR_A_CARGO_DE_PROF_HABILITADO
-- §4.2: Todo profesional a cargo de un dictado debe poder desempeñarse en la actividad de ese dictado.

CREATE OR ALTER TRIGGER TR_A_CARGO_DE_PROF_HABILITADO
ON A_CARGO_DE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN DICTADO d 
            ON d.cod_dictado = i.cod_dictado
        WHERE NOT EXISTS (
            SELECT 1
            FROM PUEDE_DESEMPENIARSE_EN p
            WHERE p.dni = i.dni
              AND p.cod_actividad = d.cod_actividad
        )
    )
    BEGIN
        THROW 50002, 'El profesional no está habilitado para la actividad del dictado.', 1;
    END;
END;
GO
-- TR_SE_DESARROLLA_EN_AREA_APTA
-- §4.2: Toda área en la que se desarrolla un dictado debe ser apta para la actividad de ese dictado
CREATE OR ALTER TRIGGER TR_SE_DESARROLLA_EN_AREA_APTA
ON SE_DESARROLLA_EN
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN DICTADO d 
            ON d.cod_dictado = i.cod_dictado
        WHERE NOT EXISTS (
            SELECT 1
            FROM APTA_PARA a
            WHERE a.cod_area = i.cod_area
              AND a.cod_actividad = d.cod_actividad
        )
    )
    BEGIN
        THROW 50003, 'El área asignada no es apta para la actividad del dictado.', 1;
    END;
END;
GO
