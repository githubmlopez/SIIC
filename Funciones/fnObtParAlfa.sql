CREATE FUNCTION fnObtParAlfa
( @pcve_parametro varchar(10))
RETURNS varchar(30)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return (select substring(VALOR_ALFA,1,30) from CI_PARAMETRO where CVE_PARAMETRO = @pcve_parametro)
END

