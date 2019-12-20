USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
--DECLARE @pError varchar(80) , @pMsgError varchar(400) 
--exec spCalImpuesto 'CU','MARIO', '201906', 1, 2, ' ', ' '

ALTER PROCEDURE [dbo].[spCalImpuesto]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                       @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
	     							   @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE
         @imp_ingresos      numeric(16,2)  = 0,
		 @imp_vta_activos   numeric(16,2)  = 0,
		 @imp_otro_gtos_iva numeric(16,2)  = 0,
		 @imp_ing_grabados  numeric(16,2)  = 0, 
         @imp_cancelado     numeric(16,2)  = 0,
		 @imp_int_bancario  numeric(16,2)  = 0,
		 @imp_otr_produc    numeric(16,2)  = 0,
		 @imp_canc_utilidad numeric(16,2)  = 0,
		 @imp_exentos       numeric(16,2)  = 0,
		 @imp_ing_nominales numeric(16,2)  = 0,
		 @imp_ing_mes_ant   numeric(16,2)  = 0,
		 @imp_ing_totales   numeric(16,2)  = 0,  
         @coef_utilidad     numeric(6,4)   = 0,
		 @imp_util_estim    numeric(16,2)  = 0,
		 @imp_invent_acum   numeric(16,2)  = 0,
		 @imp_util_adicion  numeric(16,2)  = 0,
		 @imp_per_fisc_pa   numeric(16,2)  = 0,
		 @imp_base_pag_prov numeric(16,2)  = 0,
		 @tasa_isr          numeric(8,4)   = 0,
		 @imp_isr_periodo   numeric(16,2)  = 0,
		 @imp_isr_mes_ant   numeric(16,2)  = 0,
		 @imp_isr_bancario  numeric(16,2)  = 0,
		 @imp_isr_banc_acum numeric(16,2)  = 0,
		 @imp_pag_prov_ant  numeric(16,2)  = 0,
		 @imp_isr_compensa  numeric(16,2)  = 0,
		 @imp_efect_pagado  numeric(16,2)  = 0,
		 @imp_dif_efect_pag numeric(16,2)  = 0,
         @imp_isr           numeric(16,2)  = 0


DECLARE 
         @f_inicio_mes      date,
         @f_fin_mes         date,
         @tipo_cam_f_mes    numeric(8,4),
		 @ano               int,
		 @mes               int,
		 @ano_mes_ant       varchar(6)

