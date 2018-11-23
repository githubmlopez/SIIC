CREATE FUNCTION fnCalComisItem (@pcve_empresa varchar(4), @pserie varchar(6), @pid_cxc int, @pid_item int)
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @imp_dolares   numeric(18,2),
           @tipo_cambio   numeric(8,4),
           @imp_comision  numeric(12,2),
           @f_pago        date,
           @id_cxp        int
  
  
 -- set @pcve_empresa = 'CU'
 -- set @pserie = 'CUM'
 -- set @pid_cxc = 474
 -- set @pid_item = 10
  
  set @imp_dolares = 0 

--  select ' ** comienza logica **'
   
  IF EXISTS (SELECT 1 FROM CI_CUPON_COMISION WHERE CVE_EMPRESA  = @pcve_empresa and
                                                   SERIE        = @pserie       and
                                                   ID_CXC       = @pid_cxc      and
                                                   ID_ITEM      = @pid_item)
  BEGIN -- 1
--  select ' ** si existe **'

    SELECT @f_pago = F_REAL_PAGO FROM CI_FACTURA	WHERE CVE_EMPRESA  = @pcve_empresa and
                                                  SERIE        = @pserie       and
                                                  ID_CXC       = @pid_cxc    
                                             
                                                  
    SELECT @imp_comision = sum(IMP_CUPON) FROM CI_CUPON_COMISION WHERE CVE_EMPRESA  = @pcve_empresa and
                                                                       SERIE        = @pserie       and
                                                                       ID_CXC       = @pid_cxc      and
                                                                       ID_ITEM      = @pid_item

    SELECT @tipo_cambio = TIPO_CAMBIO FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_pago 
 
--    SELECT ' IMP BRUTO ==> ' + CAST(@imp_bruto AS varchar(20))

    SET @imp_dolares = @imp_comision / @tipo_cambio
  END -- 1
  ELSE
  BEGIN -- 4
    set @imp_dolares = 0
  END  -- 4
--  SELECT ' Importe ==> ' + CAST(@imp_dolares AS varchar(20))
  return(@imp_dolares)
--------------------
END

