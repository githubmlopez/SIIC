USE [ADMON01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCCCuentasXPagar')
BEGIN
  DROP  PROCEDURE spCCCuentasXPagar
END
GO
--EXEC spCCCuentasXPagar 'CU','201811'
CREATE PROCEDURE [dbo].[spCCCuentasXPagar]
(
 @pCveEmpresa varchar(6),
 @pAnoMes varchar(6)
)
AS
BEGIN
  DECLARE
  @k_activa         varchar(1)   = 'A',
  @k_cancelada      varchar(1)   = 'C',
  @k_dolar          varchar(1)   = 'D',
  @k_falso          bit          = 0

  SELECT
  c.F_CAPTURA AS 'F. Operación',
  c.F_CANCELACION AS 'F. Cancelación',
  c.SIT_C_X_P AS 'Situación',
  c.CVE_EMPRESA AS 'Empresa',
  c.ID_CXP AS 'Id. CXC',
  c.ID_PROVEEDOR AS 'Id. Proveedor',
  p.NOM_PROVEEDOR AS 'Nom. Proveedor', 
  c.IMP_BRUTO AS 'Imp. Bruto',
  c.IMP_IVA AS 'Imp. IVA',
  IMP_NETO AS 'Imp. Neto',
  c.CVE_MONEDA AS 'Moneda',
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,c.F_CAPTURA) AS 'Tipo Cambio',
  CASE
  WHEN c.CVE_MONEDA  =  @k_dolar
  THEN c.IMP_BRUTO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,c.F_CAPTURA)
  ELSE c.IMP_BRUTO
  END AS 'Imp. Bruto (p)',
  CASE
  WHEN c.CVE_MONEDA  =  @k_dolar
  THEN c.IMP_IVA * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,c.F_CAPTURA)
  ELSE c.IMP_IVA
  END AS 'Imp. Iva (p)',
  CASE
  WHEN c.CVE_MONEDA  =  @k_dolar
  THEN c.IMP_NETO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,c.F_CAPTURA)
  ELSE c.IMP_NETO
  END AS 'Imp. Neto (p)'
  FROM    CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p
  WHERE   c.CVE_EMPRESA   =  @pCveEmpresa     AND
  c.ID_PROVEEDOR          =  p.ID_PROVEEDOR       AND
  dbo.fnArmaAnoMes(YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoMes AND
  c.SIT_C_X_P     = @k_activa 
END		