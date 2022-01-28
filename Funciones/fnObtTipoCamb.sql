USE ADMON01
GO

ALTER FUNCTION fnObtTipoCamb (@pCveEmpresa varchar(4), @pf_operacion date)
RETURNS numeric(8,4)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return(select TIPO_CAMBIO from CI_TIPO_CAMBIO WHERE CVE_EMPRESA =  @pCveEmpresa  AND  F_OPERACION = @pf_operacion)
END

