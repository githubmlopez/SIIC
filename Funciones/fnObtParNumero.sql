USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtParNumero')
BEGIN
  DROP  FUNCTION fnObtParNumero
END
GO
CREATE FUNCTION [dbo].[fnObtParNumero] 
(
@pcve_parametro varchar(10)
)
RETURNS NUMERIC(18,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  RETURN
 (SELECT
  CASE 
  WHEN  VALOR_NUMERICO > 0
  THEN  VALOR_NUMERICO
  ELSE  0
  END
  FROM  CI_PARAMETRO where CVE_PARAMETRO = @pcve_parametro)
END

