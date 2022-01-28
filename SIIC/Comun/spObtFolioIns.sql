USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtFolioIns')
BEGIN
  DROP  PROCEDURE spObtFolioIns
END
GO
------------------------------------------------------------------------------------------------
/* Proceso que obtiene folio de la nueva instancia                                            */
------------------------------------------------------------------------------------------------
--EXEC spObtFolioIns 1,'EGG',1,0
CREATE PROCEDURE [dbo].[spObtFolioIns]
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pIdProceso       numeric(9),
  @pFolioExe        int OUT
)
AS
BEGIN
  UPDATE FC_PROCESO SET FOLIO_EXEC = FOLIO_EXEC + 1  WHERE CVE_EMPRESA =  @pCveEmpresa AND ID_PROCESO = @pIdProceso
  SET  @pFolioExe  =  (SELECT FOLIO_EXEC FROM FC_PROCESO  WHERE CVE_EMPRESA =  @pCveEmpresa AND ID_PROCESO = @pIdProceso)
END
