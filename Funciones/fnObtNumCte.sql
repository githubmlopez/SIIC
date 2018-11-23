
begin
declare @cte int

set @cte = dbo.fnObtNumCte(57)
select convert(varchar(10),@cte)
end

ALTER FUNCTION fnObtNumCte
( @pId_Movto_Bancario int)
RETURNS int
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return (select distinct(c.ID_CLIENTE) from  CI_MOVTO_BANCARIO m, CI_CONCILIA_C_X_C cc, CI_FACTURA f, CI_VENTA v, CI_CLIENTE c
                                        where m.ID_MOVTO_BANCARIO    =  @pId_Movto_Bancario   and
                                              m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO  and
                                              cc.ID_CONCILIA_CXC      =  f.ID_CONCILIA_CXC     and
                                              f.ID_VENTA             =  v.ID_VENTA            and
                                              v.ID_CLIENTE           =  c.ID_CLIENTE)
END

