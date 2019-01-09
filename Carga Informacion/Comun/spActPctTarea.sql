USE [CARGADOR]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spActPctTarea')
BEGIN
  DROP  PROCEDURE spActPctTarea
END
GO
-- EXEC spActPctTarea 1,1,1,'CU','NOMINA','S','201801',1,0,0,0,' ',' '
CREATE PROCEDURE spActPctTarea
(
@pIdProceso     int,
@pIdTarea       int,
@pIdCliente     int,
@pCveEmpresa varchar(4),
@pCveAplicacion varchar(10),
@pCodigoUsuario varchar(20),
@pAvance        int,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT 
)
AS

BEGIN
  UPDATE FC_GEN_TAREA SET PCT_AVANCE = @pAvance  WHERE 
  ID_CLIENTE     = @pIdCliente     AND
  CVE_EMPRESA    = @pCveEmpresa    AND
  CVE_APLICACION = @pCveAplicacion AND
  ID_PROCESO     = @pIdProceso     AND
  ID_TAREA       = @pIdTarea
 
END




