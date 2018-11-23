USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--ERROR_NUMBER() AS ErrorNumber,  
--ERROR_SEVERITY() AS ErrorSeverity,  
--ERROR_STATE() AS ErrorState,  
--ERROR_PROCEDURE() AS ErrorProcedure,  
--ERROR_LINE() AS ErrorLine,  
--ERROR_MESSAGE() AS ErrorMessage;  

CREATE PROCEDURE spCreaTareaEvento @pCveEmpresa varchar(4), @pIdProceso numeric(9), @pIdTarea numeric(9), @pTipoEvento varchar(1),
                                   @pError varchar(80), @pMsgError varchar(400) 
AS
BEGIN
  
  DECLARE
  @k_id_evento   varchar(4)

  DECLARE 
  @id_evento           int

  SET  @k_id_evento   =  'EVEN'
    
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_evento
  SET  @id_evento  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_evento)   

  BEGIN TRY

    INSERT  INTO FC_GEN_TAREA_EVENTO  
   (CVE_EMPRESA,
    ID_PROCESO,
    ID_TAREA,
    ID_EVENTO,
    CVE_TIPO_EVENTO,
    DESC_ERROR,
    MSG_ERROR) VALUES
   (@pCveEmpresa,
    @pIdProceso,
    @pIdTarea,
    @id_evento,
    @pTipoEvento,
    @pError,
    @pMsgError)
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error al insertar Tarea Evento ' + ISNULL(ERROR_PROCEDURE(), ' ')
	SET  @pMsgError =  @pError + '==> ' + ISNULL(ERROR_MESSAGE(),' ')
--    EXEC spGrabaLog @pCveEmpresa, @pMsgError
    RAISERROR (@pMsgError, 16, 1)
    RETURN 1
  END CATCH

  IF xact_state() <> 0
  BEGIN
	ROLLBACK TRANSACTION 
  END
  --EXEC spGrabaLog @pCveEmpresa, @pMsgError
END