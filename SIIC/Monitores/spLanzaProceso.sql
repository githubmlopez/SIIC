USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

-- DROP PROCEDURE spLanzaTranProceso
ALTER PROCEDURE spLanzaProceso @pIdProceso numeric(9), @pCveEmpresa varchar(4), @pCveUsuario varchar(8),
                               @pAnoMes  varchar(6), @pStoreProc varchar(50)
AS
BEGIN

  DECLARE  @k_error      varchar(1) = 'E',
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

  EXEC  spCreaTarea  @pIdProceso, @pCveEmpresa, @pCveUsuario, @pAnoMes, @id_tarea OUT, 
                     @error OUT, @msg_error OUT 

  SET @sit_periodo  = ' '

  IF EXISTS (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE 
                                     CVE_EMPRESA    =  @pCveEmpresa    AND
                                     ANO_MES        =  @pAnoMes)
  BEGIN
    SELECT @sit_periodo = SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE 
                                           CVE_EMPRESA    =  @pCveEmpresa    AND
                                           ANO_MES        =  @pAnoMes
  END

  IF  @sit_periodo  =  @k_abierto  AND
      EXISTS (SELECT 1 FROM CI_PERIODO_ISR  WHERE  CVE_EMPRESA    =  @pCveEmpresa    AND
                                                   ANO_MES        =  @pAnoMes)  
  BEGIN

    SET @sql = N'EXEC ' + @pStoreProc +  
    N' @CveEmpresa_p,@CveUsuario_p,@AnoMes_p, @IdProceso_p, @id_tarea_p, @error_p OUTPUT, @msg_error_p OUTPUT'    
    SET @parametros =
    N'@CveEmpresa_p varchar(4),@CveUsuario_p varchar(8),@AnoMes_p varchar(6), @IdProceso_p numeric(9), @id_tarea_p numeric(9), @error_p varchar(80) OUT, @msg_error_p varchar(400) OUT'
 
--    SELECT ' sql==> ' + @sql

    EXEC sp_executesql @sql, @parametros,
    @CveEmpresa_p  = @pCveEmpresa,
    @CveUsuario_p  = @pCveUsuario,
    @AnoMes_p      = @pAnoMes,
    @IdProceso_p   = @pIdProceso,
    @id_tarea_p    = @id_tarea,
    @error_p       = @error OUTPUT, 
    @msg_error_p   = @msg_error OUTPUT;

    EXEC  spActPctTarea @id_tarea, 100

    UPDATE FC_GEN_TAREA  SET HORA_FINAL =  CONVERT(varchar(10), GETDATE(), 108)  WHERE
           ID_PROCESO  =  @pIdProceso  AND  ID_TAREA  = @id_tarea

--    SELECT 'ERROR *' + @error
--    SELECT 'MSG *' + @msg_error
  END
  ELSE
  BEGIN
    SET  @error    =  'Periodo Contable no existe, cerrado o no existe periodo ISR'
    SET  @msg_error =  LTRIM(@error + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @id_tarea, @k_error, @error, @msg_error
  END
END

