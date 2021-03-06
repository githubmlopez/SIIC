USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnObtCtaContable] (@pCveEmpresa varchar(4), @pIdCliente int, @pCveMoneda varchar(1))
RETURNS varchar(30)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  return(select CTA_CONTABLE from CI_CTA_CONT_CTE where
  CVE_EMPRESA  = @pCveEmpresa  AND
  ID_CLIENTE   = @pIdCliente   AND
  CVE_TIPO_CTA = @pCveMoneda)
END

