ALTER FUNCTION fnArmaFolPoliza (@id_movto_bancario int)
RETURNS varchar(45)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  Declare  @folios       varchar(45),
           @longitud     int
  Declare  @cve_empresa  varchar(4),
           @serie        varchar(6),
           @id_cxc        int

  declare  fact_cursor cursor for SELECT cve_empresa, serie, id_cxc
  from     CI_CONCILIA_C_X_C c, CI_FACTURA f 
  where    c.ID_MOVTO_BANCARIO  = @id_movto_bancario AND
           f.ID_CONCILIA_CXC    = c.ID_CONCILIA_CXC  
       
  set  @folios =  ' '       

  open  fact_cursor

  FETCH fact_cursor INTO  @cve_empresa, @serie, @id_cxc
    
  WHILE (@@fetch_status = 0 )
  BEGIN 

    set @folios = LTRIM(@folios + @serie + convert(varchar(6),@id_cxc) + '-')
        
    FETCH fact_cursor INTO  @cve_empresa, @serie, @id_cxc
    
  END  

  set @longitud = LEN(@folios)
  set @folios   = SUBSTRING(@folios,1,@longitud - 1)

  close fact_cursor 
  deallocate fact_cursor 

  return(@folios)

END

