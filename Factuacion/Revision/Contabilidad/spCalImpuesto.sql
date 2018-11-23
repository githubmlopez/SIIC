USE [ADMON01]
GO

-- EXEC spCalImpuesto 201701, 98.90, 27.08, 3089.20, 405.28, 0, 0

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spCalImpuesto]  @p_anomes_proceso varchar(6), @p_sdo_isr_comp numeric(16,2)
AS
BEGIN

declare  @imp_ingresos      numeric(12,2),
         @imp_cancelado     numeric(12,2),
         @imp_dif_cam_fac   numeric(12,2),
         @imp_cxc_dif_cam   numeric(12,2),
         @imp_ing_mes_ant   numeric(12,2),
         @imp_isr_mes_ant   numeric(12,2),
		 @imp_int_bancario  numeric(16,2),
		 @imp_isr_bancario  numeric(16,2),
         @imp_isr           numeric(12,2),
         @imp_util_est      numeric(12,2),
         @imp_base_pago     numeric(12,2),
         @mes_ant           int,
         @f_inicio_mes      date,
         @f_fin_mes         date,
         @tipo_cam_f_mes    numeric(8,4),
         @ano_mes_ant       varchar(6)

declare  @k_activa          varchar(2),
         @k_canc_mes_ant    varchar(2),
         @k_canc_mes_act    varchar(2),
         @k_conciliada      varchar(2),
         @k_con_error       varchar(2),
         @k_abierto         varchar(2),
         @k_enero           varchar(2),
         @k_legada          varchar(6),
         @k_dolar           varchar(1),
		 @k_peso            varchar(1),
		 @k_mov_interes     varchar(6),
		 @k_mov_impuesto    varchar(6),
         @k_falso           bit,
         @k_verdadero       bit

declare  @k_isr_mes         varchar(6),
         @k_coef_util       varchar(6),
         @k_ing_factura     varchar(6),
         @k_fac_cancel      varchar(6),
         @k_int_bancario    varchar(6),
         @k_isr_bancario    varchar(6),
         @k_per_fiscales    varchar(6),
         @k_isr_comp        varchar(6),
         @k_porc_impto      varchar(6),
         @k_up_cam_pag      varchar(6),
         @k_util_est        varchar(6),
         @k_base_pago       varchar(6),
         @k_ing_per_ant     varchar(6),
         @k_isr_per_ant     varchar(6)
         
declare  @cve_empresa       varchar(4), 
         @serie             varchar(6),           
         @id_cxc            int,                  
         @f_operacion       date,                 
         @f_captura         date,                 
         @f_pago            date,                
         @tipo_cambio       numeric(8,4),         
         @cve_chequera      varchar(6),           
         @id_venta          int,                  
         @id_fact_parcial   int,                  
         @cve_tipo_contrato varchar(1),           
         @cve_f_moneda      varchar(1),           
         @imp_f_bruto       numeric(12,2),        
         @tipo_cambio_dia   numeric(8,4),
         @imp_pesos         numeric(12,2),
         @imp_f_iva         numeric(12,2),        
         @imp_f_neto        numeric(12,2),        
         @cve_r_moneda      varchar(1),           
         @imp_r_neto_com    numeric(12,2),        
         @imp_r_neto        numeric(12,2),        
         @tipo_cambio_liq   numeric(8,4),         
         @tx_nota           varchar(400),         
         @nombre_doctp_pdf  varchar(25),          
         @nombre_docto_xml  varchar(25),          
         @firma             varchar(10),          
         @b_factura_pagada  bit,                  
         @id_concilia_cxc   int,                  
         @sit_concilia_cxc  varchar(2),           
         @sit_transaccion   varchar(2),                   
         @f_compromiso_pago date,
         @tx_nota_cobranza  varchar(200),
         @f_cancelacion     date,
         @sit_tran_fact     varchar(2)
       

set      @k_activa         =  'AC'
set      @k_conciliada     =  'CC'
set      @k_canc_mes_ant   =  'CA'
set      @k_canc_mes_act   =  'CM'
set      @k_con_error      =  'CE'
set      @k_abierto        =  'AB'
set      @k_dolar          =  'AB'
set      @k_legada         =  'LEGACY'
set      @k_dolar          =  'D'
set      @k_peso           =  'P'
set      @k_enero          =  '01' 
SET      @k_mov_interes    =  'IBF'
SET      @k_mov_impuesto   =  'RET'
set      @k_falso          =  0
set      @k_verdadero      =  1

