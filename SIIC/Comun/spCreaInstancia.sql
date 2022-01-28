USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCreaInstancia')
BEGIN
  DROP  PROCEDURE spCreaInstancia
END
GO
-- EXEC spCreaInstancia 2,'EGG','MARIO','SIIC','201812',1,0,0,0,' ', ' ', 0,' ',' '  
------------------------------------------------------------------------------------------------
/* Proceso que la infraestructura para la creación de la instancia de ejecución de un proceso */
------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[spCreaInstancia]
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pCodigoUsuario   varchar(20),
  @pCveAplicacion   varchar(10),
  @pAnoPeriodo      varchar(6),
  @pIdProceso       numeric(9),
  @pIdTarea         numeric(9) OUT,
  @pFolioExe        int OUT,
  @pBFolioExe       bit,
  @pHoraInicio      varchar(10)  OUT,
  @pHoraFin         varchar(10)  OUT,
  @pBError          bit          OUT,
  @pError           varchar(80)  OUT,
  @pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @k_verdadero  bit        = 1,
          @k_falso      bit        = 0,
          @k_error      varchar(1) = 'E'

  DECLARE @error        varchar(80),
          @store_proc   varchar(50)

  SET @error       =  ' '
  
  BEGIN TRY
    IF  @pBFolioExe  =  @k_falso
	BEGIN
      EXEC spObtFolioIns @pIdCliente, @pCveEmpresa, @pIdProceso, @pFolioExe OUT
	END

    SET  @pHoraInicio  =  CONVERT(varchar(10), GETDATE(), 108)
	
	EXEC  spCreaProcExe  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe, 
                         @pBError OUT, @pError  OUT, @pMsgError OUT 

    IF  @pBError =  @k_verdadero
    BEGIN
      RETURN
    END

    SELECT @store_proc = STORE_PROCEDURE
    FROM  FC_PROCESO
    WHERE CVE_EMPRESA  = @pCveEmpresa
    AND   ID_PROCESO   = @pIdProceso
    EXEC  spCreaTarea   @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe, @k_verdadero,
                        @store_proc, @pIdTarea OUT, @pBError OUT, @pError OUT, @pMsgError OUT 
 
    IF  @pBError =  @k_verdadero
    BEGIN
      RETURN
    END

  END TRY

  BEGIN CATCH
    SET @pError    =  '(E) Creación de instancia '
    SET @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
	IF EXISTS (SELECT 1
               FROM  FC_TAREA
               WHERE CVE_EMPRESA = @pCveEmpresa
               AND   ID_PROCESO  = @pIdProceso
               AND   FOLIO_EXEC  = @pFolioExe
               AND   ID_TAREA    = @pIdTarea)
    BEGIN
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    END

	SET  @pBError  =  @k_verdadero

  END CATCH
END
