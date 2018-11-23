ALTER FUNCTION fnCalComisVen (@pcve_subproducto varchar(6), @pproceso varchar(4), @pcve_vendedor varchar(4),
                              @pcve_especial varchar(2))
RETURNS varchar(14)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @pje_comision  varchar(14),
           @cve_producto  varchar(4)
  
  set @pje_comision = ' ' 

  set @cve_producto = (select CVE_PRODUCTO FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO = @pcve_subproducto)   

  IF EXISTS (SELECT 1 FROM CI_PROD_PROCESO WHERE CVE_PRODUCTO  = @cve_producto     AND
                                                 CVE_PROCESO   = @pproceso         AND
                                                 CVE_VENDEDOR  = @pcve_vendedor    AND
                                                 CVE_ESPECIAL  = @pcve_especial)
  BEGIN 

    SET @pje_comision = convert(varchar(14),(SELECT PJE_COMISION FROM CI_PROD_PROCESO WHERE CVE_PRODUCTO  = @cve_producto    AND
                                                                                            CVE_PROCESO   = @pproceso         AND
                                                                                            CVE_VENDEDOR  = @pcve_vendedor    AND
                                                                                            CVE_ESPECIAL  = @pcve_especial))

  END 
  ELSE
  BEGIN 
    set @pje_comision = 'NO EXISTE'
  END  
             
  return(@pje_comision)

END

