ALTER FUNCTION fnObtTipoCambCierr (@pano_mes varchar(6))
RETURNS numeric(8,4)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return(select TIPO_CAM_F_MES from CI_PERIODO_ISR where ANO_MES = @pano_mes)
END

