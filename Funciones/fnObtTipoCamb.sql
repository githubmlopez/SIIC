CREATE FUNCTION fnObtTipoCamb (@pf_operacion date)
RETURNS numeric(8,4)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return(select TIPO_CAMBIO from CI_TIPO_CAMBIO where F_OPERACION = @pf_operacion)
END

