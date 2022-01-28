USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spRegFinProceso')
BEGIN
  DROP  PROCEDURE spRegFinProceso
END
GO
-- EXEC spLanzaProcCont 2,'EGG','MARIO','SIIC','201812',202,0,1,0,' ', ' ', 0,' ',' '  
CREATE OR ALTER PROCEDURE [dbo].[spRegFinProceso]
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pCodigoUsuario   varchar(20),
  @pCveAplicacion   varchar(10),
  @pAnoPeriodo      varchar(6),
  @pIdProceso       numeric(9),
  @pIdTarea         numeric(9),
  @pFolioExe        int,
  @pHraFin          varchar(10)  OUT,
  @pBError          bit          OUT,
  @pError           varchar(80)  OUT,
  @pMsgError        varchar(400) OUT
)
AS
BEGIN
  
  DECLARE @k_verdadero  bit        = 1,
          @k_falso      bit        = 0,
		  @k_Error      varchar(1) = 'E'

  DECLARE @hora_fin     varchar(10)

  SET  @hora_fin  =  CONVERT(varchar(10), GETDATE(), 108)

  BEGIN TRY

  EXEC  spActPctTarea @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, 100

  UPDATE FC_PROC_EXEC
         SET   H_FIN        = @hora_fin
         WHERE CVE_EMPRESA  = @pCveEmpresa
         AND   ID_PROCESO   = @pIdProceso
         AND   FOLIO_EXEC   = @pFolioExe
  END TRY

  BEGIN CATCH
    SET @pError    =  '(E) Finaliza Proceso : ' + CONVERT(VARCHAR(9), @pIdProceso)
    SET @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET  @pBError  =  @k_verdadero
  END CATCH
END
