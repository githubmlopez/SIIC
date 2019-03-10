USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

--exec spTranMovBanc   'CU', 'MLOPEZ', '201804', 1, 2, ' ', ' '
ALTER PROCEDURE spTranMovBanc  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								@pMsgError varchar(400) OUT
AS
BEGIN
-- Datos de la Transacción

--  DECLARE @LISTA AS VALOR_ALFA

  DECLARE
  @id_transac          int,
  @cve_oper_cont       varchar(6),
  @tx_nota             varchar(250),
  @cve_tipo_cont       varchar(2)

---- Campos para importe en pesos 

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

-- Campo para concepto de movimiento y otros

  @tipo_cambio         varchar(4),
  @departamento        varchar(50),
  @proyecto            varchar(50),
  @conc_movimiento     varchar(400),
  
-- Datos auxiliares para el proceso
 
  @cve_tipo_movto      varchar(6),
  @cve_moneda          varchar(1),
  @nom_titular         varchar(120),
  @id_movto_bancario   numeric(9,0)

  DECLARE
  @error               varchar(100),
  @msg_error           nvarchar(400) 

  DECLARE
  @gpo_transaccion     int,
  @ident_transaccion   varchar(400),
  @f_dia               date,
  @iva_pagado          numeric(16,2),
  @imp_bruto_iva       numeric(16,2),
  @rfc                 varchar(15)
  
  DECLARE  @f_inicio_mes      date,
           @f_fin_mes         date,
           @tipo_cam_f_mes    numeric(8,4),
		   @imp_intereses     numeric(12,2),
		   @imp_isr           numeric(12,2),
		   @num_reg           int

  DECLARE  @k_activa          varchar(1),
           @k_cancelada       varchar(1),
           @k_legada          varchar(6),
           @k_peso            varchar(1),
           @k_dolar           varchar(1),
           @k_falso           bit,
           @k_verdadero       bit,
		   @k_cta_comp        varchar(10),
		   @k_error           varchar(1),
		   @k_interes         varchar(2)   =  'IF',
		   @k_isr             varchar(2)   =  'IM',
		   @k_iva             varchar(2)   =  'IV',
		   @k_traspaso        varchar(2)   =  'TR',
   		   @k_tipo_iva        varchar(1)   =  'C',
		   @k_f_iva           numeric(6,4) =  .16,

  
-- Constantes para folios

		   @k_cta_iva         varchar(10),
		   @k_cta_ingreso     varchar(10),
   		   @k_id_transaccion  varchar(4),
		   @k_gpo_transac     varchar(4),

-- Claves de operación para transacciones

		   @k_fac_pesos       varchar(6),
		   @k_fac_dolar       varchar(6),
		   @k_can_mm_pesos    varchar(6),
           @k_can_mm_dolar    varchar(6),
           @k_can_ma_pesos    varchar(6),
           @k_can_ma_dolar    varchar(6),

-- Claves de operaciòn para registro de campos para càlculo de ISR

           @k_int_bancario    varchar(6)  =  'INTBAN',
		   @k_isr_bancario    varchar(6)  =  'ISRBAN'

  SET      @k_activa         =  'A'
  SET      @k_cancelada      =  'C'
  SET      @k_dolar          =  'D'
  SET      @k_peso           =  'P'
  SET      @k_falso          =  0
  SET      @k_verdadero      =  1
  SET	   @k_cta_iva        =  'CTAIVA'
  SET	   @k_cta_ingreso    =  'CTAGCOMBAN'
  SET      @k_cta_comp       =  'CTACTECOMP'
  SET      @k_gpo_transac    =  'GPOT'
  SET      @k_id_transaccion =  'TRAC'
  SET      @k_error          =  'E'

  BEGIN TRY
 
  --INSERT INTO @LISTA (valor) 
  --SELECT  CVE_OPER_CONT  FROM CI_MOV_CONT_BANC 

  DELETE  FROM CI_PERIODO_IVA  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND CVE_TIPO  =  @k_tipo_iva

  EXEC spBorraTransac  @pCveEmpresa, @pAnoMes, @pIdProceso

  -- Borra Cifras de Control asociadas
 
--  UPDATE  CI_PERIODO_ISR SET IMP_INT_BANCARIO = 0, IMP_ISR_BANCARIO = 0 WHERE ANO_MES = @pAnoMes

  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

  INSERT FC_GEN_PROCESO_BIT (CVE_EMPRESA, ID_PROCESO, FT_PROCESO, GPO_TRANSACCION) 
  VALUES
  (@pCveEmpresa,
   @pIdProceso, 
   @pAnoMes + '00',
   @gpo_transaccion)

