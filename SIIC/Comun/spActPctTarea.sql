USE [ADNOMINA01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spActPctTarea')
BEGIN
  DROP  PROCEDURE spActPctTarea
END
GO
-- EXEC spLanzaProceso 1,1,1,'CU','NOMINA','S','201801',1,0,0,0,' ',' '
CREATE PROCEDURE spActPctTarea
@pIdCliente int,
@pCveEmpresa varchar(4),
@pCveAplicacion varchar(10),
@pIdProceso numeric(9,0),
@pIdTarea numeric(9,0), 
@pAvance int
AS
BEGIN
  UPDATE FC_GEN_TAREA SET PCT_AVANCE = @pAvance  WHERE 
  ID_CLIENTE     = @pIdCliente     AND
  CVE_EMPRESA    = @pCveEmpresa    AND
  CVE_APLICACION = @pCveAplicacion AND
  ID_PROCESO     = @pIdProceso     AND
  ID_TAREA       = @pIdTarea
 
END




