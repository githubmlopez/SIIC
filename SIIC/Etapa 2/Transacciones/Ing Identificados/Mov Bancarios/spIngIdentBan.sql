USE [ADMON01]
GO

--exec spIngIdentBan 'CU', 'MARIO', '201804', 1, 144, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--exec spIngIdentBan 'CU', 'MARIO', '201809', 1,144, ' ', ' '
ALTER PROCEDURE spIngIdentBan @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                              @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
						      @pMsgError varchar(400) OUT
AS
BEGIN

  DECLARE  @TConciliaCxC  TABLE
  (ID_MOVTO_BANCARIO      int NOT NULL)

-- Datos de la Transacción

--  DECLARE @LISTA AS VALOR_ALFA

  DECLARE
  @id_transac          int,
  @nom_titular         varchar(120),
  @cve_oper_cont       varchar(6),
  @tx_nota             varchar(250)

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

-- Campo para concepto de movimiento Y otros

  @tipo_cambio         varchar(4),
  @departamento        varchar(50),
  @proyecto            varchar(50),
  @conc_movimiento     varchar(400),
  @id_movto_bancario   numeric(9,0),
  
-- Datos auxiliares para el proceso
 
  @cve_moneda          varchar(1)

  DECLARE
  @error               varchar(100),
  @msg_error           nvarchar(400) 

  DECLARE 
  @imp_facturado       numeric(16,2),
  @imp_fact_canc       numeric(16,2),
  @iva_cobrado         numeric(16,2),
  @imp_bruto_iva       numeric(16,2),
  @rfc                 varchar(15)

  DECLARE
  @gpo_transaccion     int,
  @ident_transaccion   varchar(400),
  @f_dia               date,
  @conc_factura        varchar(50),
  @b_acredita          bit
  
  DECLARE  @f_inicio_mes      date,
           @f_fin_mes         date,
           @tipo_cam_f_mes    numeric(8,4)

  DECLARE  @k_activa          varchar(1),
           @k_cancelada       varchar(1),
           @k_legada          varchar(6),
           @k_peso            varchar(1),
           @k_dolar           varchar(1),
           @k_falso           bit,
           @k_verdadero       bit,
		   @k_cta_comp        varchar(10),
		   @k_error           varchar(1),
		   @k_cxc             varchar(3)   =  'CXC',
		   @k_conciliada      varchar(2)   =  'CC',
		   @k_conc_error      varchar(2)   =  'CE',
		   @k_mov_cxc         varchar(2)   =  'CC',
		   @k_mov_cxp         varchar(2)   =  'CP',
		   @k_mov_iva         varchar(2)   =  'IV',
		   @k_fact_iva        numeric(4,2) =  1.16,
		   @k_iva             numeric(4,2) =  .16,
   		   @k_tipo_iva        varchar(1)   =  'B',
  
-- Constantes para folios

		   @k_cta_iva_c       varchar(10),
		   @k_cta_iva_a       varchar(10),
		   @k_cta_ingreso     varchar(10),
   		   @k_id_transaccion  varchar(4),
		   @k_gpo_transac     varchar(4),

-- Claves de operación para transacciones

		   @k_mov_pesos       varchar(6),
		   @k_mov_dolar       varchar(6)

-- Claves de operaciòn para registro de campos para càlculo de ISR

 --          @k_ing_factura     varchar(6),
--           @k_fac_cancel      varchar(6)

  SET      @k_activa         =  'A'
  SET      @k_cancelada      =  'C'
  SET      @k_legada         =  'LEGACY'
  SET      @k_dolar          =  'D'
  SET      @k_peso           =  'P'
  SET      @k_falso          =  0
  SET      @k_verdadero      =  1
  SET	   @k_cta_iva_c      =  'CTAIVAACPA'
  SET      @k_cta_iva_a      =  'CTAIVACOBR'
  SET	   @k_cta_ingreso    =  'CTAINGRESO'
  SET      @k_cta_comp       =  'CTACTECOMP'
  SET      @k_gpo_transac    =  'GPOT'
  SET      @k_id_transaccion =  'TRAC'

  SET      @k_mov_pesos      =  'PAGP'
  SET      @k_mov_dolar      =  'PAGD'

  SET      @k_error          =  'E'
