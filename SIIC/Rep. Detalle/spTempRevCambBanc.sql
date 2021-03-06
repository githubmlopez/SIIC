USE [ADMON01PB]
GO
/****** Object:  StoredProcedure [dbo].[spTempRevCambBanc]    Script Date: 08/05/2018 03:16:21 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXECUTE spTempRevCambBanc 'CU', '201801', 'D'
ALTER PROCEDURE [dbo].[spTempRevCambBanc] @pCveEmpresa varchar(4), @pAnoMes  varchar(6), @pMoneda  varchar(1)
                               

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
		  @tpo_cam_i_mes    numeric(8,4)   =  0,
		  @ano_mes_ant      varchar(6),
		  @f_fin_m_ant      date
		 

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
		  @k_activa        varchar(1)   = 'A',
		  @k_dolar         varchar(1)   = 'D',
		  @k_f_inicial     varchar(10)  = '1900-01-01',
		  @k_cheq_inicial  varchar(6)   = 'SDOINI',
		  @k_imp_val_mes   varchar(6)   = 'REVUSD',
		  @k_mes_ini       int          = 01,
		  @k_abono         varchar(1)   = 'A'

  DECLARE @REVALUACION TABLE
  (CVE_CHEQUERA     varchar(6),
   F_OPERACION      date,
   CVE_TIPO_MOVTO   varchar(6),
   IMP_NETO         numeric(12,2),
   TIPO_CAMBIO      numeric(8,4),
   IMP_COMPLENTARIA numeric(12,2))
 
  INSERT  @REVALUACION  (CVE_CHEQUERA, F_OPERACION, CVE_TIPO_MOVTO, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA)
  SELECT    
  ch.CVE_CHEQUERA,
  m.F_OPERACION,
  m.CVE_TIPO_MOVTO,
  m.IMP_TRANSACCION, 
  dbo.fnObtTipoCamb(m.F_OPERACION),
  CASE
  WHEN  m.CVE_CARGO_ABONO  =  @k_abono
  THEN (dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, ch.CVE_MONEDA) - m.IMP_TRANSACCION) * -1 
  ELSE dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, ch.CVE_MONEDA) - m.IMP_TRANSACCION 
  END
  FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch 
  WHERE m.CVE_CHEQUERA = ch.CVE_CHEQUERA  AND
        ch.CVE_MONEDA  = @k_dolar         AND
		m.SIT_MOVTO    = @k_activa        AND
		m.ANO_MES      = @pAnoMes
 
 --  Calcula complementaria por cada CXC, considerando los acumulados del mes
  
  SELECT @@ROWCOUNT

  IF  SUBSTRING(@pAnoMes,5,2)  =  @k_mes_ini 
  BEGIN
    SET  @ano_mes_ant  =  dbo.fnArmaAnoMes(CONVERT(INT,SUBSTRING(@pAnoMes,1,4)),
	                      CONVERT(INT,SUBSTRING(@pAnoMes,5,6)) - 1)
	SET  @f_fin_m_ant  = (SELECT F_FINAL FROM CI_PERIODO_CONTA WHERE CVE_EMPRESA =  @pCveEmpresa  AND ANO_MES  =  @ano_mes_ant)				  
						   
    INSERT  @REVALUACION  (CVE_CHEQUERA, F_OPERACION, CVE_TIPO_MOVTO, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA)
    SELECT  
    ch.CVE_CHEQUERA,
    @k_f_inicial,
    @k_cheq_inicial,
    SDO_FIN_MES, 
    dbo.fnObtTipoCamb(@f_fin_m_ant),
  ((SDO_FIN_MES * @tpo_cam_i_mes) - SDO_FIN_MES) * -1 
    FROM  CI_CHEQUERA_PERIODO cp, CI_CHEQUERA ch
    WHERE cp.ANO_MES       =  @ano_mes_ant    AND
          cp.CVE_CHEQUERA  =  ch.CVE_CHEQUERA AND
          ch.CVE_MONEDA    =  @k_dolar 
  END

  SET  @imp_mes_ant  =  0

  SET  @imp_tot_comp    = (SELECT SUM(IMP_COMPLENTARIA)  FROM  @REVALUACION) 

  SET  @imp_tot_comp  =  @imp_tot_comp  -  @imp_mes_ant

-- Calcula la valución de la complementaria valuada a cierre de mes 

  SET  @imp_dolares = (SELECT SDO_FIN_MES  FROM  CI_CHEQUERA_PERIODO cp, CI_CHEQUERA ch
                       WHERE cp.ANO_MES       =  @pAnoMes        AND
					         cp.CVE_CHEQUERA  =  ch.CVE_CHEQUERA AND
							 ch.CVE_MONEDA    =  @k_dolar) 
  SELECT ' SDO FIN ' + CONVERT(VARCHAR(16), @imp_dolares)
  SET  @imp_valua_dolar = @imp_dolares * 
                          (SELECT TIPO_CAM_F_MES FROM  CI_PERIODO_CONTA  WHERE
						   CVE_EMPRESA  =  @pCveEmpresa  AND
						   ANO_MES      =  @pAnoMes)
  SELECT ' VAL USD ' + CONVERT(VARCHAR(16), @imp_valua_dolar)

  SET  @imp_tot_com_cmes  =  @imp_valua_dolar - @imp_dolares 

  INSERT  @REVALUACION  (CVE_CHEQUERA, F_OPERACION, CVE_TIPO_MOVTO, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA) VALUES
  (' ',  @k_f_inicial, @k_imp_val_mes, @imp_valua_dolar, 
  (SELECT TIPO_CAM_F_MES FROM  CI_PERIODO_CONTA  WHERE
						   CVE_EMPRESA  =  @pCveEmpresa  AND
						   ANO_MES      =  @pAnoMes),
   
   @imp_tot_com_cmes)
 -- Calcula importe de renovación del mes

--  SET  @imp_renovacion  =  @imp_tot_com_cmes -  @imp_tot_comp

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