set      @k_up_cam_pag     =  'UPCAMB'

set      @k_ing_factura    =  'INGFAC' -- 1 
set      @k_fac_cancel     =  'FACCAN' -- 2
set      @k_int_bancario   =  'INTBAN' -- 3 
set      @k_isr_bancario   =  'ISRBAN' -- 4
set      @k_ing_per_ant    =  'INGPAN' -- 5
set      @k_coef_util      =  'COUTIL' -- 6  
set      @k_util_est       =  'UTIEST' -- 7
set      @k_per_fiscales   =  'PERFIS' -- 8
set      @k_base_pago      =  'BASPAG' -- 9
set      @k_porc_impto     =  'PORIMP' -- 10
set      @k_isr_mes        =  'ISR'    -- 11
set      @k_isr_per_ant    =  'ISRPAN' -- 12
set      @k_isr_comp       =  'ISRCOM' -- 15

set      @imp_ingresos     =  0
set      @imp_cancelado    =  0
set      @imp_dif_cam_fac  =  0
set      @imp_cxc_dif_cam  =  0
set      @imp_ing_mes_ant  =  0
set      @imp_isr_mes_ant  =  0
set      @imp_ISR          =  0
set      @imp_util_est     =  0
set      @imp_base_pago    =  0

-- Inicialia Periodo

if  (select pi.B_CERRADO from CI_PERIODO_ISR pi where pi.ANO_MES = @p_anomes_proceso) =  @k_falso
begin
  if  SUBSTRING(@p_anomes_proceso,5,2) = @k_enero
  begin
    set  @imp_ing_mes_ant  =  0
  end
  else
  begin
    SELECT ' No es Enero '
    set @mes_ant     = convert(int,SUBSTRING(@p_anomes_proceso,5,2)) - 1
	set @ano_mes_ant = dbo.fnArmaAnoMes(@p_anomes_proceso,@mes_ant)
    set  @imp_ing_mes_ant  =   

