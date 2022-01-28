USE ADMON01
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtTipoCamCan')
BEGIN
  DROP  FUNCTION fnObtTipoCamCan
END
GO

CREATE FUNCTION fnObtTipoCamCan 
(@pCveEmpresa varchar(4),
 @pAnoMes     varchar(6),
 @pCveMoneda  varchar(1)
)
RETURNS numeric(8,4)

AS
BEGIN
  RETURN
  (SELECT TIPO_CAMB_F_MES FROM CI_PER_TIPO_CAMB WHERE
   CVE_EMPRESA = @pCveEmpresa                    AND
   ANO_MES     = dbo.fnObtAnoMesAnt(@pAnoMes)    AND
   CVE_MONEDA  =   @pCveMoneda)

END

