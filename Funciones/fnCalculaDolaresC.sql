USE ADMON01
GO 
ALTER FUNCTION fnCalculaDolaresC
(
@pCveEmpresa  varchar(4),
@pAnoMes      varchar(6),
@pFRealPago   date,
@pImporte     numeric(16,2),
@pcve_moneda  varchar(4))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  DECLARE  @k_pesos       varchar(1),
           @imp_dolares   numeric(18,2),
           @tipo_cambio   numeric(8,4)
  
  SET @k_pesos = 'P'
   
  if  @pcve_moneda = @k_pesos 
  BEGIN
    SET @tipo_cambio = dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @pFRealPago)
    SET @imp_dolares = @pImporte / @tipo_cambio
  END
  ELSE
  BEGIN
    set @imp_dolares = @pImporte
  END
  return(@imp_dolares)
END