--  SET      @k_ing_factura    =  'IDEFAC'

  BEGIN TRY
  -- Borra Cifras de Control asociadas
  
  --INSERT INTO @LISTA (valor) VALUES (@k_mov_dolar),(@k_mov_pesos)

  DELETE  FROM CI_PERIODO_IVA  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND CVE_TIPO  =  @k_tipo_iva

  EXEC spBorraTransac  @pCveEmpresa, @pAnoMes, @pIdProceso
  
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

  INSERT FC_GEN_PROCESO_BIT (CVE_EMPRESA, ID_PROCESO, FT_PROCESO, GPO_TRANSACCION) 
  VALUES
  (@pCveEmpresa,
   @pIdProceso, 
   @pAnoMes + '00',
   @gpo_transaccion)

  INSERT  @TConciliaCxC  (ID_MOVTO_BANCARIO)
  SELECT  DISTINCT(ID_MOVTO_BANCARIO)
  FROM    CI_CONCILIA_C_X_C
  WHERE   ANOMES_PROCESO     = @pAnoMes

-- Obten datos del periodo contable
  
  SELECT @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL,  @tipo_cam_f_mes =  TIPO_CAM_F_MES
  FROM CI_PERIODO_CONTA  where ANO_MES  =  @pAnoMes
  
  --SELECT ' PROCESANDO AÑOMES ==> ' + @pAnoMes
  --SELECT ' f. INICIO ==> ' + CONVERT(VARCHAR,@f_inicio_mes, 112)
  --SELECT ' f. FIN ==> ' + CONVERT(VARCHAR,@f_fin_mes, 112)
  --SELECT ' PRUEBA ' + dbo.fnArmaAnoMes (YEAR(@f_inicio_mes), MONTH(@f_inicio_mes)) 
  SET  @f_dia  =  GETDATE()

  --SELECT 'Reg a Procesar ' + convert(varchar(10),COUNT(*))
  --FROM  CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch, CI_CONCILIA_C_X_C cc 
  --WHERE cc.ANOMES_PROCESO     = @pAnoMes            AND 
  --      cc.ID_MOVTO_BANCARIO  = m.ID_MOVTO_BANCARIO AND
  --      m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO    AND
  --      m.CVE_CHEQUERA        = ch.CVE_CHEQUERA     AND
		--m.CVE_CHEQUERA        = ch.CVE_CHEQUERA     AND
		--m.CVE_TIPO_MOVTO      = @k_cxc              AND
		--m.SIT_CONCILIA_BANCO  IN (@k_conciliada, @k_conc_error)  AND
		--EXISTS (SELECT 1 FROM  CI_FACTURA f WHERE
		--        f.ID_CONCILIA_CXC  =  cc.ID_CONCILIA_CXC  AND
		--		f.SIT_CONCILIA_CXC IN (@k_conciliada, @k_conc_error))                                      
                        
--  SELECT ' **TERMINE DE CONTAR** ' -----
  DECLARE cur_transaccion CURSOR FOR SELECT
  
--01 'IMBP', Importe Bruto Pesos
  0,
--02 'IMIP', Importe IVA Pesos
  CASE
  WHEN    ch.CVE_MONEDA  =  @k_peso
  THEN    (m.IMP_TRANSACCION / @k_fact_iva)  * @k_iva
  ELSE    0
  END,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    ch.CVE_MONEDA   =  @k_peso
  THEN    m.IMP_TRANSACCION
  ELSE    0
  END, 
--04 'IMCP', Importe Complementario Pesos
  CASE
  WHEN    ch.CVE_MONEDA  =  @k_dolar
  THEN    (m.IMP_TRANSACCION  * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, m.F_OPERACION)) - m.IMP_TRANSACCION
  ELSE    0
  END,
--05 'IMBD', Importe Bruto Dólares
  0,
--06 'IMID', Importe IVA Dólares
  CASE
  WHEN    ch.CVE_MONEDA  =  @k_dolar
  THEN
  dbo.fnCalculaPesosC(@pCveEmpresa, @pAnoMes, m.F_OPERACION, (m.IMP_TRANSACCION / @k_fact_iva) * @k_iva, ch.CVE_MONEDA)
  ELSE    0
  END,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN    ch.CVE_MONEDA   =  @k_dolar
  THEN    m.IMP_TRANSACCION
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  ch.CTA_CONTABLE,
--09 'CTCM', Cuenta Contable Complementaria
  ch.CTA_CONT_COMP,
