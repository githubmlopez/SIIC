USE [ADMON01]
GO

--exec spFacturacion  'CU', '20190201','20190128', '201902'
--DROP PROCEDURE spFacturacion
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE spFacturacion  @pCveEmpresa  varchar(4), @pFInicial date, @pFFinal date, @pAnoMes varchar(6)
AS
BEGIN
  DECLARE  @ano_mes_ant       varchar(6)
  
  DECLARE  @k_activa          varchar(1)  =  'A',
           @k_cancelada       varchar(1)  =  'C',
           @k_legada          varchar(6)  =  'LEGACY',
           @k_peso            varchar(1)  =  'P',
           @k_dolar           varchar(1)  =  'D',
           @k_falso           bit         =  0,
           @k_verdadero       bit         =  1

   SET @ano_mes_ant = dbo.fnObtAnoMesAnt(@pAnoMes)

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
   CASE 
   WHEN f.CVE_F_MONEDA = @k_dolar
   THEN
   CONVERT(VARCHAR(12),
   dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoMes, f.SIT_TRANSACCION,f.F_OPERACION),f.F_OPERACION) *
   f.IMP_F_NETO)
   ELSE CONVERT(VARCHAR(12),f.IMP_F_NETO)
   END AS IMP_PESOS,
   i.IMP_BRUTO_ITEM, SIT_TRANSACCION 
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND 
         f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and                                            
--         f.SIT_TRANSACCION      =  @k_activa                                   AND  
--          f.F_OPERACION >= @pFInicial and f.F_OPERACION <= @pFFinal  AND
          i.ID_ITEM in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
   union    
   select    
   ' ' AS F_OPERACION,   
   ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
   S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ', i.IMP_BRUTO_ITEM,  SIT_TRANSACCION 
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND 
         f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and                                        
--         f.SIT_TRANSACCION      =  @k_activa                              AND  
--         ( f.F_OPERACION >= @pFInicial and f.F_OPERACION <= @pFFinal) and
          i.ID_ITEM not in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
         order by f.ID_CXC, F_OPERACION DESC    

END