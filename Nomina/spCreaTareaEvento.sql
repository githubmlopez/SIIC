USE [ADNOMINA01]
GO
/****** Object:  StoredProcedure [dbo].[spCreaTareaEvento]    Script Date: 12/12/2018 10:47:27 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCreaTareaEvento')
BEGIN
  DROP  PROCEDURE spCreaTareaEvento
END
GO
-- EXEC spCreaTareaEvento 1,1,'MARIO',1,'CU','NOMINA','E','ERROR ','ERROR COMP '
CREATE PROCEDURE [dbo].[spCreaTareaEvento]
(
 @pIdProceso     numeric(9),
 @pIdTarea       numeric(9),
 @pCodigoUsuario varchar(20),
 @pIdCliente     int,
 @pCveEmpresa    varchar(4),
 @pCveAplicacion varchar(10),
 @pTipoEvento    varchar(1),
 @pError         varchar(80),
 @pMsgError      varchar(400)
 )

AS
BEGIN
  
  DECLARE
  @k_id_evento   varchar(4)  =  'EVEN',
  @k_id_tarea_d  int         =  9999999

  DECLARE 
  @id_evento           int
   
  UPDATE NO_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_evento
  SET  @id_evento  =  (SELECT NUM_FOLIO FROM NO_FOLIO WHERE
                              ID_CLIENTE  = @pIdCliente    AND
							  CVE_EMPRESA = @pCveEmpresa   AND
							  CVE_FOLIO   = @k_id_evento)  

  IF  NOT EXISTS(SELECT 1 FROM FC_GEN_TAREA WHERE
                 ID_CLIENTE     =  @pIdCliente     AND
		         CVE_EMPRESA    =  @pCveEmpresa    AND
			     CVE_APLICACION =  @pCveAplicacion AND
			     ID_PROCESO     =  @pIdProceso     AND
			     ID_TAREA       =  @pIdTarea)
  BEGIN
	SET  @pIdTarea   = @k_id_tarea_d
	SET  @pIdProceso = @k_id_tarea_d
  END

  BEGIN TRY

  INSERT  INTO FC_GEN_TAREA_EVENTO  
 (ID_CLIENTE,
  CVE_EMPRESA,
  CVE_APLICACION,
  ID_PROCESO,
  ID_TAREA,
  ID_EVENTO,
  CVE_TIPO_EVENTO,
  DESC_ERROR,
  MSG_ERROR) VALUES
 (@pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
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