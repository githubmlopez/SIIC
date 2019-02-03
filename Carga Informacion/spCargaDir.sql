USE [CARGADOR]
GO

-- EXEC spCargaDir 1,1,'MARIO',1,'CU','DOCTOS','C:\TEMP2018\Doctos',' ',' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCargaDir')
BEGIN
  DROP  PROCEDURE spCargaDir
END
GO

CREATE PROCEDURE [dbo].[spCargaDir]
(
@pIdProceso       numeric (9),
@pIdTarea         numeric (9),
@pCodigoUsuario   varchar (20),
@pIdCliente       int,
@pCveEmpresa      varchar (4),
@pCveAplicacion   varchar (10),
@pPatCalc         varchar (50),
@pError           varchar (80) OUT,
@pMsgError        varchar (400) OUT
)

AS
BEGIN
  DECLARE  @CMD          varchar(512)
  
  IF OBJECT_ID('tempdb..#FILEP') IS NULL
  BEGIN
    CREATE TABLE #FILEP 
   (Rowfile     varchar(max))
  END
 
  SET @CMD = 'DIR ' + @pPatCalc
--  SELECT @CMD
-- Almacenar resultado del comando 
  INSERT INTO #FILEP  
  EXEC MASTER..xp_cmdshell   @CMD 
--  SELECT * FROM #FILEP
--  Depuración de archivo 
  DELETE 
  FROM   #FILEP 
  WHERE  Rowfile NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %' 
  OR Rowfile LIKE '%<DIR>%' 
  OR Rowfile NOT LIKE '%pdf%' 
  OR Rowfile NOT LIKE '%' + @pCveEmpresa + '%' 
  OR Rowfile is null

  UPDATE #FILEP SET Rowfile =
  SUBSTRING(Rowfile,CHARINDEX(@pCveEmpresa,Rowfile),LEN(Rowfile))
  UPDATE #FILEP SET Rowfile =
  SUBSTRING(Rowfile,1,CHARINDEX('.pdf',Rowfile) - 1)

--  SELECT * FROM #FILEP
END

