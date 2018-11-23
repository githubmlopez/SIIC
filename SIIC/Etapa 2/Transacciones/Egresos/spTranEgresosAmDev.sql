USE [ADMON01PB]
GO

--exec spTranFacturacion 'CU', 'MARIO', '201601', 1, 130, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- DROP PROCEDURE spTranFacturacion
ALTER PROCEDURE spTranEgresosAmDev @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                   @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								   @pMsgError varchar(400) OUT
AS
BEGIN

  DECLARE @LISTA AS VALOR_ALFA

-- Datos de la Transacción

  DECLARE
  @id_transac          int,
  @cve_gpo_contable    int,
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
 
  @sit_cxp             varchar(1),
  @f_captura           date,
  @cve_moneda          varchar(1),
  @b_amortiza          bit,
  @b_devenga           bit

  DECLARE
  @error               varchar(100),
  @msg_error           nvarchar(400) 

  DECLARE 
  @imp_facturado       numeric(16,2),
  @imp_fact_canc       numeric(16,2)

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
		   @k_fact_iva        int          =  .16,
  
-- Constantes para folios

		   @k_cta_iva         varchar(10),
		   @k_cta_ingreso     varchar(10),
   		   @k_id_transaccion  varchar(4),
		   @k_gpo_transac     varchar(4),
		   @cve_identif       varchar(2),

-- Claves de operación para transacciones

		   @k_op_can_amort     varchar(2)  =  'CA',
		   @k_op_amort         varchar(2)  =  'AM',
		   @k_op_can_deven     varchar(2)  =  'CD',
		   @k_op_devenga       varchar(2)  =  'DE',
		   @k_tab_egresos     varchar(20)  =  'CI_MOV_CONT_CXP', 
		   @k_camp_identif    varchar(20)  =  'CVE_IDENTIFICA' 

  SET      @k_activa         =  'A'
  SET      @k_cancelada      =  'C'
  SET      @k_legada         =  'LEGACY'
  SET      @k_dolar          =  'D'
  SET      @k_peso           =  'P'
  SET      @k_falso          =  0
  SET      @k_verdadero      =  1
  SET	   @k_cta_iva        =  'CTAIVA'
  SET	   @k_cta_ingreso    =  'CTAINGRESO'
  SET      @k_cta_comp       =  'CTACTECOMP'
  SET      @k_gpo_transac    =  'GPOT'
  SET      @k_id_transaccion =  'TRAC'
  SET      @k_error          =  'E'

  BEGIN TRY

  INSERT INTO @LISTA (valor) VALUES(@k_op_can_amort),(@k_op_amort),(@k_op_can_deven),(@k_op_devenga)

  EXEC spLimpiaTransac  @pCveEmpresa, @pAnoMes, @pIdProceso,
                        @k_tab_egresos, @k_camp_identif, @LISTA
  
  -- Borra Cifras de Control asociadas

  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

-- Obten datos del periodo contable
  
  select @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL,  @tipo_cam_f_mes =  TIPO_CAM_F_MES
  from CI_PERIODO_CONTA  where ANO_MES  =  @pAnoMes
  
  SELECT ' PROCESANDO AÑOMES ==> ' + @pAnoMes
  SELECT ' f. INICIO ==> ' + CONVERT(VARCHAR,@f_inicio_mes, 112)
  SELECT ' f. FIN ==> ' + CONVERT(VARCHAR,@f_fin_mes, 112)
  SELECT ' PRUEBA ' + dbo.fnArmaAnoMes (YEAR(@f_inicio_mes), MONTH(@f_inicio_mes)) 
  SET  @f_dia  =  GETDATE()

  SELECT 'Reg a Procesar ' + convert(varchar(10),COUNT(*))
  FROM    CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_GPO_CONTABLE g, CI_CHEQUERA ch --,
 WHERE   c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  o.GPO_CONTABLE       =  g.CVE_GPO_CONTABLE AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
		 (o.B_DEVENGA          =  @k_verdadero       OR
		  o.B_AMORTIZA         =  @k_verdadero)      AND
        ((c.SIT_C_X_P          =  @k_activa          AND
          c.F_CAPTURA >= @f_inicio_mes and c.F_CAPTURA <= @f_fin_mes)   OR
		 (c.SIT_C_X_P      =  @k_cancelada     AND                            
 		  dbo.fnArmaAnoMes (YEAR(c.F_CANCELACION), MONTH(c.F_CANCELACION))  = @pAnoMes))


  SELECT ' **TERMINE DE CONTAR** ' -----
  DECLARE cur_transaccion CURSOR FOR SELECT
  
--01 'IMBP', Importe Bruto Pesos
  CASE
  WHEN    c.CVE_MONEDA  =  @k_peso
  THEN    i.IMP_BRUTO
  ELSE    0
  END,
--02 'IMIP', Importe IVA Pesos
  CASE
  WHEN    c.CVE_MONEDA  =  @k_peso
  THEN    i.IVA 
  ELSE    0
  END,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    c.CVE_MONEDA  =  @k_peso
  THEN    i.IMP_BRUTO + i.IVA
  ELSE    0
  END,
