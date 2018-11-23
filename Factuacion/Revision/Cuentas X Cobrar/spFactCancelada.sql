USE [ADMON01]
GO

--exec spFactCancelada  'CU', '20180101','20180131', '201801'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE spFactCancelada  @pCveEmpresa  varchar(4), @pFInicial date, @pFFinal date, @pAnoMes varchar(6)
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
   LEFT(CONVERT(VARCHAR, f.F_OPERACION, 120), 10) AS F_OPERACION,    
   CONVERT(VARCHAR(10),c.ID_CLIENTE)AS ID_CLIENTE,
   c.NOM_CLIENTE,
   f.CVE_EMPRESA,
   f.SERIE,
   f.ID_CXC,
   p.DESC_PRODUCTO,
   S.DESC_CORTA_SP,
   CONVERT(VARCHAR(12),f.IMP_F_BRUTO) AS IMP_F_BRUTO,
   CONVERT(VARCHAR(12),f.IMP_F_IVA) AS IMP_F_IVA,
   CONVERT(VARCHAR(12),f.IMP_F_NETO) AS IMP_F_NETO,
   f.CVE_F_MONEDA,
   CONVERT(VARCHAR(12),dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA)) AS IMP_PESOS,  
   i.IMP_BRUTO_ITEM, f.SIT_TRANSACCION, F_CANCELACION   
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND 
         f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and                                            
 		 f.SIT_TRANSACCION     =  @k_cancelada   AND
		 dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes   and i.ID_ITEM in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
   union    
   select    
   ' ' AS F_OPERACION,   
   ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
   S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ', i.IMP_BRUTO_ITEM, ' ' , ' '   
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND 
         f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and                                            
 		 f.SIT_TRANSACCION     =  @k_cancelada   AND
		 dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes     and i.ID_ITEM not in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
         order by f.ID_CXC, F_OPERACION DESC    

END