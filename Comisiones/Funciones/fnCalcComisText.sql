CREATE FUNCTION fnCalComisText (@anomes varchar(4), @pcve_empresa varchar(4), @pserie varchar(6), @pid_cxc int,
                                 @id_item int)
RETURNS varchar(14)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @texto      numeric(12)
  

  IF EXISTS (SELECT 1 FROM CI_CUPON_COMISION  WHERE ANO_MES       = @anomes         AND   
                                                    CVE_EMPRESA   = @pcve_empresa   AND
                                                    SERIE         = @pserie         AND
                                                    ID_CXC        = @pid_cxc        AND
                                                    ID_ITEM       = @id_item)  
  BEGIN 

    SELECT @texto = IMP_CUPON FROM CI_CUPON_COMISION  WHERE  ANO_MES                = @anomes         AND   
                                                                CVE_EMPRESA            = @pcve_empresa   AND
                                                                SERIE                  = @pserie         AND
                                                                ID_CXC                 = @pid_cxc        AND
                                                                ID_ITEM                = @id_item  
  END 
  ELSE
  BEGIN 
    set @texto = ' '
  END  
             
  return(@texto)

END

