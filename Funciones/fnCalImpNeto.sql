USE ADMON01
GO 
ALTER FUNCTION fnCalImpNeto (@pimp_neto numeric(18,2), @pcve_moneda varchar(1), @ptipo_cambio numeric(8,4))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @imp_pesos     numeric(18,2),
           @k_dolar       varchar(1)
  
  set @k_dolar = 'D'         
  
  IF  @pcve_moneda  = @k_dolar
  BEGIN
    set @imp_pesos = @pimp_neto * @ptipo_cambio
  END  
  ELSE
  BEGIN
    set @imp_pesos = @pimp_neto  
  END
  
  return(@imp_pesos)
--------------------
END