--10 'CTIN', Cuenta Contable Ingresos
  dbo.fnObtParAlfa(@k_cta_ingreso),
--11 'CTIV', Cuenta Contable IVA
  CASE
  WHEN t.CVE_TIPO_CONT  =  @k_mov_cxc
  THEN  dbo.fnObtParAlfa(@k_cta_iva_a)
  WHEN t.CVE_TIPO_CONT  =  @k_mov_cxc
  THEN  dbo.fnObtParAlfa(@k_cta_iva_c)
  WHEN t.CVE_TIPO_CONT  =  @k_mov_iva
  THEN t.CTA_CONTABLE
  ELSE ' '
  END,    
--12 'TCAM', Tipo de Cambio
  1,
--13 'DPTO', Departamento
  0,
--14 'PROY', Proyecto
  ' ',
--15 'CPTO', Concepto 
  m.CVE_CHEQUERA + '-' + CONVERT(VARCHAR(10), m.ID_MOVTO_BANCARIO) + '-' + @pAnoMes,
-- Campos de trabajo
  m.CVE_CHEQUERA + '-' + CONVERT(VARCHAR(10), m.ID_MOVTO_BANCARIO) + '-' + @pAnoMes,
  ch.CVE_MONEDA,
  m.ID_MOVTO_BANCARIO
  FROM  CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch, @TConciliaCxC cc 
  WHERE -- cc.ANOMES_PROCESO     = @pAnoMes            AND 
        cc.ID_MOVTO_BANCARIO  = m.ID_MOVTO_BANCARIO AND
        m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO    AND
        m.CVE_CHEQUERA        = ch.CVE_CHEQUERA     AND
	    m.CVE_TIPO_MOVTO      = @k_cxc              -- AND
		--EXISTS (SELECT 1 FROM  CI_FACTURA f WHERE
		--        f.ID_CONCILIA_CXC  =  cc.ID_CONCILIA_CXC  AND
		--		f.SIT_CONCILIA_CXC IN (@k_conciliada, @k_conc_error))     
  -----

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
  @ident_transaccion,
  @cve_moneda,
  @id_movto_bancario

-- select ' Termine Primer FETCH '     
  
  SET  @imp_facturado  =  0
  SET  @imp_fact_canc  =  0

  WHILE (@@fetch_status = 0 )
  BEGIN 
--  SELECT ' ** ENTRE A WHILE ** '
    EXEC  spObtCptoIngBco @id_movto_bancario, @conc_factura OUT
    SET @ident_transaccion  =  LTRIM (@ident_transaccion + ' ' + @conc_factura) 
    SET @conc_movimiento    =  LTRIM (@conc_factura + ' ' + @conc_movimiento) 
    IF  @cve_moneda    =  @k_dolar 
    BEGIN
	  SET  @cve_oper_cont  =  @k_mov_dolar
--	  SET  @imp_facturado  =  @imp_facturado  +  (@imp_neto_d  * dbo.fnObtTipoCamb(@f_operacion))
	END
    ELSE
	BEGIN
	  SET  @cve_oper_cont  =  @k_mov_pesos
--	  SET  @imp_facturado  =  @imp_facturado  +  @imp_neto_p
    END
 
--	select ' Voy a crear transaccion '
   
    SET @tx_nota     =  0
	SET @id_transac  =  0
	SET @nom_titular = ' '
  
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

   IF  @imp_iva_p + @imp_iva_d  >  0 
   BEGIN
     SET @iva_cobrado  = @imp_iva_p + @imp_iva_d
	 SET @iva_cobrado  = @iva_cobrado * -1
 	 SELECT @rfc = RFC FROM CI_CHEQUERA WHERE CVE_CHEQUERA = SUBSTRING(@ident_transaccion,1,6)
     SET @b_acredita = dbo.fnAcredIva(@pCveEmpresa, @id_movto_bancario)
     EXEC spRegIva @pCveEmpresa, @pAnoMes, @k_tipo_iva,  @iva_cobrado, @conc_movimiento, @rfc, 
	      @b_acredita, @pAnoMes, @id_movto_bancario 
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
    @ident_transaccion,
	@cve_moneda,
	@id_movto_bancario

-- Actualiza Información de IVA

  END
  
  CLOSE cur_transaccion
  DEALLOCATE cur_transaccion

  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error de Ejecucion Proceso Ing Identif Bcos'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

