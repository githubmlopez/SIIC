USE ADMON01
GO

ALTER FUNCTION fnObtTipoCambC 
(@pCveEmpresa varchar(4),
 @pAnoMes     varchar(6),
 @pFOperacion date)
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
    SELECT @tipo_cambio = TIPO_CAM_F_MES FROM CI_PERIODO_CONTA WHERE 
	       CVE_EMPRESA  =  @pCveEmpresa  AND
		   ANO_MES      =  @ano_mes_ant 
  END
  ELSE
  BEGIN
    IF @cve_valua =  @k_val_prom
    BEGIN
      SELECT @tipo_cambio = TIPO_CAMB_PROM FROM CI_PERIODO_CONTA WHERE 
	       CVE_EMPRESA  =  @pCveEmpresa  AND
		   ANO_MES      =  @ano_mes_ant 
    END
    ELSE
	BEGIN
      IF @cve_valua =  @k_val_oper
      BEGIN
        SELECT @tipo_cambio =  TIPO_CAMBIO FROM CI_TIPO_CAMBIO
		WHERE F_OPERACION = @pFOperacion
      END
      ELSE
	  BEGIN
        SET @tipo_cambio = 0
	  END

	END

  END

  RETURN @tipo_cambio
END

