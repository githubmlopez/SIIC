ALTER FUNCTION fnCalculaPesos (@pf_real_pago date, @pImporte numeric(16,2), @pcve_moneda varchar(4))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  Declare  @k_dolares     varchar(1),
           @imp_pesos   numeric(18,2),
           @tipo_cambio   numeric(8,4)
  
  set @k_dolares = 'D'
   
  if  @pcve_moneda = @k_dolares 
  BEGIN
    SELECT @tipo_cambio = TIPO_CAMBIO FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @pf_real_pago 
    set @imp_pesos = @pImporte * @tipo_cambio
  END
  ELSE
  BEGIN
    set @imp_pesos = @pImporte
  END
  return(@imp_pesos)
END

