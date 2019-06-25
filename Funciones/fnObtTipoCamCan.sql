USE ADMON01
GO

ALTER FUNCTION fnObtTipoCamCan 
(@pCveEmpresa varchar (4), @pAnoMes varchar(6))
RETURNS numeric(8,4)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  RETURN
  (SELECT TIPO_CAM_F_MES FROM CI_PERIODO_CONTA WHERE CVE_EMPRESA = @pCveEmpresa AND
  ANO_MES = dbo.fnObtAnoMesAnt(@pAnoMes))

END

