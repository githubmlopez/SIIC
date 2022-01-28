USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

-- DROP PROCEDURE spLanzaTranProceso

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spLanzaProceso')
BEGIN
  DROP  PROCEDURE spLanzaProceso
END
GO

-- EXEC spLanzaProceso 1,'CU','MARIO','SIIC','202002',301,0,1,' ', ' ', 0,' ',' '  

CREATE PROCEDURE spLanzaProceso 
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pValPeriodo      bit,
@pFolioExe        int          OUT,
@pHoraInicio      varchar(10)  OUT,
@pHoraFin         varchar(10)  OUT,
@pBError          bit          OUT,
@pError           varchar(80)  OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE  @k_verdadero  bit        = 1,
           @k_falso      bit        = 0,
           @k_error      varchar(1) = 'E',
           @k_abierto    varchar(1) = 'A'

  DECLARE  @error        varchar(80),
           @msg_error    varchar(400),
		   @id_tarea     numeric(9),
		   @folio_exe    int,
		   @sql          nvarchar(max),
		   @parametros   nvarchar(max),
		   @sit_periodo  varchar(1),
		   @b_correcto   bit,
           @base_datos   varchar(20),
           @owner        varchar(20),
           @store_proc   varchar(50),
		   @b_error_int  varchar(1)
 
  SET      @error       =  ' '
  SET      @msg_error   =  ' '
  SET      @id_tarea    =  0
  SET      @b_error_int = @k_falso

  BEGIN TRY

  EXEC  spCreaProcExe  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @folio_exe OUT, 
                       @b_error_int OUT, @pError  OUT, @pMsgError OUT 

  SET  @pFolioExe = @folio_exe

  IF  @b_error_int =  @k_verdadero
  BEGIN
    SET  @pBError  =  @k_verdadero
    RETURN 
  END

  SELECT   @base_datos = BASE_DATOS, @owner = OWNER,  @store_proc = STORE_PROCEDURE FROM
  FC_PROCESO  WHERE CVE_EMPRESA = @pCveEmpresa  AND  ID_PROCESO = @pIdProceso

  EXEC  spCreaTarea  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @folio_exe, @k_verdadero,
                      @store_proc, @id_tarea OUT, @b_error_int OUT, @pError OUT, @pMsgError OUT 

  IF  @b_error_int =  @k_verdadero
  BEGIN
    SET  @pBError  =  @k_verdadero
    RETURN 
  END

  SET  @b_correcto  =  @k_verdadero

  IF  @pValPeriodo  =  @k_verdadero
  BEGIN

    SET @sit_periodo  = ' '

    IF EXISTS (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE 
                                       CVE_EMPRESA    =  @pCveEmpresa    AND
                                       ANO_MES        =  @pAnoPeriodo)
    BEGIN
      SELECT @sit_periodo = SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE 
                                             CVE_EMPRESA    =  @pCveEmpresa    AND
                                             ANO_MES        =  @pAnoPeriodo
    END
   
    IF  @sit_periodo  =  @k_abierto  AND
        EXISTS (SELECT 1 FROM CI_PERIODO_ISR  WHERE  CVE_EMPRESA    =  @pCveEmpresa    AND
                                                     ANO_MES        =  @pAnoPeriodo)  
    BEGIN
      SET @b_correcto  =  @k_falso 
    END
    ELSE
    BEGIN
      SET  @error    =  'Periodo Contable no existe, cerrado o no existe periodo ISR'
      RAISERROR(@error, 16, 1)
    END
  END

  SET  @pHoraInicio  =  CONVERT(varchar(10), GETDATE(), 108)

  IF  @b_correcto  =  @k_verdadero
  BEGIN

    SET @sql = N'EXEC ' + LTRIM(@base_datos + @owner + @store_proc) +  
    N' @pIdCliente_p,@pCveEmpresa_p,@pCodigoUsuario_p,@pCveAplicacion_p,@pAnoPeriodo_p,@pIdProceso_p, @folio_exe_p, @id_tarea_p, @b_error_p OUTPUT, @error_p OUTPUT, @msg_error_p OUTPUT'    
    SET @parametros =
    N'@pIdCliente_p int,@pCveEmpresa_p varchar(4),@pCodigoUsuario_p varchar(20),@pCveAplicacion_p varchar(10),@pAnoPeriodo_p varchar(6), @pIdProceso_p numeric(9), @folio_exe_p int,@id_tarea_p numeric(9), @b_error_p bit OUT, @error_p varchar(80) OUT, @msg_error_p varchar(400) OUT'
 
--    SELECT ' sql==> ' + @sql

    EXEC sp_executesql @sql, @parametros,
    @pIdCliente_p     = @pIdCliente,
	@pCveEmpresa_p    = @pCveEmpresa,
    @pCodigoUsuario_p = @pCodigoUsuario,
	@pCveAplicacion_p = @pCveAplicacion,
    @pAnoPeriodo_p    = @pAnoPeriodo,
    @pIdProceso_p     = @pIdProceso,
	@folio_exe_p      = @folio_exe,
    @id_tarea_p       = @id_tarea,
	@b_error_p        = @pBError OUT,
    @error_p          = @pError OUT, 
    @msg_error_p      = @pMsgError OUT;

	IF  @pBError =  @k_verdadero
	BEGIN
      RETURN 
	END
  
    EXEC  spActPctTarea @pCveEmpresa, @pIdProceso, @folio_exe, @id_tarea, 100

	SET  @pHoraFin  =  CONVERT(varchar(10), GETDATE(), 108)

    UPDATE FC_PROC_EXEC  SET H_FIN =  @pHoraFin  WHERE
           CVE_EMPRESA = @pCveEmpresa  AND ID_PROCESO  =  @pIdProceso  AND   FOLIO_EXEC = @folio_exe

  END
  
  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) Lanzar Proceso;'
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
 
    IF EXISTS (SELECT 1 FROM FC_TAREA WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso AND
	                                            FOLIO_EXEC  = @folio_exe AND ID_TAREA = @id_tarea)
    BEGIN
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @folio_exe, @id_tarea, @k_error, @pError, @pMsgError
    END
	SET  @pBError  =  @k_verdadero
  END CATCH

END

