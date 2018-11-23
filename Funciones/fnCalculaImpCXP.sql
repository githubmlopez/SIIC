ALTER FUNCTION fnCalculaImpCXP (@pImp_Estim numeric(16,2), @pImp_Real numeric(16,2))
RETURNS numeric(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  Declare  @imp_dolares   numeric(18,2)
 
  set @imp_dolares = 0 
 
  if  isnull(@pImp_Real,0) <> 0  
  BEGIN
    set @imp_dolares = @pImp_Real 
  END
  ELSE
  BEGIN
    if  isnull(@pImp_Estim,0) <> 0  
    BEGIN
      set @imp_dolares = @pImp_Estim
    END
  END
  return(@imp_dolares)
END

