USE ADMON01
GO 
ALTER FUNCTION fnRelCXP (@pcve_empresa varchar(4), @pserie varchar(6), @pid_cxc int, @pid_item int)
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  Declare  @k_dolares     varchar(1)
  
  Declare  @imp_dolares     numeric(18,2),
           @tipo_cambio     numeric(8,4),
           @imp_bruto       numeric(12,2),
           @cve_moneda      varchar(1),
           @id_concilia_cxp int,
           @f_pago          date
  
  
 -- set @pcve_empresa = 'CU'
 -- set @pserie = 'CUM'
 -- set @pid_cxc = 474
 -- set @pid_item = 10
  
  set @k_dolares   = 'D'
  set @imp_dolares = 0 

--  select ' ** comienza logica **'
   
  IF EXISTS (SELECT 1 FROM CI_ITEM_CXP WHERE CVE_EMPRESA  = @pcve_empresa and
                                             SERIE        = @pserie       and
                                             ID_CXC       = @pid_cxc      and
                                             ID_ITEM      = @pid_item)
  BEGIN -- 1
--  select ' ** si existe **'

    SELECT @id_concilia_cxp = ID_CONCILIA_CXP FROM CI_ITEM_CXP WHERE CVE_EMPRESA  = @pcve_empresa and
                                              SERIE       = @pserie       and
                                              ID_CXC      = @pid_cxc      and
                                              ID_ITEM     = @pid_item
 
--    SELECT ' cxp ==> ' + CAST(@id_cxp AS varchar(20))

    SELECT  @imp_bruto = IMP_BRUTO, @f_pago = F_PAGO, @cve_moneda = CVE_MONEDA
            FROM CI_CUENTA_X_PAGAR WHERE ID_CONCILIA_CXP = @id_concilia_cxp
--    SELECT ' IMP BRUTO ==> ' + CAST(@imp_bruto AS varchar(20))

    IF @cve_moneda <>  @k_dolares
    BEGIN -- 2
--      select ' **soy dolares **'

      SELECT @tipo_cambio = TIPO_CAMBIO FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_pago 
      SET @imp_dolares = @imp_bruto / @tipo_cambio
    END  -- 2
    ELSE
    BEGIN  -- 3
--      select ' ** no soy folares **'

      set @imp_dolares = @imp_bruto
    END -- 3
  END -- 1
  ELSE
  BEGIN -- 4
    set @imp_dolares = 0
  END  -- 4
--  SELECT ' Importe ==> ' + CAST(@imp_dolares AS varchar(20))
  return(@imp_dolares)
--------------------
END

