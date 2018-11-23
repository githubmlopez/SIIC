USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
--EXEC spProcesaIndicador 'CU','MLOPEZ','201804',42,1134, ' ', ' '
--DROP PROCEDURE spProcesaIndicador
ALTER PROCEDURE [dbo].[spProcesaIndicador] @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT

AS
BEGIN
  
  DECLARE  @k_verdadero        bit         =  1,
           @k_falso            bit         =  0,
		   @k_chequera         varchar(2)  =  'CH',
		   @k_activo           varchar(1)  =  'A',
		   @k_error            varchar(1)  =  'E',
		   @k_no_actualiza     int         =  99999

  DECLARE  @imp_ind_pivote     numeric(16,2) = 0,
           @imp_ind_cuenta     numeric(16,2) = 0,
		   @cve_tipo_indicador varchar(2),
		   @cve_indicador      varchar(10)

  
  SELECT  @cve_indicador =  CVE_INDICADOR, @cve_tipo_indicador = CVE_TIPO_INDICADOR  FROM  CI_INDICADOR	WHERE
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso

--  SELECT 'SL PROCESANDO ' + CONVERT(VARCHAR(10), @pIdProceso ) + ' ' + @cve_indicador + ' ' + @cve_tipo_indicador

  SET  @imp_ind_pivote  =  @k_no_actualiza

  IF  @cve_tipo_indicador  =  @k_chequera
  BEGIN
    SET  @imp_ind_pivote = 0
    EXEC spCalIndChequera  @pCveEmpresa, @pAnoMes, @cve_indicador, @imp_ind_pivote OUTPUT
    SET  @imp_ind_pivote  =  ISNULL(@imp_ind_pivote,0)
  END

	--IF  @cve_indicador = 'EGR756' 
	--BEGIN
 --     SELECT 'CALL ' +  @pCveEmpresa + @pAnoMes + @cve_indicador
	--END
 
  EXEC spCalIndCuenta @pCveEmpresa, @pAnoMes, @cve_indicador, @imp_ind_cuenta OUTPUT
  SET @imp_ind_cuenta  =  ISNULL(@imp_ind_cuenta,0)
--  SELECT ' RECALL ' + CONVERT(VARCHAR(16), @imp_ind_cuenta)

  
  BEGIN  TRY
    IF EXISTS(SELECT 1 FROM CI_INDICA_PERIODO WHERE CVE_EMPRESA = @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
	          CVE_INDICADOR  =  @cve_indicador)  AND  @cve_tipo_indicador  =  @k_chequera
    BEGIN
      DELETE  CI_INDICA_PERIODO WHERE CVE_EMPRESA = @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
	          CVE_INDICADOR  =  @cve_indicador
	END
--	SELECT ' INDICADOR ' + @cve_indicador
	--IF  @cve_indicador = 'EGR756'
	--BEGIN
 --     SELECT 'PI ' + CONVERT(VARCHAR(16),@imp_ind_pivote) + ' CTA ' +  CONVERT(VARCHAR(16), @imp_ind_cuenta)
	--END
--    SELECT 'PI ' + CONVERT(VARCHAR(16),@imp_ind_pivote) + ' CTA ' +  CONVERT(VARCHAR(16), @imp_ind_cuenta)
    EXEC  spInsIndicador  @pCveEmpresa, @pAnoMes, @cve_indicador,
                          @imp_ind_pivote,  @imp_ind_cuenta

  END  TRY

  BEGIN CATCH
    SET  @pError    =  'Error de Ejecucion Indicadores'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
END