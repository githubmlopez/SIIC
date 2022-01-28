USE [ADMON01]
GO

-- EXEC spCargaDir 1,1,'MARIO',1,'CU','DOCTOS','C:\TEMP2018\Doctos',' ',' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaDir')
BEGIN
  DROP  PROCEDURE spCargaDir
END
GO

CREATE PROCEDURE [dbo].[spCargaDir]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pPatCalc       varchar (100),
@pExtension     varchar (10),
@pError         varchar (80) OUT,
@pMsgError      varchar (400) OUT
)

AS
BEGIN
  DECLARE  @CMD          varchar(512)
  
  IF OBJECT_ID('tempdb..#FILEP') IS NULL
  BEGIN
    CREATE TABLE #FILEP 
   (Rowfile     varchar(max))
  END
 
  SET @CMD = LTRIM('DIR ' + @pPatCalc)
--  SELECT @CMD --*
-- Almacenar resultado del comando 
  INSERT INTO #FILEP  
  EXEC MASTER..xp_cmdshell   @CMD 
 -- SELECT * FROM #FILEP
--  Depuración de archivo 
--  SELECT * FROM  #FILEP 
  DELETE 
  FROM   #FILEP 
  WHERE  Rowfile NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %' 
  OR Rowfile LIKE '%<DIR>%' 
  OR Rowfile NOT LIKE '%' + @pExtension + '%' 
  OR Rowfile is null

--  SELECT * FROM #FILEP

  UPDATE #FILEP SET Rowfile =
  SUBSTRING(Rowfile, (LEN(Rowfile) - CHARINDEX(' ',REVERSE(Rowfile)) + 1) + 1, LEN(Rowfile))
--  SELECT * FROM #FILEP
END

