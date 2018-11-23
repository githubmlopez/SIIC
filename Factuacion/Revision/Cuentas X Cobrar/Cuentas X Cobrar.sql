USE [ADMON01]
GO

--exec spCtasXCobrar  '201804', 'N'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
ALTER PROCEDURE spCtasXCobrar  @pAnoMes  varchar(6), @pMoneda varchar (1)
AS
BEGIN
   DECLARE  @k_conc_parcial   varchar(2)  =  'CP',
            @k_conc_total     varchar(2)  =  'CC',
			@k_conc_error     varchar(2)  =  'CE',
			@k_cancelada      varchar(1)  =  'C',
			@k_legada         varchar(6)  =  'LEGACY',
		    @k_conc_antes     varchar(2)  =  'CA',
		    @k_conc_despues   varchar(2)  =  'CD',
            @k_conc_ambos     varchar(2)  =  'CB',
		    @k_no_concilia    varchar(2)  =  'NC',
		    @k_n_conc_antes   varchar(2)  =  'NA',
		    @k_n_conc_despues varchar(2)  =  'ND',
		    @k_n_conc_ambos   varchar(2)  =  'NB',
		    @k_otra           varchar(2)  =  'OT',
			@k_activa         varchar(1)  =  'A',
			@k_no_aplica      varchar(1)  =  'N'
   

   SELECT
   LEFT(CONVERT(VARCHAR, f.F_OPERACION, 120), 10) AS F_OPERACION,    
   CONVERT(VARCHAR(10),c.ID_CLIENTE) AS ID_CLIENTE,
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
   CONVERT(VARCHAR(12),dbo.fnObtTipoCamb(f.F_OPERACION)) as TIPO_CAMBIO,
   CONVERT(VARCHAR(12),dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA)) AS IMP_PESOS,  
   CONVERT(VARCHAR(12),dbo.fnImpLiqPesos(f.ID_CONCILIA_CXC, @pAnoMes)) AS IMP_PAGADO, 
 --  CONVERT(VARCHAR(12),(dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA) - dbo.fnImpLiqPesos(f.ID_CONCILIA_CXC, @pAnoMes))) AS IMP_ADEUDA, 
   i.IMP_BRUTO_ITEM    
   FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   WHERE f.CVE_EMPRESA         = i.CVE_EMPRESA       AND         
         f.SERIE               = i.SERIE             AND    
         f.ID_CXC              = i.ID_CXC            AND
         dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes)    NOT IN (@k_conc_antes, @k_otra) AND    
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO   AND    
         f.ID_VENTA            = v.ID_VENTA          AND    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR     AND    
         v.ID_CLIENTE          = c.ID_CLIENTE        AND    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO      AND    
		 dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND
       ((f.SIT_TRANSACCION     = @k_activa)          OR
		(f.SIT_TRANSACCION     = @k_CANCELADA        AND 
         dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes)) AND
		(f.CVE_F_MONEDA        =   @pMoneda  OR
		 @pMoneda              =   @k_no_aplica)     AND    
         f.SERIE <> @k_legada   AND i.ID_ITEM in    
         (SELECT MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
   UNION   
   SELECT    
   ' ' AS F_OPERACION,   
   ' ', ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
   S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ', ' ', ' ', i.IMP_BRUTO_ITEM    
   FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
   WHERE f.CVE_EMPRESA         = i.CVE_EMPRESA       AND         
         f.SERIE               = i.SERIE             AND    
         f.ID_CXC              = i.ID_CXC            AND
         dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes)    NOT IN (@k_conc_antes, @k_otra) AND   
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO   AND    
         f.ID_VENTA            = v.ID_VENTA          AND    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR     AND    
         v.ID_CLIENTE          = c.ID_CLIENTE        AND    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO      AND    
		 dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND
       ((f.SIT_TRANSACCION     = @k_activa)          OR
		(f.SIT_TRANSACCION     = @k_CANCELADA        AND 
         dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes)) AND
		(f.CVE_F_MONEDA        =   @pMoneda  OR
		 @pMoneda              =   @k_no_aplica)     AND   
         f.SERIE <> @k_legada   AND  i.ID_ITEM not in    
         (SELECT MIN(i2.ID_ITEM) FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
         ORDER BY f.ID_CXC, F_OPERACION DESC    

END