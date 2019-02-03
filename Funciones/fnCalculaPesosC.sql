USE ADMON01
GO 
ALTER FUNCTION fnCalculaPesosC (
@pCveEmpresa  varchar(4),
@pAnoMes      varchar(6),
@pFrealPago date,
@pImporte     numeric(16,2),
@pcve_moneda  varchar(4))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  DECLARE  @k_dolares     varchar(1),
           @imp_pesos     numeric(18,2),
           @tipo_cambio   numeric(8,4)
  
  set @k_dolares = 'D'
   
  if  @pcve_moneda = @k_dolares 
  BEGIN
    SET @tipo_cambio = dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @pFrealPago)
    SET @imp_pesos = @pImporte * @tipo_cambio
  END
  ELSE
  BEGIN
    set @imp_pesos = @pImporte
  END
  return(@imp_pesos)
END

