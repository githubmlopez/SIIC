declare @conta int;
declare @nom_tabla  varchar(30)

declare cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA_EX 
  
open  cur_tabla

FETCH cur_tabla INTO  @nom_tabla

set @conta = 1

WHILE (@@fetch_status = 0 )
BEGIN
  update FC_TABLA_EX set SINONIMO = 'A' + CONVERT(VARCHAR(5),@conta) WHERE NOM_TABLA = @nom_tabla
  set @conta = @conta + 1
  FETCH cur_tabla INTO  @nom_tabla
END

close cur_tabla 
deallocate cur_tabla

select * from FC_TABLA_EX

   