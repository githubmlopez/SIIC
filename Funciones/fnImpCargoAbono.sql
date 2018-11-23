CREATE FUNCTION fnImpCargoAbono(@cve_operacion varchar(1), @cve_cargo_abono varchar(1))
RETURNS int)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @importe         int,
           @desc_producto   varchar(15)

  set @productos = ' '	 

  declare  item_cursor cursor for SELECT p.DESC_PRODUCTO FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p
  where    f.ID_CONCILIA_CXC = @id_concilia_cxc   AND
           f.CVE_EMPRESA     = i.CVE_EMPRESA      AND
           f.SERIE           = i.SERIE            AND
           f.ID_CXC          = i.ID_CXC           AND
           i.CVE_SUBPRODUCTO  = s.CVE_SUBPRODUCTO  AND
           s.CVE_PRODUCTO    = p.CVE_PRODUCTO
       
  open  item_cursor

  FETCH item_cursor INTO  @desc_producto  
    
  WHILE (@@fetch_status = 0 )
  BEGIN 

    set @productos = RTRIM(LTRIM(@productos) + rtrim(substring(@desc_producto,1,15)) + '-')
    
    FETCH item_cursor INTO  @desc_producto
    
  END  

  close item_cursor 
  deallocate item_cursor 

  return(@productos)



END

