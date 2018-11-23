USE [ADMON01]
GO
--exec spRepPolizas 'CU', '201804'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
SET XACT_ABORT ON
GO
ALTER PROCEDURE spRepPolizas @pCveEmpresa varchar(4), @pAnoMes  varchar(6)
AS
BEGIN
SELECT  dt.ANO_MES, t.CVE_OPER_CONT, dt.CVE_POLIZA, dt.ID_ENCA_POLIZA, dt.ID_TRANSACCION, dt.ID_ASIENTO, dt.CTA_CONTABLE, c.DESC_CTA_CONT, dt.DESC_DEPARTAMENTO,
dt.CONC_MOVIMIENTO, dt.DESC_DEPARTAMENTO, dt.PROYECTO, dt.TIPO_CAMBIO_P, dt.IMP_DEBE, dt.IMP_HABER
FROM CI_DET_POLIZA dt, CI_CAT_CTA_CONT c, CI_TRANSACCION_CONT t
WHERE  dt.ANO_MES        =  @pAnoMes           AND
       dt.CVE_EMPRESA    =  t.CVE_EMPRESA       AND
       dt.ID_TRANSACCION =  t.ID_TRANSACCION    AND
	   dt.CTA_CONTABLE   =  c.CTA_CONTABLE
UNION
SELECT  dt.ANO_MES, ' ',dt.CVE_POLIZA, dt.ID_ENCA_POLIZA, dt.ID_TRANSACCION, dt.ID_ASIENTO, dt.CTA_CONTABLE, c.DESC_CTA_CONT, dt.DESC_DEPARTAMENTO,
dt.CONC_MOVIMIENTO, dt.DESC_DEPARTAMENTO, dt.PROYECTO, dt.TIPO_CAMBIO_P, dt.IMP_DEBE, dt.IMP_HABER
FROM CI_DET_POLIZA dt, CI_CAT_CTA_CONT c, CI_TRANSACCION_CONT t
WHERE  dt.ANO_MES        =  @pAnoMes            AND
	   dt.CTA_CONTABLE   =  c.CTA_CONTABLE      AND
	   dt.ID_TRANSACCION = 999999999
ORDER BY dt.CVE_POLIZA, dt.ID_ENCA_POLIZA, dt.CONC_MOVIMIENTO, dt.ID_ASIENTO
END