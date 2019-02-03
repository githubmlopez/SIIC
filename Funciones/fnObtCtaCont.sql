USE ADMON01
GO

ALTER FUNCTION fnObtCtaCont (@pIdCliente int, @pCveTipoCuenta varchar(1))
RETURNS varchar(30)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  RETURN (SELECT cc.CTA_CONTABLE  from  CI_CLIENTE c, CI_CTA_CONT_CTE cc
                 WHERE c.ID_CLIENTE     =  @pIdCliente    AND 
				       c.ID_CLIENTE     =  cc.ID_CLIENTE  AND
					   cc.CVE_TIPO_CTA  =  @pCveTipoCuenta)

END

