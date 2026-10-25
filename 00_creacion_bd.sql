-- Eliminar la base de datos si ya existe
USE master;
GO

IF DB_ID('ClubDeportivo') IS NOT NULL
BEGIN
    ALTER DATABASE ClubDeportivo
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ClubDeportivo;
END;
GO

CREATE DATABASE ClubDeportivo;
GO

USE ClubDeportivo;
GO
