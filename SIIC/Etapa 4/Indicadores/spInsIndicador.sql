USE ADMON01
GO

ALTER PROCEDURE [dbo].[spInsIndicador]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pCveIndicador varchar(10),
                                         @pImpPivote numeric(16,2), @pImpSecundario numeric(16,2) 
AS
BEGIN
  DECLARE  @k_activo    varchar(1)    = 'A',
           @k_no_act    numeric (9,0) = 99999

  IF NOT EXISTS(SELECT 1 FROM CI_INDICA_PERIODO WHERE
                CVE_EMPRESA   = @pCveEmpresa        AND
				ANO_MES       =  @pAnoMes  AND
	            CVE_INDICADOR =  @pCveIndicador)  
  BEGIN
    IF  @pImpPivote  =  @k_no_act
	BEGIN
	  SET  @pImpPivote = 0
	END
    IF  @pImpSecundario  =  @k_no_act
    BEGIN
	  SET  @pImpSecundario = 0
	END

	INSERT INTO CI_INDICA_PERIODO 
    (
    CVE_EMPRESA,
    ANO_MES,
    CVE_INDICADOR,
    IMP_PIVOTE,
    IMP_SECUNDARIO
    ) 
	VALUES
	(
	@pCveEmpresa,
	@pAnoMes,
	@pCveIndicador,
	@pImpPivote,
	@pImpSecundario
	)
  END
  ELSE
  BEGIN
    IF  @pImpPivote  <>  @k_no_act
	BEGIN
      UPDATE CI_INDICA_PERIODO SET  IMP_PIVOTE  =  @pImpPivote
      WHERE  CVE_EMPRESA    =  @pCveEmpresa  AND
	         ANO_MES        =  @pAnoMes  AND
	         CVE_INDICADOR  =  @pCveIndicador
	END
    IF  @pImpSecundario  <>  @k_no_act
    BEGIN
      UPDATE CI_INDICA_PERIODO SET  IMP_SECUNDARIO  =  @pImpSecundario
      WHERE  CVE_EMPRESA    =  @pCveEmpresa  AND
             ANO_MES        =  @pAnoMes  AND
	         CVE_INDICADOR  =  @pCveIndicador
	END
  END

END
