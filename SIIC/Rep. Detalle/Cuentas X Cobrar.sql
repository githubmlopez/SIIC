USE [ADMON01PB]
GO

--exec spCtasXCobrar  '201801', 'P'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE spCtasXCobrar  @pAnoMes  varchar(6), @pMoneda varchar (1)
AS
BEGIN
   DECLARE  @k_conc_parcial  varchar(2)  =  'CP',
            @k_conc_total    varchar(2)  =  'CC',
			@k_conc_error    varchar(2)  =  'CE',
			@k_no_concilia   varchar(2)  =  'NC',
			@k_cancelada     varchar(1)  =  'C',
			@k_legada        varchar(6)  =  'LEGACY',
	        @k_conc_par_ct   varchar(2)   = 'PC',
		    @k_conc_despues  varchar(2)   = 'CD',
		    @k_conc_antes    varchar(2)   = 'CA',
		    @k_conc_par_nc   varchar(2)   = 'PN',
			@k_activa        varchar(1)   = 'A'
   

   SELECT
   LEFT(CONVERT(VARCHAR, f.F_OPERACION, 120), 10) AS F_OPERACION,    
   CONVERT(VARCHAR(10),c.ID_CLIENTE)AS ID_CLIENTE,
   c.NOM_CLIENTE,
   ve.NOM_VENDEDOR,
   f.CVE_EMPRESA,
   f.SERIE,
   f.ID_CXC,
   p.DESC_PRODUCTO,
   S.DESC_CORTA_SP,
   CONVERT(VARCHAR(12),f.IMP_F_NETO) AS IMP_F_NETO,
   f.CVE_F_MONEDA,
   f.SIT_CONCILIA_CXC AS SIT_CONCILIA,
   dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes) AS SIT_CONC_CAL, 
   CONVERT(VARCHAR(12),dbo.fnObtTipoCamb(f.F_OPERACION)),
   CONVERT(VARCHAR(12),dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA)) AS IMP_PESOS,  
   CONVERT(VARCHAR(12),dbo.fnImpLiqPesos(f.ID_CONCILIA_CXC, @pAnoMes)) AS IMP_PAGADO, 
   CONVERT(VARCHAR(12),(dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA) - dbo.fnImpLiqPesos(f.ID_CONCILIA_CXC, @pAnoMes))) AS IMP_PAGADO, 
   i.IMP_BRUTO_ITEM    
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
         dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes)    IN (@k_conc_par_ct, @k_conc_par_nc, @k_no_concilia, @k_conc_despues) and    
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and    
		 dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND
       ((f.SIT_TRANSACCION     = @k_activa) OR
		(f.SIT_TRANSACCION     = @k_CANCELADA  AND 
         dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes)) AND
		 f.CVE_F_MONEDA        =   @pMoneda and    
         f.SERIE <> @k_legada   and i.ID_ITEM in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
   union    
   select    
   ' ' AS F_OPERACION,   
   ' ', ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
   S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', i.IMP_BRUTO_ITEM    
   from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   where f.CVE_EMPRESA         = i.CVE_EMPRESA and         
         f.SERIE               = i.SERIE and    
         f.ID_CXC              = i.ID_CXC and
--		 f.SIT_CONCILIA_CXC NOT IN (@k_conc_error, @k_conc_total)  AND  
         dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes)    IN (@k_conc_par_ct, @k_conc_par_nc, @k_no_concilia, @k_conc_despues) and    
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO and    
         f.ID_VENTA            = v.ID_VENTA    and    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR and    
         v.ID_CLIENTE          = c.ID_CLIENTE and    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO and    
		 dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND
       ((f.SIT_TRANSACCION     = @k_activa) OR
		(f.SIT_TRANSACCION     = @k_CANCELADA  AND 
         dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes)) AND
		 f.CVE_F_MONEDA        =   @pMoneda and    
         f.SERIE <> @k_legada   and  i.ID_ITEM not in    
         (select MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
         order by f.ID_CXC, F_OPERACION DESC    

END