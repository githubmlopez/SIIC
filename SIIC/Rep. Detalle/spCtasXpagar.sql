USE [ADMON01]
GO

--exec spCtasXpagar  'CU', '20180401','20180430', '201804'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE spCtasXpagar  @pCveEmpresa  varchar(4), @pFInicial date, @pFFinal date, @pAnoMes varchar(6)
AS
BEGIN
     DECLARE  @k_activa          varchar(1)  =  'A',
              @k_cancelada       varchar(1)  =  'C',
              @k_legada          varchar(6)  =  'LEGACY',
              @k_peso            varchar(1)  =  'P',
              @k_dolar           varchar(1)  =  'D',
              @k_falso           bit         =  0,
              @k_verdadero       bit         =  1


   SELECT
   LEFT(CONVERT(VARCHAR, c.F_CAPTURA, 120), 10) AS F_OPERACION,    
   CONVERT(VARCHAR(10),p.ID_PROVEEDOR) AS ID_PROVEEDOR,
   p.NOM_PROVEEDOR,
   c.CVE_EMPRESA,
   c.ID_CXP,
   o.DESC_OPERACION,
   CONVERT(VARCHAR(12),c.IMP_NETO) AS IMP_F_NETO,
   c.CVE_MONEDA,
   CONVERT(VARCHAR(12), dbo.fnObtTipoCamb(c.F_CAPTURA)),
   CASE
   WHEN c.CVE_MONEDA  =  @k_dolar
   THEN CONVERT(VARCHAR(12), i.IMP_BRUTO * dbo.fnObtTipoCamb(c.F_CAPTURA))
   ELSE i.IMP_BRUTO
   END,
   CASE
   WHEN c.CVE_MONEDA  =  @k_dolar
   THEN CONVERT(VARCHAR(12), i.IVA * dbo.fnObtTipoCamb (c.F_CAPTURA))
   ELSE i.IVA
   END
   FROM   CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_CHEQUERA ch --,
   WHERE  c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
--		  o.B_DEUDOR           =  @k_falso           AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
         (c.SIT_C_X_P          =  @k_activa          AND
          c.F_CAPTURA >= @pFInicial and c.F_CAPTURA <= @pFFinal)   AND
--		 (c.SIT_C_X_P      =  @k_cancelada      AND                            
--		  dbo.fnArmaAnoMes(YEAR(c.F_CANCELACION), MONTH(c.F_CANCELACION))  = @pAnoMes)  AND
--		  NOT EXISTS(SELECT 1  FROM  CI_DET_DEUD_CXP  WHERE  CVE_EMPRESA = @pCveEmpresa   AND
		                                                       i.ID_CXP_DET in    
         (select MIN(i2.ID_CXP_DET) FROM CI_ITEM_C_X_P i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.ID_CXP = i.ID_CXP)    
   union    
   SELECT
   ' ',    
   ' ',
   ' ',
   ' ',
   c.ID_CXP,
   o.DESC_OPERACION,
   ' ',
   c.CVE_MONEDA,
   CONVERT(VARCHAR(12),dbo.fnObtTipoCamb(c.F_CAPTURA)),
   CASE
   WHEN c.CVE_MONEDA  =  @k_dolar
   THEN CONVERT(VARCHAR(12), i.IMP_BRUTO * dbo.fnObtTipoCamb(c.F_CAPTURA))
   ELSE i.IMP_BRUTO
   END,
   CASE
   WHEN c.CVE_MONEDA  =  @k_dolar
   THEN CONVERT(VARCHAR(12), i.IVA * dbo.fnObtTipoCamb(c.F_CAPTURA))
   ELSE i.IVA
   END
   FROM   CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_CHEQUERA ch --,
   WHERE  c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
--		  o.B_DEUDOR           =  @k_falso           AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
         (c.SIT_C_X_P          =  @k_activa          AND
          c.F_CAPTURA >= @pFInicial and c.F_CAPTURA <= @pFFinal)   AND
--		 (c.SIT_C_X_P      =  @k_cancelada      AND                            
--		  dbo.fnArmaAnoMes(YEAR(c.F_CANCELACION), MONTH(c.F_CANCELACION))  = @pAnoMes)  AND
--		  NOT EXISTS(SELECT 1  FROM  CI_DET_DEUD_CXP  WHERE  CVE_EMPRESA = @pCveEmpresa   AND
		                                                      i.ID_CXP_DET NOT in    
         (select MIN(i2.ID_CXP_DET) FROM CI_ITEM_C_X_P i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.ID_CXP = i.ID_CXP)    
         order by c.ID_CXP, F_OPERACION DESC    

END