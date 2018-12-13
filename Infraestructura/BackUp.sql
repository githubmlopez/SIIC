USE [ADMON01PB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spBackUp 'ADMON01PB'
ALTER PROCEDURE spBackUp @pBase nvarchar(20) 

AS
BEGIN

DECLARE 
@disk    nvarchar(300),
@name    nvarchar(300),
@fecha   varchar(10)

SELECT
SERVERPROPERTY('MachineName') AS [ServerName], 
SERVERPROPERTY('ServerName') AS [ServerInstanceName], 
SERVERPROPERTY('InstanceName') AS [Instance], 
SERVERPROPERTY('Edition') AS [Edition],
SERVERPROPERTY('ProductVersion') AS [ProductVersion], 
Left(@@Version, Charindex('-', @@version) - 2) As VersionName    

SET  @fecha = CONVERT(VARCHAR,GETDATE(), 112)

SET @disk  =  'C:\RESPALDOSBDMLP\' + RTRIM(@pBase) + RTRIM(SUBSTRING(@fecha,1,10)) + '.' + 'BAK' 
SET @name  =  RTRIM(@pBase) + '-Full Database Backup'

BACKUP DATABASE [ADMON01PB] TO  DISK = @disk
WITH NOFORMAT, NOINIT,  NAME = @name, SKIP, 
NOREWIND, NOUNLOAD,  STATS = 10

RESTORE HEADERONLY FROM DISK = @disk  
RESTORE FILELISTONLY from DISK = @disk 
RESTORE LABELONLY from DISK = @disk 

END


