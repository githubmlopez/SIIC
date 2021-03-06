USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCreaTareaEventoB]    Script Date: 18/01/2020 05:54:56 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCreaTareaEvento')
BEGIN
  DROP  PROCEDURE spCreaTareaEvento
END
GO

CREATE PROCEDURE [dbo].[spCreaTareaEvento]
@pCveEmpresa varchar(4),
@pIdProceso  numeric(9),
@pFolioExe   int,
@pIdTarea    numeric(9),
@pTipoEvento varchar(1),
@pError      varchar(80),
@pMsgError   varchar(400) 
AS
BEGIN
  
  DECLARE
  @k_id_evento   varchar(4)

  DECLARE 
  @id_evento           int


  BEGIN TRY

    SET  @k_id_evento   =  'EVEN'
    
    IF EXISTS (SELECT 1 FROM FC_TAREA WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso AND
	                                        FOLIO_EXEC  = @pFolioExe AND ID_TAREA = @pIdTarea)

    BEGIN
      UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_evento
      SET  @id_evento  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_evento)   

      INSERT  INTO FC_TAREA_EVENTO  
     (CVE_EMPRESA,
      ID_PROCESO,
	  FOLIO_EXEC,
      ID_TAREA,
      ID_EVENTO,
      CVE_TIPO_EVENTO,
      DESC_ERROR,
      MSG_ERROR,
      ERROR_NUMBER_D,
	  ERROR_SEVERITY_D,
	  ERROR_STATE_D,
	  ERROR_PROCEDURE_D,
	  ERROR_LINE_D,
	  ERROR_MESSAGE_D
) VALUES
     (@pCveEmpresa,
      @pIdProceso,
	  @pFolioExe,
      @pIdTarea,
      @id_evento,
      @pTipoEvento,
      ISNULL(@pError,'INF. CON NULL '),
      ISNULL(@pMsgError,'INF. CON NULL '),
	  ERROR_NUMBER(),  
      ERROR_SEVERITY(),  
      ERROR_STATE(),  
      ERROR_PROCEDURE(),  
      ERROR_LINE(),  
      ERROR_MESSAGE()
)
    END
	ELSE
	BEGIN
      RAISERROR ('(E) No existe Tarea',16,1) 
	END

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) Insertar Tarea Evento;' + ISNULL(ERROR_PROCEDURE(), ' ')
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--	SELECT @pMsgError
  END CATCH

 -- IF xact_state() <> 0
 -- BEGII
	--ROLLBACK TRANSACTION 
 -- END
  --EXEC spGrabaLog @pCveEmpresa, @pMsgError
END