-- Obtiene los ingresos y el impuestos de periódos anteriores

   (select IMP_CONCEPTO from CI_IMP_CPTO_CIER_MES where ANO_MES      = @ano_mes_ant  and
                                                        CVE_CONCEPTO = @k_ing_per_ant)
    set  @imp_isr_mes_ant  =   
   (select IMP_CONCEPTO from CI_IMP_CPTO_CIER_MES where ANO_MES      = @ano_mes_ant  and
                                                        CVE_CONCEPTO = @k_isr_per_ant)
  end
  
  select @f_inicio_mes  =  F_INICIAL, @f_fin_mes  =  F_FINAL, @tipo_cam_f_mes =  TIPO_CAM_F_MES
  from CI_PERIODO_CONTA  where ANO_MES  =  @p_anomes_proceso

  -- Inicializa concepros de cálculo de ISR
  
  DELETE CI_IMP_CPTO_CIER_MES where ANO_MES  =  @p_anomes_proceso   AND 
                                    CVE_CONCEPTO in (@k_ing_factura,@k_fac_cancel,@k_int_bancario,
                                                     @k_isr_bancario,
                                                     @k_ing_per_ant,@k_util_est, @k_up_cam_pag, 
                                                     @k_per_fiscales,@k_base_pago,@k_porc_impto,
                                                     @k_isr_mes,@k_isr_per_ant,@k_isr_comp)

  -- Inicializa cálculos de pérdida y ganancia cambiaria del mes
  
  DELETE CI_PERD_GAN_CAMB WHERE ANO_MES = @p_anomes_proceso

  -- Calcula y Registra intereses por movimientos Bancarios

  SET @imp_int_bancario  =  (SELECT 
                             CASE 
							 WHEN ch.CVE_MONEDA  =  @k_dolar
							 THEN SUM(m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION))
							 WHEN ch.CVE_MONEDA  =  @k_peso
							 THEN SUM(m.IMP_TRANSACCION)
							 ELSE SUM(0)
							 END
                             FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
							 WHERE m.ANO_MES        =  @p_anomes_proceso   AND
							       m.CVE_CHEQUERA   =  ch.CVE_CHEQUERA     AND
								   m.CVE_TIPO_MOVTO  IN (@k_mov_interes)   AND
								   ch.CVE_MONEDA    =  @k_dolar            AND
								   m.SIT_MOVTO      =  @k_activa)
                                                       
  exec spInsIsrItem @p_anomes_proceso, @k_int_bancario,  @imp_int_bancario 

  SET  @imp_isr_bancario =  (SELECT 
                             CASE 
							 WHEN ch.CVE_MONEDA  =  @k_dolar
							 THEN SUM(m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION))
							 WHEN ch.CVE_MONEDA  =  @k_peso
							 THEN SUM(m.IMP_TRANSACCION)
							 ELSE SUM(0)
							 END
                             FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
							 WHERE m.ANO_MES        =  @p_anomes_proceso   AND
							       m.CVE_CHEQUERA   =  ch.CVE_CHEQUERA     AND
								   m.CVE_TIPO_MOVTO  IN (@k_mov_impuesto)   AND
								   ch.CVE_MONEDA    =  @k_dolar            AND
								   m.SIT_MOVTO      =  @k_activa)

  exec spInsIsrItem @p_anomes_proceso, @k_isr_bancario, @imp_isr_bancario

  -- Obtiene el Perdida fiscal del periodo correspondiente

  exec spInsIsrItem @p_anomes_proceso, @k_per_fiscales, 
                    (select IMP_PER_FISCAL from CI_PERIODO_CONTA  where ANO_MES  =  @p_anomes_proceso)

  -- Obtiene el ISR a compensar del periodo correspondiente
  
  exec spInsIsrItem @p_anomes_proceso, @k_isr_comp, 
                    (select IMP_ISR_COMPENSA from CI_PERIODO_CONTA  where ANO_MES  =  @p_anomes_proceso)
  

  exec spInsIsrItem @p_anomes_proceso, @k_porc_impto, 
                    (select PCT_IMPUESTO from CI_PERIODO_CONTA  where ANO_MES  =  @p_anomes_proceso)
  
  
  set  @imp_util_est  = (@imp_ingresos - @imp_cancelado + @imp_int_bancario - @imp_isr_bancario) *   
                        (select IMP_CONCEPTO from CI_IMP_CPTO_CIER_MES where ANO_MES      = @p_anomes_proceso  and
                                                                               CVE_CONCEPTO = @k_coef_util)  
  set  @imp_base_pago =  @imp_util_est -  @p_per_fiscales
 
  exec spInsIsrItem @p_anomes_proceso, @k_util_est, @imp_util_est

  exec spInsIsrItem @p_anomes_proceso, @k_base_pago, @imp_base_pago

  set  @imp_ing_mes_ant  =  @imp_ing_mes_ant  +  (@imp_ingresos - @imp_cancelado + @imp_int_bancario)

  set  @imp_isr          = ((@imp_base_pago    *
                            (select COEF_UTILIDAD from CI_PERIODO_CONTA  where ANO_MES  =  @p_anomes_proceso)
                                                                                  
   
  set  @imp_isr_mes_ant  =  @imp_isr_mes_ant  +   @imp_isr

  exec spInsIsrItem @p_anomes_proceso, @k_ing_per_ant, @imp_ing_mes_ant

  exec spInsIsrItem @p_anomes_proceso, @k_isr_mes, @imp_isr

  exec spInsIsrItem @p_anomes_proceso, @k_isr_per_ant, @imp_isr_mes_ant

end
else
begin
  select 'El Periodo esta Cerrado no se puede procesar'
end

select cp.DESC_CONCEPTO, im.IMP_CONCEPTO from CI_IMP_CPTO_CIER_MES im, CI_CPTO_CIERRE_MES cp where B_PRESENTA       = @k_verdadero      and
                                                                                                   cp.CVE_CONCEPTO  = im.CVE_CONCEPTO   and
                                                                                                   im.ANO_MES       = @p_anomes_proceso                                                                                                 
                                                                                                   order by  cp.ID_ORDEN
                                                                                                   
END
