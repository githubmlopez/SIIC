USE ADMON01
GO

ALTER FUNCTION fnArmaProductoCP (@id_concilia_cxp int)
RETURNS varchar(45)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @productos       varchar(45),
           @desc_producto   varchar(15)

  declare  item_cursor cursor for SELECT o.DESC_OPERACION FROM CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P i, CI_OPERACION_CXP o
  where    cp.ID_CXP          = @id_concilia_cxp   AND
           cp.CVE_EMPRESA     = i.CVE_EMPRESA      AND
           cp.ID_CXP          = i.ID_CXP           AND
           i.CVE_OPERACION    = o.CVE_OPERACION

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

