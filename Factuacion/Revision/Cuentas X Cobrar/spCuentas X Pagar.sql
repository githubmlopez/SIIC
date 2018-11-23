USE [ADMON01]
GO

--exec spCtasXpagar  'CU', '201804'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE spCtasXpagar  @pCveEmpresa  varchar(4), @pAnoMes varchar(6)
AS
BEGIN
   DECLARE  @k_activa       varchar(1)  =  'A',
            @k_cancelada    varchar(1)  =  'C',
            @k_peso         varchar(1)  =  'P',
            @k_dolar        varchar(1)  =  'D',
            @k_falso        bit         =  0,
            @k_verdadero    bit         =  1

   SELECT
   LEFT(CONVERT(VARCHAR, c.F_CAPTURA, 120), 10) AS F_OPERACION,    
   CONVERT(VARCHAR(10),p.ID_PROVEEDOR) AS ID_PROVEEDOR,
   p.NOM_PROVEEDOR,
   c.CVE_EMPRESA,
   c.ID_CXP,
   o.DESC_OPERACION,
   CONVERT(VARCHAR(12),c.IMP_NETO) AS IMP_F_NETO,
   c.CVE_CHEQUERA,
   c.CVE_MONEDA,
   CASE
   WHEN c.CVE_MONEDA = @k_dolar 
   THEN CONVERT(VARCHAR(12),dbo.fnObtTipoCamb(c.F_CAPTURA)) 
   ELSE '0'
   END AS TIPO_CAMBIO,
   CASE
   WHEN c.CVE_MONEDA  =  @k_dolar
   THEN CONVERT(VARCHAR(12), c.IMP_NETO * c.TIPO_CAMBIO)
   ELSE CONVERT(VARCHAR(12), c.IMP_NETO)
   END AS IMP_PESOS,
   CONVERT(VARCHAR(16), i.IMP_BRUTO) AS IMP_BRUTO,
   CONVERT(VARCHAR(16), i.IVA) AS IMP_IVA,
   LTRIM(ISNULL(c.TX_NOTA, ' ') + '/' + ISNULL(i.TX_NOTA, ' ')) AS NOTA
   --CASE
   --WHEN c.CVE_MONEDA  =  @k_dolar
   --THEN CONVERT(VARCHAR(12), i.IMP_BRUTO * c.TIPO_CAMBIO)
   --ELSE i.IMP_BRUTO
   --END AS IMP_BRUTO,
   --CASE
   --WHEN c.CVE_MONEDA  =  @k_dolar
   --THEN CONVERT(VARCHAR(12), i.IVA * c.TIPO_CAMBIO)
   --ELSE i.IVA
   --END AS IVA
   FROM   CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_CHEQUERA ch --,
   WHERE  c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
          c.SIT_C_X_P          =  @k_activa          AND
         dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA)) = @pAnoMes AND		                                                       i.ID_CXP_DET in    
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
   ' ',
   ' ',
   ' ',
   ' ',
   CONVERT(VARCHAR(12), i.IMP_BRUTO),
   CONVERT(VARCHAR(12), i.IVA),
   ISNULL(i.TX_NOTA,' ') AS NOTA
   --CASE
   --WHEN c.CVE_MONEDA  =  @k_dolar
   --THEN CONVERT(VARCHAR(12), i.IMP_BRUTO * c.TIPO_CAMBIO)
   --ELSE i.IMP_BRUTO
   --END,
   --CASE
   --WHEN c.CVE_MONEDA  =  @k_dolar
   --THEN CONVERT(VARCHAR(12), i.IVA * c.TIPO_CAMBIO)
   --ELSE i.IVA
   --END
   FROM   CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_CHEQUERA ch --,
   WHERE  c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
          c.SIT_C_X_P          =  @k_activa          AND
          dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA)) > @pAnoMes AND		
		  i.ID_CXP_DET NOT in    
         (select MIN(i2.ID_CXP_DET) FROM CI_ITEM_C_X_P i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.ID_CXP = i.ID_CXP)    
          order by c.ID_CXP, F_OPERACION DESC    

END