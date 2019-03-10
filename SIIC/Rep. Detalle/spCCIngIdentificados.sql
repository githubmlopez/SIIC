USE [ADMON01]
GO
/****** Reporte de Saldos Movimientos Bancarios Identificados ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCCIngIdentificados')
BEGIN
  DROP  PROCEDURE spCCIngIdentificados
END
GO
-- EXEC spCCIngIdentificados 'CU', '201811'
CREATE PROCEDURE [dbo].[spCCIngIdentificados] @pCveEmpresa varchar(6), @pAnoMes varchar(6)
AS
BEGIN

  DECLARE  @k_cxc       varchar(6)   = 'CXC',
           @k_activa    varchar(1)   =  'A',
	       @k_dolar     varchar(1)   =  'D',
		   @k_fact_iva  numeric(4,2) =  1.16,
		   @k_iva       numeric(4,2) =  .16

  SELECT
  c.ANOMES_PROCESO 'A/M Concilia',
  ch.CVE_CHEQUERA AS 'Chequera',
  m.ID_MOVTO_BANCARIO 'Id. Movto',
  m.F_OPERACION AS 'F.Operación',
  (m.IMP_TRANSACCION - (m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva) AS 'Importe Bruto',
  ((m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva) AS 'IVA',
  m.IMP_TRANSACCION AS 'Imp. Neto',
  ch.CVE_MONEDA AS 'Moneda',
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,m.F_OPERACION) AS 'Tipo Cambio',
  CASE
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN (m.IMP_TRANSACCION - (m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva) * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,m.F_OPERACION)
  ELSE m.IMP_TRANSACCION - ((m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva)
  END AS 'Imp. Bruto (p)',
  CASE
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN ((m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva) * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,m.F_OPERACION)
  ELSE (m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva
  END AS 'Imp. Iva (p)',
  CASE
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN m.IMP_TRANSACCION * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes,m.F_OPERACION)
  ELSE m.IMP_TRANSACCION
  END AS 'Imp. Neto (p)',
  dbo.fnArmaFacturas(c.ID_MOVTO_BANCARIO) AS 'Facturas'
  FROM CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch WHERE 
  m.ID_MOVTO_BANCARIO  =  c.ID_MOVTO_BANCARIO  AND
  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
  m.CVE_TIPO_MOVTO     =  @k_CXC               AND
  m.SIT_MOVTO          =  @k_activa            AND
  c.ANOMES_PROCESO     =  @pAnoMes     ORDER BY ch.CVE_CHEQUERA, m.F_OPERACION       
END
 