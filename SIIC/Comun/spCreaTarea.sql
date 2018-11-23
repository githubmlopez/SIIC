USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--EXEC spCreaTarea 1,'CU','MARIO',0, ' ',' '
ALTER PROCEDURE spCreaTarea  @pIdProceso numeric(9), @pCveEmpresa varchar(4), @pCodigoUsuario varchar(20), @pAnoMes varchar(6),
                             @pIdTarea numeric(9) OUT, @pError varchar(80) OUT, @pMsgError varchar(400) OUT 
AS
BEGIN
  
  DECLARE
  @k_id_tarea          varchar(10),
  @k_iniciando         varchar(1),
  @k_error             varchar(80)

  SET  @k_id_tarea  =  'TARE'
  SET  @k_iniciando =  'I'
  SET  @k_error     =  'E'
 
  SET  @pError      =  ' '
  SET  @pMsgError   =  ' '
      
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_tarea
  SET  @pIdtarea  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_tarea)   

--  select ' El folio es ==> ' + CONVERT(varchar(10), @pIdtarea)

  BEGIN TRY 

    INSERT  INTO FC_GEN_TAREA  
   (CVE_EMPRESA,
    ID_PROCESO,
    ID_TAREA,
	F_OPERACION,
    HORA_INICIO,
	HORA_FINAL,
	SIT_TAREA,
    PCT_AVANCE,
    CODIGO_USUARIO,
	ANO_MES_PROC,
	NUM_REGISTROS) VALUES
   (@pCveEmpresa,
    @pIdProceso,
    @pIdtarea,
	GETDATE(),
    CONVERT(varchar(10), GETDATE(), 108),
    NULL,
	@k_iniciando,
	0,
    @pCodigoUsuario,
	@pAnoMes,
	0)

 --   select ' Salgo de Insertar '
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error al insertar Tarea'
	SET  @pMsgError =  @pError + '==> ' + ERROR_MESSAGE()
    SELECT @pError + ' ' + @pMsgError

--	EXECUTE spCreaTareaEvento @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
END
