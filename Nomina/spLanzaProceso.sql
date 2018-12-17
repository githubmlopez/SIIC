USE [ADNOMINA01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spLanzaProceso')
BEGIN
  DROP  PROCEDURE spLanzaProceso
END
GO
-- EXEC spLanzaProceso 'MON1',1,1,'CU','NOMINA','MARIO','201803','S','spGenProcNomina'
CREATE PROCEDURE spLanzaProceso
(
@pCveMonitor    varchar(10),
@pIdProceso     numeric(9,0),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pCodigoUsuario varchar(10),
@pAnoPeriodo    varchar(6),
@pCveTipoNomina varchar(2),
@pStoreProc     varchar(50)
)
AS
BEGIN
--  SELECT 'ENTRO A LANZA PROCESO'
  DECLARE  @k_error      varchar(1) = 'E',
           @k_warning    varchar(1) = 'W',
           @k_abierto    varchar(1) = 'A'

  DECLARE  @error        varchar(80),
           @msg_error    varchar(400),
		   @id_tarea     numeric(9),
		   @sql          nvarchar(max),
		   @parametros   nvarchar(max),
		   @sit_periodo  varchar(1)
 
  SET      @error      =  ' '
  SET      @msg_error  =  ' '
  SET      @id_tarea   =  0

  EXEC  spCreaTarea
  @pIdProceso,
  @pCodigoUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pAnoPeriodo,
  @id_tarea OUT,
  @error OUT,
  @msg_error OUT 

  SET @sit_periodo  = ' '

  IF EXISTS (SELECT 1 FROM NO_PERIODO  WHERE 
                           ID_CLIENTE      =  @pIdCliente     AND
					       CVE_EMPRESA     =  @pCveEmpresa    AND
						   CVE_TIPO_NOMINA =  @pCveTipoNomina AND
						   ANO_PERIODO     =  @pAnoPeriodo)
  BEGIN
    SELECT @sit_periodo = SIT_PERIODO FROM NO_PERIODO  WHERE 
                                           ID_CLIENTE      =  @pIdCliente     AND
				                 	       CVE_EMPRESA     =  @pCveEmpresa    AND
						                   CVE_TIPO_NOMINA =  @pCveTipoNomina AND
						                   ANO_PERIODO     =  @pAnoPeriodo
  END

  IF  @sit_periodo  =  @k_abierto   
  BEGIN

    SET @sql = N'EXEC ' + @pStoreProc +  
    N' @IdProceso_p, @IdTarea_p, @CodigoUsuario_p, @IdCliente_p,' +
    N'@CveEmpresa_p, @CveAplicacion_p, @CveTipoNomina_p, @AnoPeriodo_p,' +
	N'@error_p OUTPUT, @msg_error_p OUTPUT'    
    SET @parametros =
    N' @IdProceso_p numeric(9,0), @IdTarea_p numeric(9,0), @CodigoUsuario_p varchar(20), @IdCliente_p int,' +
    N'@CveEmpresa_p varchar(4), @CveAplicacion_p varchar(10), @CveTipoNomina_p varchar(2),' +
	N'@AnoPeriodo_p varchar(6), @error_p varchar(80) OUT, @msg_error_p varchar(400) OUT'
 
--  SELECT ' sql==> ' + @sql
--	SELECT ' par==> ' + @parametros

    EXEC sp_executesql @sql, @parametros,
    @IdProceso_p      = @pIdProceso,
	@IdTarea_p        = @id_tarea,
	@CodigoUsuario_p  = @pCodigoUsuario,
	@IdCliente_p      = @pIdCliente,
    @CveEmpresa_p     = @pCveEmpresa,
    @CveAplicacion_p  = @pCveAplicacion,
	@CveTipoNomina_p  = @pCveTipoNomina,
    @AnoPeriodo_p     = @pAnoPeriodo,
    @error_p          = @error OUTPUT, 
    @msg_error_p      = @msg_error OUTPUT;

    EXEC  spActPctTarea 
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pIdProceso,
    @id_tarea, 
    100

    UPDATE FC_GEN_TAREA  SET HORA_FINAL =  CONVERT(varchar(10), GETDATE(), 108)  WHERE
           ID_PROCESO  =  @pIdProceso  AND  ID_TAREA  = @id_tarea

--    SELECT 'ERROR *' + @error
--    SELECT 'MSG *' + @msg_error
  END
  ELSE
  BEGIN
    SET  @error    =  'Periodo no existe, cerrado o no existe periodo ISR'
    SET  @msg_error =  LTRIM(@error + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento 
    @pIdProceso,
    @id_tarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_warning,
    @error,
    @msg_error
  END
END

