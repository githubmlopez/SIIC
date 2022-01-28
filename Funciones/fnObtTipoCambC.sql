USE ADMON01
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtTipoCambC')
BEGIN
  DROP  FUNCTION fnObtTipoCambC
END
GO

CREATE FUNCTION fnObtTipoCambC 
(@pCveEmpresa varchar(4),
 @pAnoMes     varchar(6),
 @pFOperacion date,
 @pCveMoneda  varchar(1)
)
RETURNS numeric(8,4)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @k_verdadero    varchar(1)  = 'V',
          @k_val_cierre   varchar(1)  = 'C',
		  @k_val_prom     varchar(1)  = 'P',
		  @k_val_oper     varchar(1)  = 'O' 
 
  DECLARE @tipo_cambio    numeric(8,4),
          @cve_valua      varchar(1),
		  @ano_mes_ant    varchar(6)

  SET @ano_mes_ant = dbo.fnObtAnoMesAnt(@pAnoMes)

  SELECT  @cve_valua = CVE_TIPO_VAL
  FROM  CI_PERIODO_CONTA
  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES = @pAnoMes 

  IF @cve_valua =  @k_val_cierre
  BEGIN
    SELECT @tipo_cambio =  TIPO_CAMB_F_MES FROM CI_PER_TIPO_CAMB WHERE 
	       CVE_EMPRESA  =  @pCveEmpresa  AND
		   ANO_MES      =  @ano_mes_ant  AND
		   CVE_MONEDA   =  @pCveMoneda
  END
  ELSE
  BEGIN
    IF @cve_valua =  @k_val_prom
    BEGIN
      SELECT @tipo_cambio = TIPO_CAMB_PROM FROM CI_PER_TIPO_CAMB WHERE 
	       CVE_EMPRESA  =  @pCveEmpresa  AND
		   ANO_MES      =  @ano_mes_ant  AND
		   CVE_MONEDA   =  @pCveMoneda
    END
    ELSE
	BEGIN
      IF @cve_valua =  @k_val_oper
      BEGIN
        SELECT @tipo_cambio =  TIPO_CAMBIO FROM CI_TIPO_CAMBIO
		WHERE CVE_EMPRESA = @pCveEmpresa  AND  CVE_MONEDA = @pCveMoneda AND F_OPERACION = @pFOperacion
      END
      ELSE
	  BEGIN
        SET @tipo_cambio = 0
	  END

	END

  END

  RETURN @tipo_cambio
END

