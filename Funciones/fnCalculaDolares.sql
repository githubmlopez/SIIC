USE ADMON01
GO 
ALTER FUNCTION fnCalculaDolares (@pf_real_pago date, @pImporte numeric(16,2), @pcve_moneda varchar(4))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  Declare  @k_pesos       varchar(1),
           @imp_dolares   numeric(18,2),
           @tipo_cambio   numeric(8,4)
  
  set @k_pesos = 'P'
   
  if  @pcve_moneda = @k_pesos 
  BEGIN
    SELECT @tipo_cambio = TIPO_CAMBIO FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @pf_real_pago 
    set @imp_dolares = @pImporte / @tipo_cambio
  END
  ELSE
  BEGIN
    set @imp_dolares = @pImporte
  END
  return(@imp_dolares)
END