-- Obten datos del periodo contable
  
  SELECT @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL,  @tipo_cam_f_mes =  TIPO_CAM_F_MES
  FROM CI_PERIODO_CONTA  where ANO_MES  =  @pAnoMes
  
  --SELECT ' PROCESANDO AÑOMES ==> ' + @pAnoMes
  --SELECT ' f. INICIO ==> ' + CONVERT(VARCHAR,@f_inicio_mes, 112)
  --SELECT ' f. FIN ==> ' + CONVERT(VARCHAR,@f_fin_mes, 112)
  --SELECT ' PRUEBA ' + dbo.fnArmaAnoMes (YEAR(@f_inicio_mes), MONTH(@f_inicio_mes)) 
  SET  @f_dia  =  GETDATE()

  --SELECT count(*)
  --FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch 
  --WHERE m.ANO_MES             = @pAnoMes          AND
  --      m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO  AND
  --      m.CVE_CHEQUERA        = ch.CVE_CHEQUERA   AND
	 --   EXISTS (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	 --   mb.CVE_EMPRESA        = @pCveEmpresa      AND
	 --   mb.CVE_TIPO_MOVTO      = m.CVE_TIPO_MOVTO) 

  --SELECT ' **TERMINE DE CONTAR** ' -----
  DECLARE cur_transaccion CURSOR FOR SELECT
--01 'IMBP', Importe Bruto Pesos
  0,
--02 'IMIP', Importe IVA Pesos
  --CASE
  ----WHEN  ch.CVE_MONEDA = @k_dolar AND t.CVE_TIPO_CONT = @k_iva
  ----THEN  m.IMP_TRANSACCION * dbo.fnObtTipoCamb(m.F_OPERACION)
  --WHEN  ch.CVE_MONEDA = @k_peso AND t.CVE_TIPO_CONT = @k_iva
  --THEN  m.IMP_TRANSACCION
  --ELSE  0
  --END,
  0,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    ch.CVE_MONEDA  =  @k_peso
  THEN    m.IMP_TRANSACCION 
  WHEN    ch.CVE_MONEDA  =  @k_dolar
  THEN    m.IMP_TRANSACCION * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, m.F_OPERACION)
  ELSE    0
  END,
--04 'IMCP', Importe Complementario Pesos
  dbo.fnObtImpComplem
  (@pCveEmpresa, @pAnoMes, m.CVE_CHEQUERA, m.F_OPERACION, m.ID_MOVTO_BANCARIO, ch.CVE_MONEDA, m.IMP_TRANSACCION),
--05 'IMBD', Importe Bruto Dólares
  0,
--06 'IMID', Importe IVA Dólares
  --CASE
  --WHEN  ch.CVE_MONEDA = @k_dolar AND t.CVE_TIPO_CONT = @k_iva
  --THEN  m.IMP_TRANSACCION * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, m.F_OPERACION)
  --ELSE  0
  --END,
  0,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN   ch.CVE_MONEDA   =  @k_dolar
  THEN   m.IMP_TRANSACCION
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  CASE
  WHEN   t.CVE_TIPO_CONT   =  @k_traspaso
  THEN   ch.CTA_CONTABLE
  ELSE   t.CTA_CONTABLE
  END, 

--09 'CTCM', Cuenta Contable Complementaria
  ch.CTA_CONT_COMP,
--10 'CTIN', Cuenta Contable Ingresos
  ch.CTA_CONTABLE,
--11 'CTIV', Cuenta Contable IVA
  dbo.fnObtParAlfa(@k_cta_iva),
--12 'TCAM', Tipo de Cambio
  1,
--13 'DPTO', Departamento
  0,
--14 'PROY', Proyecto
  ' ',
--15 'CPTO', Concepto
  ISNULL(ch.CVE_CHEQUERA,' ') + '-' + ISNULL(CONVERT(VARCHAR(10), m.F_OPERACION,112), ' ') +  '-' +
  CONVERT(VARCHAR(10), m.ID_MOVTO_BANCARIO) + '-' + ISNULL(m.DESCRIPCION,' '),  
-- Campos de trabajo
  m.CVE_TIPO_MOVTO,
  ch.CVE_MONEDA,
  ch.DESC_CHEQUERA,
  ch.CVE_CHEQUERA + '-' + CONVERT(VARCHAR(10), m.ID_MOVTO_BANCARIO),
  t.CVE_TIPO_CONT,
  m.ID_MOVTO_BANCARIO
  FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch 
  WHERE m.ANO_MES             = @pAnoMes          AND
        m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO  AND
        m.CVE_CHEQUERA        = ch.CVE_CHEQUERA   AND
	    EXISTS (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	    mb.CVE_EMPRESA        = @pCveEmpresa      AND
	    mb.CVE_TIPO_MOVTO      = m.CVE_TIPO_MOVTO) 

  EXEC spActPctTarea @pIdTarea, 30
  
--  select 'voy a abrir cursor **'

  OPEN  cur_transaccion
  
--  select 'Abri cursor **'

  FETCH cur_transaccion INTO  
  @imp_bruto_p,
  @imp_iva_p,
  @imp_neto_p,
  @imp_comp_p,
  @imp_bruto_d,
  @imp_iva_d,
  @imp_neto_d,
  @cta_contable,
  @cta_contable_comp,
  @cta_contable_ing, 
  @cta_contable_iva,
  @tipo_cambio,
  @departamento,
  @proyecto,
  @conc_movimiento,
-- Campos de trabajo
  @cve_tipo_movto,
  @cve_moneda,
  @nom_titular,
  @ident_transaccion,
  @cve_tipo_cont,
  @id_movto_bancario

