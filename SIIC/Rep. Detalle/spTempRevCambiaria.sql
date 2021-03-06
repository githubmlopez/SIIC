USE [ADMON01PB]
GO
/****** Object:  StoredProcedure [dbo].[spTempRevCambiaria]    Script Date: 08/05/2018 03:12:18 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXECUTE spTempRevCambiaria 'CU', '201801', 'D'
ALTER PROCEDURE [dbo].[spTempRevCambiaria] @pCveEmpresa varchar(4), @pAnoMes  varchar(6), @pMoneda  varchar(1)
                               

AS
BEGIN

DECLARE
  @imp_bruto_p         numeric(16,2),
  @imp_iva_p           numeric(16,2),
  @imp_neto_p          numeric(16,2),
  @imp_comp_p          numeric(16,2),

---- Campos para importes en moneda extranjera

  @imp_bruto_d         numeric(16,2),
  @imp_iva_d           numeric(16,2),
  @imp_neto_d          numeric(16,2),

-- Campos para Cuentas Contables

  @cta_contable        varchar(30),
  @cta_contable_comp   varchar(30),
  @cta_contable_ing    varchar(30),
  @cta_contable_iva    varchar(30),

-- Campo para concepto de movimiento Y otros

  @tipo_cambio         varchar(4),
  @departamento        varchar(50),
  @proyecto            varchar(50),
  @conc_movimiento     varchar(400)

  DECLARE
  @id_transac          int,
  @gpo_transaccion     int,
  @ident_transaccion   varchar(400),
  @nom_titular         varchar(120),
  @cve_oper_cont       varchar(6),
  @tx_nota             varchar(250),
  @f_dia               date
		 
  DECLARE @imp_dolares      numeric(12,2)  =  0,
          @imp_valua_dolar  numeric(12,2)  =  0,
		  @imp_tot_com_cmes numeric(12,2)  =  0,
          @imp_tot_comp     numeric(12,2)  =  0,
          @imp_renovacion   numeric(12,2)  =  0,
		  @imp_mes_ant      numeric(12,2)  =  0,
		  @pAnoMesIni       varchar(6) 

  DECLARE @k_conc_parcial  varchar(2)  =  'CP',
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

  


  DECLARE @REVALUACION TABLE
  (CVE_EMPRESA      varchar(4),
   ID_CXC           int,
   IMP_NETO         numeric(12,2),
   TIPO_CAMBIO      NUMERIC(8,4),
   IMP_COMPLENTARIA numeric(12,2))
 
  SET  @pAnoMesIni  =  SUBSTRING(@pAnoMes,1,4) + '00'

  INSERT  @REVALUACION  (CVE_EMPRESA, ID_CXC, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA)
  SELECT    
  f.CVE_EMPRESA,
  f.ID_CXC,
  f.IMP_F_NETO, 
  dbo.fnObtTipoCamb(f.F_OPERACION),
  dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA) - f.IMP_F_NETO 
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
         f.SERIE <> @k_legada 

 --  Calcula complementaria por cada CXC, considerando los acumulados del mes
  
  SELECT @@ROWCOUNT

  SET  @imp_mes_ant  = (SELECT SUM(IMP_RENOVACION) FROM CI_PERIODO_CONTA WHERE
                        CVE_EMPRESA  =  @pCveEmpresa  AND
						ANO_MES      <  @pAnoMes      AND
						ANO_MES     >=  @pAnoMesIni)

  SET  @imp_mes_ant  =  ISNULL(@imp_mes_ant,0)

  SET  @imp_tot_comp    = (SELECT SUM(IMP_COMPLENTARIA)  FROM  @REVALUACION) 

  SET  @imp_tot_comp  =  @imp_tot_comp  -  @imp_mes_ant

-- Calcula la valución de la complementaria valuada a cierre de mes 

  SET  @imp_dolares = (SELECT SUM(IMP_NETO)  FROM  @REVALUACION) 

  SET  @imp_valua_dolar = @imp_dolares * 
                          (SELECT TIPO_CAM_F_MES FROM  CI_PERIODO_CONTA  WHERE
						   CVE_EMPRESA  =  @pCveEmpresa  AND
						   ANO_MES      =  @pAnoMes)

  SET  @imp_tot_com_cmes  =  @imp_valua_dolar - @imp_dolares 

-- Calcula importe de renovación del mes

  SET  @imp_renovacion  =  @imp_tot_com_cmes -  @imp_tot_comp

  --IF  @imp_renovacion  <  0 
  --BEGIN
  --  SET @cve_oper_cont  =  @k_perdida
  --END
  --ELSE
  --BEGIN
  --  SET @cve_oper_cont  =  @k_utilidad
  --END  

  select ' Renovacion ' + convert(varchar(16), @imp_renovacion)

  select * FROM @REVALUACION
END