--04 'IMCP', Importe Complementario Pesos
  CASE
  WHEN    c.CVE_MONEDA =  @k_dolar
  THEN   ((i.IMP_BRUTO + i.IVA) * dbo.fnObtTipoCamb(c.F_CAPTURA)) - (i.IMP_BRUTO + IVA)
  ELSE    0
  END,
--05 'IMBD', Importe Bruto Dólares
  CASE
  WHEN    c.CVE_MONEDA  =  @k_dolar
  THEN    i.IMP_BRUTO  * dbo.fnObtTipoCamb(c.F_CAPTURA)
  ELSE    0
  END,
--06 'IMID', Importe IVA Dólares
  CASE
  WHEN    c.CVE_MONEDA  =  @k_dolar
  THEN    i.IMP_BRUTO *  @k_fact_iva * dbo.fnObtTipoCamb(c.F_CAPTURA)
  ELSE    0
  END,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN    c.CVE_MONEDA  =  @k_dolar
  THEN    i.IMP_BRUTO + i.IVA
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  o.CTA_CONTABLE,
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
  ch.CVE_CHEQUERA + CONVERT(VARCHAR(10), c.ID_CXP) + p.NOM_PROVEEDOR + @pAnoMes,
-- Campos de trabajo
  c.SIT_C_X_P,
  c.CVE_MONEDA,
  ch.CVE_CHEQUERA + '-'  +  CONVERT(VARCHAR(8),c.ID_CXP) + '-' + p.NOM_PROVEEDOR + '-' + @pAnoMes,
  o.GPO_CONTABLE,
  P.NOM_PROVEEDOR,
  o.B_AMORTIZA,
  o.B_DEVENGA

  FROM    CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i , CI_PROVEEDOR p, CI_OPERACION_CXP o, CI_GPO_CONTABLE g, CI_CHEQUERA ch --,
  WHERE   c.CVE_EMPRESA        =  @pCveEmpresa       AND
          c.ID_PROVEEDOR       =  p.ID_PROVEEDOR     AND
          c.CVE_EMPRESA        =  i.CVE_EMPRESA      AND
		  c.ID_CXP             =  i.ID_CXP           AND
		  o.GPO_CONTABLE       =  g.CVE_GPO_CONTABLE AND
		  i.CVE_OPERACION      =  o.CVE_OPERACION    AND
		  c.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
		 (o.B_DEVENGA          =  @k_verdadero       OR
		  o.B_AMORTIZA         =  @k_verdadero)      AND
        ((c.SIT_C_X_P          =  @k_activa          AND
          c.F_CAPTURA >= @f_inicio_mes and c.F_CAPTURA <= @f_fin_mes)   OR
		 (c.SIT_C_X_P      =  @k_cancelada     AND                            
 		  dbo.fnArmaAnoMes (YEAR(c.F_CANCELACION), MONTH(c.F_CANCELACION))  = @pAnoMes))


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
  @sit_cxp,
  @cve_moneda,
  @ident_transaccion,
  @cve_gpo_contable,
  @nom_titular,
  @b_amortiza,
  @b_devenga
    

-- select ' Termine Primer FETCH '     
    
  SET  @imp_facturado  =  0
  SET  @imp_fact_canc  =  0

  WHILE (@@fetch_status = 0 )
  BEGIN 
    SELECT ' ** ENTRE A WHILE ** '
    SET  @cve_identif  =  ' '
    IF   @sit_cxp  =  @k_cancelada
    BEGIN
      IF  @b_amortiza  =  @k_verdadero
	  BEGIN
        SET  @cve_identif  =  @k_op_can_amort
	  END
	  ELSE
	  BEGIN
        SET  @cve_identif  =  @k_op_can_deven
	  END
    END
	ELSE
	BEGIN
	  IF  @b_amortiza  =  @k_verdadero
	  BEGIN
	    SET  @cve_identif  =  @k_op_amort
      END
	  ELSE
	  BEGIN
	    SET  @cve_identif  =  @k_op_devenga
      END
	END
	  
    IF  EXISTS(SELECT 1 FROM CI_MOV_CONT_CXP  WHERE 
        CVE_EMPRESA       =  @pCveEmpresa        AND
		CVE_GPO_CONTABLE  =  @cve_gpo_contable   AND
		CVE_MONEDA        =  @cve_moneda)
    BEGIN
	  SET  @cve_oper_cont  =
	      (SELECT CVE_OPER_CONT FROM CI_MOV_CONT_CXP  WHERE 
	            CVE_EMPRESA       =  @pCveEmpresa        AND
	            CVE_GPO_CONTABLE  =  @cve_gpo_contable   AND
				CVE_IDENTIFICA    =  @cve_identif        AND
	 	        CVE_MONEDA        =  @cve_moneda)
	END
	ELSE
	BEGIN
	  SET  @pError    =  'No Existe Clave de operación ' + @pCveEmpresa + @cve_gpo_contable + @cve_moneda
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
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
    @sit_cxp,
    @cve_moneda,
    @ident_transaccion,
	@cve_gpo_contable,
	@nom_titular,
	@b_amortiza,
    @b_devenga
    
  END
  
  CLOSE cur_transaccion
  DEALLOCATE cur_transaccion

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error - '  +
	                   (SELECT SUBSTRING(NOMBRE_PROCESO,1,70) FROM FC_GEN_PROCESO  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
					                                                                     ID_PROCESO   =  @pIdProceso)

    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