-- select ' Termine Primer FETCH '     
  
  SET  @imp_intereses  =  0 
  SET  @imp_isr        =  0 

  WHILE (@@fetch_status = 0 )
  BEGIN 
--    SELECT ' ** ENTRE A WHILE ** '
    IF  @cve_tipo_cont  =  @k_interes    
	BEGIN
      SET @imp_intereses =   @imp_intereses  +  @imp_neto_p
    END
    IF  @cve_tipo_cont  =  @k_isr    
	BEGIN
      SET @imp_isr =   @imp_isr +  @imp_neto_p
    END

    IF  EXISTS (SELECT 1  FROM  CI_MOV_CONT_BANC mb WHERE
	    mb.CVE_EMPRESA        = @pCveEmpresa      AND
	    mb.CVE_TIPO_MOVTO     = @cve_tipo_movto   AND 
	    mb.CVE_MONEDA         = @cve_moneda)
    BEGIN
      SET @cve_oper_cont     =  (SELECT DISTINCT(CVE_OPER_CONT) FROM  CI_MOV_CONT_BANC mb WHERE
	      mb.CVE_EMPRESA     = @pCveEmpresa      AND
	      mb.CVE_TIPO_MOVTO  = @cve_tipo_movto   AND 
	      mb.CVE_MONEDA      = @cve_moneda)
--		  SELECT ' ** Clave de Transaccion ** ' +  @cve_tipo_movto 
    END
    ELSE
    BEGIN
      SET  @pError    =  'No se puede determinar el tipo de transacción ' + ISNULL(@cve_tipo_movto, ' ') + 
	                     ISNULL(@cve_moneda, ' ')
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END
--	select ' Voy a crear transaccion '
   
    SET @tx_nota     =  0
	SET @id_transac  =  0
  
    UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_transaccion
    SET  @id_transac  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_transaccion)   
--   SELECT ' **** VOY A INSERTAR TRANSACCION ** '
    EXEC  spCreaTransaccionCont
    @pIdProceso,
    @pIdTarea,
    @id_transac,
    @pCveUsuario,
    @pCveEmpresa,
    @pAnoMes,
    @cve_oper_cont,
    @f_dia,
    @ident_transaccion,
    @nom_titular,
    @tx_nota,
    @gpo_transaccion,
    @pError OUT,
    @pMsgError OUT
-- SELECT ' **** TERMINE TRANSACCION ** '
-- SELECT ' **** VOY A CREAR CONCEPTOS ** '
    EXEC spLanzaCreaConTrans
    @pIdProceso,
    @pIdTarea,
    @pCveEmpresa,
    @pAnoMes,
    @id_transac,
    @cve_oper_cont,
    @imp_bruto_p,
    @imp_iva_p,
    @imp_neto_p,
    @imp_comp_p,
    @imp_bruto_d,
    @imp_iva_d, 
    @imp_neto_d,
    @cta_contable,    
    @cta_contable_comp,
    @cta_contable_ing,
    @cta_contable_iva,
    @tipo_cambio,
    @departamento,
    @proyecto,    
    @conc_movimiento,
    @pError OUT,
    @pMsgError OUT
-- SELECT ' ** SALIR DE CREAR CONCEPTOS ** '

   IF @imp_iva_p + @imp_iva_d > 0 
   BEGIN
     SET @iva_pagado  = @imp_iva_p + @imp_iva_d
 	 SELECT @rfc = RFC FROM CI_CHEQUERA WHERE CVE_CHEQUERA = SUBSTRING(@ident_transaccion,1,6)
     EXEC spRegIva @pCveEmpresa, @pAnoMes, @k_tipo_iva, @iva_pagado, @conc_movimiento, @rfc, 
	      @k_verdadero, @pAnoMes, @id_movto_bancario
   END

   FETCH cur_transaccion INTO  
    @imp_bruto_p,
    @imp_iva_p,
    @imp_neto_p,
    @imp_comp_p,
    @imp_bruto_d,
    @imp_iva_d,
    @imp_neto_d,
    @cta_contable,
    @cta_contable_comp,
    @cta_contable_ing, 
    @cta_contable_iva,
    @tipo_cambio,
    @departamento,
    @proyecto,
    @conc_movimiento,
-- Campos de trabajo
    @cve_tipo_movto,
    @cve_moneda,
    @nom_titular,
	@ident_transaccion,
    @cve_tipo_cont,
	@id_movto_bancario

-- Actualiza Información de IVA

  END
  
  CLOSE cur_transaccion
  DEALLOCATE cur_transaccion

-- Crea registros para cálculo de impuestos
  
--  SELECT ' ** REGISTRO DE INTERESES **'
  EXEC spInsIsrItem @pCveEmpresa, @pAnoMes,  @k_int_bancario, @imp_intereses

--  SELECT ' ** REGISTRO DE IMPUESTOS **'
  EXEC spInsIsrItem @pCveEmpresa, @pAnoMes,  @k_isr_bancario, @imp_isr

--    SELECT ' ** TERMINA REG IMPUESTOS **'

  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error de Ejecucion Proceso Tran. Mov. Banc.'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END


