CREATE FUNCTION fnCalComisVen (@anomes varchar(4), @pcve_empresa varchar(4), @pserie varchar(6), @pid_cxc int,
                               @id_item int)
RETURNS varchar(14)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @comision      numeric(12)
  
  set @pje_comision = ' ' 

  set @cve_producto = (select CVE_PRODUCTO FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO = @pcve_subproducto)   


  IF EXISTS (SELECT 1 FROM CI_CUPON_COMISION  WHERE ANO_MES       = @anomes         AND   
                                                    CVE_EMPRESA   = @pcve_empresa   AND
                                                    CVE_SERIE     = @pserie         AND
                                                    ID_CXC_       = @pid_cxc        AND
                                                    ID_ITEM       = @id_item  
  BEGIN 

    SELECT @comision = IMP_CUPON FROM CI_CUPON_COMISION  WHERE  ANO_MES  ANO_MES       = @anomes         AND   
                                                                CVE_EMPRESA            = @pcve_empresa   AND
                                                                CVE_SERIE              = @pserie         AND
                                                                ID_CXC_                = @pid_cxc        AND
                                                                ID_ITEM                = @id_item  
  END 
  ELSE
  BEGIN 
    set @comision = 0
  END  
             
  return(@comision)

END

