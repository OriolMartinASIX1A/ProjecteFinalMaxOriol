-- Version: 1.0
-- cibernova_portal.sql - Base de datos del Portal CiberNova (intranet de incidencias de Sistemas). 27/11/2026 - Max.
-- Se ejecuta UNA vez contra la VIP (siempre es la replica principal del AG):
--   sqlcmd -S 192.168.202.27 -U sa -C -i /tmp/cibernova_portal.sql
-- Pasos: crear la BD, recuperacion completa y copia completa (obligatorias para entrar en un AG),
-- tabla, usuario de la web con permisos minimos y alta en el AG (seeding automatico a la secundaria).
IF DB_ID(N'cibernova_portal') IS NULL CREATE DATABASE cibernova_portal;
GO
ALTER DATABASE cibernova_portal SET RECOVERY FULL;
GO
USE cibernova_portal;
IF OBJECT_ID(N'dbo.incidencias') IS NULL
CREATE TABLE dbo.incidencias (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    titulo      NVARCHAR(150)  NOT NULL,
    descripcion NVARCHAR(2000) NULL,
    sede        NVARCHAR(20)   NOT NULL CHECK (sede IN (N'Barcelona', N'Madrid', N'Valencia')),
    prioridad   NVARCHAR(10)   NOT NULL CHECK (prioridad IN (N'Baja', N'Media', N'Alta')),
    estado      NVARCHAR(10)   NOT NULL DEFAULT N'Abierta' CHECK (estado IN (N'Abierta', N'Cerrada')),
    creada      DATETIME2(0)   NOT NULL DEFAULT SYSDATETIME(),
    cerrada     DATETIME2(0)   NULL,
    servidor_bd NVARCHAR(128)  NOT NULL,   -- replica principal que guardo la fila (@@SERVERNAME)
    nodo_web    NVARCHAR(64)   NOT NULL    -- nodo Apache que atendio la peticion
);
GO
-- Minimo privilegio: la web solo lee, crea y cierra incidencias (sin DELETE ni cambios de esquema).
IF USER_ID(N'web_cibernova') IS NULL CREATE USER web_cibernova FOR LOGIN web_cibernova;
GRANT SELECT, INSERT, UPDATE ON dbo.incidencias TO web_cibernova;
GO
BACKUP DATABASE cibernova_portal TO DISK = N'/var/opt/mssql/backup/cibernova_portal_inicial.bak' WITH INIT, CHECKSUM;
GO
USE master;
ALTER AVAILABILITY GROUP [sqlag_cibernova] ADD DATABASE [cibernova_portal];
GO
