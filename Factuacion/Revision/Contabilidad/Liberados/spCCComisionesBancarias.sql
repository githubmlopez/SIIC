declare @pano_mes varchar(6) =  '201801'

SELECT
--01 'IMBP', Importe Bruto Pesos
  0,
--02 'IMIP', Importe IVA Pesos
  CASE
  WHEN  ch.CVE_MONEDA = 'D' AND t.CVE_TIPO_CONT = 'IV'
  THEN  m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION)
  WHEN  ch.CVE_MONEDA = 'P' AND t.CVE_TIPO_CONT = 'IV'
  THEN  m.IMP_TRANSACCION
  ELSE  0
  END,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    ch.CVE_MONEDA  =  'P'
  THEN    m.IMP_TRANSACCION 
  ELSE    0
  END,
--04 'IMCP', Importe Complementario Pesos
  CASE
  WHEN    ch.CVE_MONEDA  =  'D'
  THEN   (m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION)) - m.IMP_TRANSACCION
  ELSE    0
  END,
--05 'IMBD', Importe Bruto Dólares
  0,
--06 'IMID', Importe IVA Dólares
  CASE
  WHEN  ch.CVE_MONEDA = 'D' AND t.CVE_TIPO_CONT = 'IV'
  THEN  m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION)
  ELSE  0
  END,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN   ch.CVE_MONEDA   =  'D'
  THEN   m.IMP_TRANSACCION
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  ch.CTA_CONTABLE,
--09 'CTCM', Cuenta Contable Complementaria
  ch.CTA_CONT_COMP,
--10 'CTIN', Cuenta Contable Ingresos
  dbo.fnObtParAlfa('CTAINGRESO'),
--11 'CTIV', Cuenta Contable IVA
  dbo.fnObtParAlfa('CTAIVA'),
--12 'TCAM', Tipo de Cambio
  1,
--13 'DPTO', Departamento
  0,
--14 'PROY', Proyecto
  ' ',
--15 'CPTO', Concepto
  ch.CVE_CHEQUERA + m.DESCRIPCION + CONVERT(VARCHAR(10), m.F_OPERACION,112),
-- Campos de trabajo
  M.CVE_TIPO_MOVTO,
  ch.CVE_MONEDA

FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch 
where m.ANO_MES = @pano_mes                     AND
      m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO  AND
      m.CVE_CHEQUERA        = ch.CVE_CHEQUERA   AND
	  EXISTS (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	  mb.CVE_EMPRESA        = 'CU'              AND
	  mb.CVE_OPER_CONT      = m.CVE_TIPO_MOVTO) 


IF  EXISTS (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	  mb.CVE_EMPRESA        = 'CU'              AND
	  mb.CVE_TIPO_MOVTO     = @cve_tipo_movto   AND 
	  mb.CVE_MONEDA         = @cve_moneda)
BEGIN
   SET @cve_tipo_movto  =  (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	   mb.CVE_EMPRESA        = 'CU'              AND
	   mb.CVE_TIPO_MOVTO     = @cve_tipo_movto   AND 
	   mb.CVE_MONEDA         = @cve_moneda) 
END
ELSE
BEGIN
  SELECT 'No se puede determinar el tipo de transacción'
END