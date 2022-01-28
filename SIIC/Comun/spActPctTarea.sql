USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActPctTarea')
BEGIN
  DROP  PROCEDURE spActPctTarea
END
GO
-- EXEC spLanzaProceso 1,1,1,'CU','NOMINA','S','201801',1,0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spActPctTarea] @pCveEmpresa varchar(4), @pIdProceso numeric(9), @pFolio_exe int, @pIdTarea numeric(9),
                                        @pAvance int
AS
BEGIN
  UPDATE FC_TAREA SET PCT_AVANCE = @pAvance  WHERE 
  CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso AND  FOLIO_EXEC = @pFolio_exe AND ID_TAREA = @pIdTarea
END


