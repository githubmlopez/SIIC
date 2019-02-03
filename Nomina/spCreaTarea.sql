USE ADNOMINA01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCreaTarea')
BEGIN
  DROP  PROCEDURE spCreaTarea
END
GO
--EXEC spCreaTarea 1,'MARIO',1,'CU','NOMINA','201803',0,' ',' '
CREATE PROCEDURE spCreaTarea
@pIdProceso     numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(6),
@pIdTarea       numeric(9) OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT 
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
      
  UPDATE NO_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_tarea
  SET  @pIdtarea  =  (SELECT NUM_FOLIO FROM NO_FOLIO WHERE CVE_FOLIO  = @k_id_tarea)   

--  select ' El folio es ==> ' + CONVERT(varchar(10), @pIdtarea)

  BEGIN TRY 

    INSERT  INTO FC_GEN_TAREA  
   (ID_CLIENTE,
    CVE_EMPRESA,
	CVE_APLICACION,
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
   (@pIdCliente,
    @pCveEmpresa,
	@pCveAplicacion,
    @pIdProceso,
    @pIdtarea,
	GETDATE(),
    CONVERT(varchar(10), GETDATE(), 108),
    NULL,
	@k_iniciando,
	0,
    @pCodigoUsuario,
	@pAnoPeriodo,
	0)

 --   select ' Salgo de Insertar '
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error al insertar Tarea'
	SET  @pMsgError =  @pError + '==> ' + ERROR_MESSAGE()
 	EXECUTE  spCreaTareaEvento
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_error,
    @pError,
    @pMsgError

   END CATCH
END
