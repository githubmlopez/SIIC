USE [MASTER]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE master
--ALTER DATABASE ADMON01 SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
--EXECUTE spRestore 'ADMON0120201106.BAK'
ALTER PROCEDURE spRestore @pNombre nvarchar(50) 
AS
BEGIN

  DECLARE  @path nvarchar(100)

  SELECT
  SERVERPROPERTY('MachineName') AS [ServerName], 
  SERVERPROPERTY('ServerName') AS [ServerInstanceName], 
  SERVERPROPERTY('InstanceName') AS [Instance], 
  SERVERPROPERTY('Edition') AS [Edition],
  SERVERPROPERTY('ProductVersion') AS [ProductVersion], 
  Left(@@Version, Charindex('-', @@version) - 2) As VersionName    

  SET @path  = LTRIM(N'D:\RESPALDOS\' + @pNombre)

  SELECT @path

  RESTORE HEADERONLY FROM DISK = @path
  RESTORE FILELISTONLY from DISK = @path
  RESTORE LABELONLY from DISK = @path

  IF CONVERT(NVARCHAR(100),(SELECT SERVERPROPERTY('MachineName'))) = 'LAPTOP-LNT1ODT6' 
  BEGIN
    SELECT ' EJECUTA RESTORE '
--    DROP DATABASE ADMON01 
    RESTORE DATABASE ADMON01 FROM DISK=  @path
    WITH FILE = 1, REPLACE,
    RECOVERY, 
    MOVE 'ADMON01' TO  N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\ADMON01.mdf',
    MOVE 'ADMON01_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\ADMON01.ldf' 
    SELECT ' TERMINO CORRECTAMENTE '
  END
  ELSE
  BEGIN
    SELECT ' EL RESTORE NO FUE EJECUTADO'
  END
END

