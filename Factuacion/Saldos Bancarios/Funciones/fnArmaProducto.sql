CREATE FUNCTION fnArmaProducto (@id_concilia_cxc int)
RETURNS varchar(45)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @productos       varchar(45),
           @desc_producto   varchar(15)

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

    set @productos = substring(@desc_producto,1,15)
    
    FETCH item_cursor INTO  @desc_producto
    
  END  

  close item_cursor 
  deallocate item_cursor 

  return(@productos)



END

