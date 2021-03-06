USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
--EXEC spRepRevaluacion 'CU', '201804'
ALTER PROCEDURE [dbo].[spRepRevaluacion]  @pCveEmpresa varchar(4), @pAnoMes varchar(6)
AS
BEGIN
  SELECT 
  CVE_EMPRESA,
  ANO_MES,
  F_OPERACION,
  CVE_TIPO,
  ID_SECUENCIA,
  CVE_CONCEPTO,
  ID_CXC,
  CVE_CHEQUERA,
  IMP_NETO,
  TIPO_CAMBIO,
  IMP_COMPLEMENTARIA
  FROM CI_BIT_REV_CAMBIARIA
  WHERE CVE_EMPRESA  = @pCveEmpresa  AND ANO_MES = @pAnoMes 
END