USE [ADMON01]
GO

--exec spIngIdentP_L 'CU', 'MARIO', '201804', 12, 361, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spIngIdentP_L @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                               @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
						       @pMsgError varchar(400) OUT
AS
BEGIN
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
  
-- Datos auxiliares para el proceso
 
  @sit_factura         varchar(1),
  @f_operacion         date,
  @cve_f_moneda        varchar(1)

  DECLARE
  @error               varchar(100),
  @msg_error           nvarchar(400) 

  DECLARE 
  @imp_utilidad        numeric(16,2)  =  0

  DECLARE
  @gpo_transaccion     int,
  @ident_transaccion   varchar(400),
  @f_dia               date
  
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
		   @k_fact_iva        numeric(4,2) =  1.16,
		   @k_iva             numeric(4,2) =  .16,
  
-- Constantes para folios

		   @k_cta_iva         varchar(10),
		   @k_cta_ganancia    varchar(10),
		   @k_cta_perdida     varchar(10),
   		   @k_id_transaccion  varchar(4),
		   @k_gpo_transac     varchar(4),

-- Claves de operación para transacciones

		   @k_gan_pesos       varchar(6)  =  'GANP',
		   @k_gan_dolar       varchar(6)  =  'GAND',
  		   @k_per_pesos       varchar(6)  =  'PERP',
		   @k_per_dolar       varchar(6)  =  'PERD',

-- Claves de operación para ISR

		   @k_util_camb       varchar(6)  =  'UTILC'

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
  SET	   @k_cta_iva        =  'CTAIVA'
  SET	   @k_cta_ganancia   =  'CTAGANCAM'
  SET	   @k_cta_perdida    =  'CTAPERCAM'
  SET      @k_cta_comp       =  'CTACTECOMP'
  SET      @k_gpo_transac    =  'GPOT'
  SET      @k_id_transaccion =  'TRAC'

  SET      @k_error          =  'E'
--  SET      @k_ing_factura    =  'IDEFAC'

  BEGIN TRY

  -- Borra Cifras de Control asociadas

  --INSERT INTO @LISTA (valor) VALUES (@k_per_dolar),(@k_gan_dolar),(@k_per_pesos),(@k_gan_pesos)

  UPDATE  CI_CONCILIA_C_X_C  SET IMP_PAGO_AJUST = 0 WHERE ANOMES_PROCESO = @pAnoMes

  EXEC spProrrateaPago @pCveEmpresa, @pAnoMes
    
  EXEC spBorraTransac  @pCveEmpresa, @pAnoMes, @pIdProceso

  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

  INSERT FC_GEN_PROCESO_BIT (CVE_EMPRESA, ID_PROCESO, FT_PROCESO, GPO_TRANSACCION) 
  VALUES
  (@pCveEmpresa,
   @pIdProceso, 
   @pAnoMes + '00',
   @gpo_transaccion)

-- Obten datos del periodo contable
  
  select @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL,  @tipo_cam_f_mes =  TIPO_CAM_F_MES
  from CI_PERIODO_CONTA  where ANO_MES  =  @pAnoMes
  
  --SELECT ' PROCESANDO AÑOMES ==> ' + @pAnoMes
  --SELECT ' f. INICIO ==> ' + CONVERT(VARCHAR,@f_inicio_mes, 112)
  --SELECT ' f. FIN ==> ' + CONVERT(VARCHAR,@f_fin_mes, 112)
  --SELECT ' PRUEBA ' + dbo.fnArmaAnoMes (YEAR(@f_inicio_mes), MONTH(@f_inicio_mes)) 
  SET  @f_dia  =  GETDATE()

  --SELECT 'Reg a Procesar ' + convert(varchar(10),COUNT(*))
  --FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  --WHERE   f.CVE_EMPRESA      =  @pCveEmpresa   AND
  --        f.ID_VENTA         =  v.ID_VENTA     AND
  --        v.ID_CLIENTE       =  c.ID_CLIENTE   AND
  --        f.SERIE            <> @k_legada      AND
		--  f.SIT_CONCILIA_CXC IN (@k_conciliada,@k_conc_error)  AND
		--  EXISTS (SELECT 1 FROM  CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m WHERE
		--          f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC  AND
		--		  cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO AND
		--		  m.CVE_TIPO_MOVTO      =  @k_cxc              AND
		--		  cc.ANOMES_PROCESO     =  @pAnoMes)           AND                                      
  --        f.SIT_TRANSACCION  =  @k_activa                                           
                        
  --SELECT ' **TERMINE DE CONTAR** ' -----
  DECLARE cur_transaccion CURSOR FOR SELECT
  
--01 'IMBP', Importe Bruto Pesos
  0,
--02 'IMIP', Importe IVA Pesos
  0,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_peso
  --THEN   (dbo.fnAcumMovtosBanc(f.ID_CONCILIA_CXC) - 
  --      ((dbo.fnAcumMovtosBanc(f.ID_CONCILIA_CXC) / @k_fact_iva) * @k_iva)) -
		-- (f.IMP_F_NETO - f.IMP_F_IVA)
  THEN 
  dbo.fnAcumMovtosBanc(@pCveEmpresa, @pAnoMes, f.ID_CONCILIA_CXC, f.CVE_F_MONEDA, f.IMP_F_BRUTO, f.F_OPERACION)	
  ELSE  0
  END,
