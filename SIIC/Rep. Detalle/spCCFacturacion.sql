USE [ADMON01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCCFacturacion')
BEGIN
  DROP  PROCEDURE spCCFacturacion
END
GO
--EXEC spCCFacturacion 'CU','201901','F'
CREATE PROCEDURE [dbo].[spCCFacturacion]
(
 @pCveEmpresa varchar(6),
 @pAnoMes     varchar(6),
 @pOpción     varchar(1)
)
AS
BEGIN
  DECLARE
  @k_activa         varchar(1)   = 'A',
  @k_cancelada      varchar(1)   = 'C',
  @k_legada         varchar(6)   = 'LEGACY',
  @k_dolar          varchar(1)   = 'D',
  @k_falso          bit          = 0,
  @k_facturacion    varchar(1)   = 'F',
  @k_cancelacion    varchar(1)   = 'C'

  IF  @pOpción = @k_facturacion
  BEGIN

  SELECT
  f.F_OPERACION AS 'F. Operación',
  f.F_CANCELACION AS 'F. Cancelación',
  f.SIT_TRANSACCION AS 'Situación',
  f.CVE_EMPRESA AS 'Empresa',
  f.SERIE AS 'Serie',
  f.ID_CXC AS 'Id. CXC',
  c.ID_CLIENTE AS 'Id. Cliente',
  c.NOM_CLIENTE AS 'Nom. Cliente', 
  f.IMP_F_BRUTO AS 'Imp. Bruto',
  f.IMP_F_IVA AS 'Imp. IVA',
  IMP_F_NETO AS 'Imp. Neto',
  f.CVE_F_MONEDA AS 'Moneda',
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION) AS 'Tipo Cambio',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_BRUTO
  END AS 'Imp. Bruto (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_IVA
  END AS 'Imp. Iva (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_NETO
  END AS 'Imp. Neto (p)'
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
  f.ID_VENTA              =  v.ID_VENTA       AND
  v.ID_CLIENTE            =  c.ID_CLIENTE     AND
  f.SERIE                <>  @k_legada        AND                                         
(((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND f.SIT_TRANSACCION     = @k_activa) OR
 (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA) AND
 (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes)))		  
  UNION 
  SELECT 
  f.F_OPERACION AS 'F. Operación',
  f.F_CANCELACION AS 'F. Cancelación',
  @k_activa AS 'Situación',
  f.CVE_EMPRESA AS 'Empresa',
  f.SERIE AS 'Serie',
  f.ID_CXC AS 'Id. CXC',
  c.ID_CLIENTE AS 'Id. Cliente',
  c.NOM_CLIENTE AS 'Nom. Cliente',   
  f.IMP_F_BRUTO AS 'Imp. Bruto',
  f.IMP_F_IVA AS 'Imp. IVA',
  IMP_F_NETO AS 'Imp. Neto',
  f.CVE_F_MONEDA AS 'Moneda',
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION) AS 'Tipo Cambio',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_BRUTO
  END AS 'Imp. Bruto (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_IVA
  END AS 'Imp. IVA (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_NETO
  END AS 'Imp. Neto (p)'
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
  f.ID_VENTA              =  v.ID_VENTA       AND
  v.ID_CLIENTE            =  c.ID_CLIENTE     AND
  f.SERIE                <>  @k_legada        AND
  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes  AND                                         
 (f.SIT_TRANSACCION      =  @k_cancelada      AND
  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes)  
  
  END
  ELSE
  BEGIN
 
  SELECT 
  f.F_OPERACION AS 'F. Operación',
  f.F_CANCELACION AS 'F. Cancelación',
  @k_activa AS 'Situación',
  f.CVE_EMPRESA AS 'Empresa',
  f.SERIE AS 'Serie',
  f.ID_CXC AS 'Id. CXC',
  c.ID_CLIENTE AS 'Id. Cliente',
  c.NOM_CLIENTE AS 'Nom. Cliente',   
  f.IMP_F_BRUTO AS 'Imp. Bruto',
  f.IMP_F_IVA AS 'Imp. IVA',
  IMP_F_NETO AS 'Imp. Neto',
  f.CVE_F_MONEDA AS 'Moneda',
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION) AS 'Tipo Cambio',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_BRUTO
  END AS 'Imp. Bruto (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_IVA
  END AS 'Imp. IVA (p)',
  CASE
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,f.F_OPERACION)
  ELSE f.IMP_F_NETO
  END AS 'Imp. Neto (p)'
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
  f.ID_VENTA              =  v.ID_VENTA       AND
  v.ID_CLIENTE            =  c.ID_CLIENTE     AND
  f.SERIE                <>  @k_legada        AND
  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes  AND                                         
 (f.SIT_TRANSACCION      =  @k_cancelada      AND
  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  > 
  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)))  

  END     
END		