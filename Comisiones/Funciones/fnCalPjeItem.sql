ALTER FUNCTION fnCalPjeItem (@pcve_empresa varchar(4), @pserie varchar(6), @pid_cxc int,
                              @pimp_bruto_item numeric(12,2))
RETURNS varchar(14)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @pje_item_part numeric(7,4)
  
  set @pje_item_part = 0 

  set @pje_item_part = (@pimp_bruto_item / (isnull((select  IMP_F_BRUTO FROM CI_FACTURA WHERE
                                                            CVE_EMPRESA      =  @pcve_empresa     AND
                                                            SERIE            =  @pserie           AND
                                                            ID_CXC           =  @pid_cxc),0))) * 100
  return(@pje_item_part)

END