declare  @k_diciembre       int         =  12,
         @k_enero           int         =  01,
         @k_falso           bit         =  0,
         @k_verdadero       bit         =  1,
		 @k_error           varchar(1)  =  'E',
		 @k_no_act          numeric(9,0) =  99999,
         @k_ingresos        varchar(6)   = 'VERISR',
		 @k_fac_cancela     varchar(6)   = 'VERISR2',
		 @k_int_banc        varchar(6)   = 'VERISR3',
		 @k_ut_camb         varchar(6)   = 'VERISR4',
		 @k_isr_banc        varchar(6)   = 'VERISR5',
		 @k_isr_favor       varchar(6)   = 'VERISR6',
		 @k_isr_pag_prov    varchar(6)   = 'VERISR7',
		 @k_dif_pago_isr    varchar(6)   = 'VERISR8',
		 @k_cerrado         varchar(1)   = 'C'


  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoMes)  <>  @k_cerrado 
  BEGIN

  SET  @ano  =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @mes  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2))

  IF  @mes  <>  @k_enero
  BEGIN
    SET  @mes  =  @mes - 1
  END
  ELSE
  BEGIN
    SET  @ano  =  @ano  -  1
	SET  @mes  =  @k_diciembre
  END

  SET  @ano_mes_ant  =  dbo.fnArmaAnoMes (@ano, @mes)

  SET  @imp_exentos = 0
  
  SELECT @imp_ingresos  =  IMP_INGRESOS, @imp_cancelado  =  IMP_CANCELACIONES, @imp_int_bancario  = IMP_INT_BANCARIO,
         @imp_vta_activos   =  IMP_VTA_ACTIVOS,  @imp_otro_gtos_iva  =  IMP_OTRO_GTOS_IVA,  @imp_otr_produc  =  IMP_OTR_PRODUC,
         @imp_invent_acum   =  IMP_INVENT_ACUM,  @coef_utilidad  =  COEF_UTLIDAD,  @tasa_isr  =  TASA_ISR,
		 @imp_isr_compensa  =  IMP_ISR_COMPENSA, @imp_isr_bancario  =  IMP_ISR_BANCARIO, @imp_per_fisc_pa  = IMP_PER_FISC_PA,
		 @imp_canc_utilidad =  IMP_CANC_UTILIDAD , @imp_efect_pagado = IMP_EFECT_PAGADO  
  FROM   CI_PERIODO_ISR  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes

  SET  @imp_ing_grabados  =  @imp_ingresos  +   @imp_vta_activos  +  @imp_otro_gtos_iva 


  SET  @imp_ing_mes_ant  =  ISNULL((SELECT SUM(IMP_ING_NOMINALES) 
                            FROM CI_PERIODO_ISR  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES <=  @ano_mes_ant
							AND IMP_ING_NOMINALES > 0),0)

  SET  @imp_ing_nominales  =  @imp_ing_grabados  -  @imp_cancelado + @imp_int_bancario + @imp_otr_produc - @imp_exentos - @imp_canc_utilidad

  SET  @imp_ing_totales  =  @imp_ing_nominales  +  @imp_ing_mes_ant

  SET  @imp_util_estim   =  @imp_ing_totales  *  @coef_utilidad

  SET  @imp_util_adicion =  @imp_util_estim  +  @imp_invent_acum

  SET  @imp_base_pag_prov  =  @imp_util_adicion  -  @imp_per_fisc_pa
  
  SET  @imp_isr_periodo  =  @imp_base_pag_prov  *  (@tasa_isr / 100) 

  SET  @imp_isr_mes_ant  =  ISNULL((SELECT IMP_ISR_PERIODO   
                            FROM CI_PERIODO_ISR  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES =  @ano_mes_ant),0)

  --SET @imp_isr_banc_acum  =  ISNULL((SELECT SUM(IMP_ISR_BANCARIO)   
  --                          FROM CI_PERIODO_ISR  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES <=  @ano_mes_ant AND
  --					SUBSTRING(ANO_MES,1,4) = SUBSTRING(@pAnoMes,1,4)),0) + @imp_isr_bancario

  SET @imp_isr_banc_acum  =  @imp_isr_bancario

  SET  @imp_pag_prov_ant  =  @imp_isr_periodo  -  @imp_isr_mes_ant  -  @imp_isr_banc_acum

  SET  @imp_isr  =   @imp_pag_prov_ant  -  @imp_isr_compensa
  
  SET  @imp_dif_efect_pag  =   @imp_pag_prov_ant - @imp_isr_compensa - @imp_efect_pagado

  BEGIN  TRY

  UPDATE  CI_PERIODO_ISR
   SET  IMP_ING_GRABADOS   =  @imp_ing_grabados,
        IMP_EXENTOS        =  @imp_exentos,
        IMP_ING_NOMINALES  =  @imp_ing_nominales,
        IMP_ING_MES_ANT    =  @imp_ing_mes_ant,
        IMP_ING_TOTALES    =  @imp_ing_totales,
        IMP_UTIL_ESTIM     =  @imp_util_estim,
        IMP_UTIL_ADICION   =  @imp_util_adicion,
        IMP_BASE_PAG_PROV  =  @imp_base_pag_prov,
		IMP_ISR_PERIODO    =  @imp_isr_periodo,
		IMP_ISR_MES_ANT    =  @imp_isr_mes_ant,
		IMP_ISR_BANCARIO   =  @imp_isr_bancario,
		IMP_ISR_BANC_ACUM  =  @imp_isr_banc_acum,
		IMP_PAG_PROV_PER   =  @imp_pag_prov_ant,  
        IMP_ISR            =  @imp_isr
  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  = @pAnoMes 

  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ingresos,       @imp_ing_grabados,  @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_fac_cancela,    @imp_cancelado,     @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_int_banc,       @imp_int_bancario,  @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ut_camb,        @imp_otr_produc,    @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_isr_banc,       @imp_isr_bancario,  @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_isr_favor,      @imp_isr_compensa,  @k_no_act 
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_isr_pag_prov,   @imp_efect_pagado,  @k_no_act
  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_dif_pago_isr,   @imp_dif_efect_pag, @k_no_act 
  
  END  TRY

  BEGIN CATCH
    SET  @pError    =  'Error de Ejecucion Proceso Calculo ISR'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
--    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, 1
  END                                                    
  ELSE
  BEGIN
    SET  @pError    =  'El periodo se encuentra cerrado ' + @pAnoMes
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
--    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END 

END