--04 'IMCP', Importe Complementario Pesos
  0,
--05 'IMBD', Importe Bruto Dólares
  0,
--06 'IMID', Importe IVA Dólares
  0,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar
  THEN dbo.fnAcumMovtosBanc(@pCveEmpresa, @pAnoMes, f.ID_CONCILIA_CXC, f.CVE_F_MONEDA, f.IMP_F_BRUTO, f.F_OPERACION)		 
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  ' ',
--09 'CTCM', Cuenta Contable Complementaria
  ' ',
--10 'CTIN', Cuenta Contable Ingresos
  ' ',
--11 'CTIV', Cuenta Contable IVA
  ' ',
--12 'TCAM', Tipo de Cambio
  1,
--13 'DPTO', Departamento
  0,
--14 'PROY', Proyecto
  ' ',
--15 'CPTO', Concepto
  f.SERIE + CONVERT(VARCHAR(10), f.ID_CXC) + c.NOM_CLIENTE + CONVERT(VARCHAR(10), dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, f.F_OPERACION)),
-- Campos de trabajo
  f.SIT_TRANSACCION,
  f.F_OPERACION,
  f.CVE_F_MONEDA,
  c.NOM_CLIENTE,
  SERIE + '-' + CONVERT(VARCHAR(8),f.ID_CXC) + '-' + c.NOM_CLIENTE + '-' + CONVERT(VARCHAR(8),dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, f.F_OPERACION))
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA      =  @pCveEmpresa   AND
          f.ID_VENTA         =  v.ID_VENTA     AND
          v.ID_CLIENTE       =  c.ID_CLIENTE   AND
          f.SERIE            <> @k_legada      AND
		  f.SIT_CONCILIA_CXC IN (@k_conciliada,@k_conc_error)  AND
		  EXISTS (SELECT 1 FROM  CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m WHERE
		          f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC     AND
				  cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO AND
				  m.CVE_TIPO_MOVTO      =  @k_cxc              AND
				  cc.ANOMES_PROCESO  =  @pAnoMes)              AND                                    
          f.SIT_TRANSACCION  =  @k_activa       
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
  -- Campos de trabajo
  @sit_factura,
  @f_operacion,
  @cve_f_moneda,
  @nom_titular,
  @ident_transaccion    

-- select ' Termine Primer FETCH '     
  
  SET  @imp_utilidad = 0

  WHILE (@@fetch_status = 0 )
  BEGIN 
--  SELECT ' ** ENTRE A WHILE ** '
    IF  @cve_f_moneda  =  @k_dolar
	BEGIN
	  IF  @imp_neto_d  <>  0
	  BEGIN
        IF  @imp_neto_d  <  0  
        BEGIN
		  SET @cve_oper_cont  =  @k_per_dolar
		  SET @cta_contable = dbo.fnObtParAlfa(@k_cta_perdida)
		END
		ELSE
		BEGIN
		  SET @cve_oper_cont  =  @k_gan_dolar
		  SET @cta_contable   =  dbo.fnObtParAlfa(@k_cta_ganancia)
		  SET @imp_utilidad   =  @imp_utilidad  +  @imp_neto_d
		END
	  END
	END
	ELSE
	BEGIN
	  IF  @imp_neto_p  <>  0
	  BEGIN
        IF  @imp_neto_p  <  0  
        BEGIN
		  SET @cve_oper_cont  =  @k_per_pesos
		  SET @cta_contable = dbo.fnObtParAlfa(@k_cta_perdida)
		END
		ELSE
		BEGIN
		  SET @cve_oper_cont  =  @k_gan_pesos
		  SET @cta_contable   =  dbo.fnObtParAlfa(@k_cta_ganancia)
		  SET @imp_utilidad   =  @imp_utilidad  +  @imp_neto_p
		END
	  END
	END

--	select ' Voy a crear transaccion '
    
	SET  @imp_neto_p  =  ABS(@imp_neto_p)
    SET  @imp_neto_d  =  ABS(@imp_neto_d)
	  
	   
    SET @tx_nota     =  0
	SET @id_transac  =  0
  
    UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_transaccion
    SET  @id_transac  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_transaccion)   
--   SELECT ' **** VOY A INSERTAR TRANSACCION ** '

    IF  @imp_neto_d  <>  0 OR  @imp_neto_p  <>  0
	BEGIN

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
    -- Campos de trabajo
    @sit_factura,
    @f_operacion,
    @cve_f_moneda,
    @nom_titular,
    @ident_transaccion  
 
  END
  
  CLOSE cur_transaccion
  DEALLOCATE cur_transaccion

-- Crea registros para cálculo de impuestos
  UPDATE CI_PERIODO_ISR SET IMP_OTR_PRODUC = 0 WHERE ANO_MES = @pAnoMes
  EXEC spInsIsrItem @pCveEmpresa, @pAnoMes,  @k_util_camb, @imp_utilidad
----    SELECT ' ** TERMINA REG IMPUESTOS **'
  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error de Ejecucion Proceso Tran. P&L'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

