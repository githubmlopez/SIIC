USE [ADMON01]
GO
--exec spTranFacturacion 'CU', 'MARIO', '201804', 12, 361, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
SET XACT_ABORT ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spTranFacturacion]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[spTranFacturacion]
GO
ALTER PROCEDURE spTranFacturacion @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
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

  --DECLARE 
  --@imp_facturado       numeric(16,2),
  --@imp_fact_canc       numeric(16,2)

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
		   @k_no_act          numeric(9,0) =  99999,
           @k_ind_factura     varchar(10)  =  'FACAING',
       	   @k_ind_fact_can    varchar(10)  =  'FACBING',
           @k_ind_iva         varchar(10)  =  'FACAIVA',
		   @k_ind_iva_can     varchar(10)  =  'FACBIVA',
  
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
           @k_ing_factura     varchar(6),
           @k_fac_cancel      varchar(6)

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
  SET      @k_fac_pesos      =  'FACP'
  SET      @k_fac_dolar      =  'FACD'
  SET      @k_can_mm_pesos   =  'FCMP'
  SET      @k_can_mm_dolar   =  'FCMD'
  SET      @k_can_ma_pesos   =  'FCAP'
  SET      @k_can_ma_dolar   =  'FCAD'
  SET      @k_error          =  'E'
  SET      @k_ing_factura    =  'INGFAC' 
  SET      @k_fac_cancel     =  'FACCAN'
  
  BEGIN TRY
  
  -- Borra Cifras de Control asociadas
  
--INSERT INTO @LISTA (valor) VALUES (@k_fac_pesos),(@k_fac_dolar),(@k_can_mm_pesos),(@k_can_mm_dolar),
--                                  (@k_can_ma_pesos),(@k_can_ma_dolar)

-- ALTER PROCEDURE spBorraTransac  @pCveEmpresa varchar(4), @pAnoMes  varchar(6), @pIdProceso numeric(9)
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
  --WHERE   f.CVE_EMPRESA          =  @pCveEmpresa                              AND
  --        f.ID_VENTA   =  v.ID_VENTA                                          AND
  --        v.ID_CLIENTE =  c.ID_CLIENTE                                        AND
  --        f.SERIE      <> 'LEGACY'                                            AND                                         

  --      ((f.SIT_TRANSACCION      =  @k_activa                                 AND  
  --        f.F_OPERACION >= @f_inicio_mes and f.F_OPERACION <= @f_fin_mes)     OR

		-- (f.SIT_TRANSACCION      =  @k_cancelada                              AND
		--  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes)) 

--  SELECT ' **TERMINE DE CONTAR** ' -----
  DECLARE cur_transaccion CURSOR LOCAL FORWARD_ONLY STATIC FOR SELECT
	
--01 'IMBP', Importe Bruto Pesos
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_peso
  THEN    f.IMP_F_BRUTO
  ELSE    0
  END,
--02 'IMIP', Importe IVA Pesos
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_peso
  THEN    f.IMP_F_IVA
  ELSE    0
  END,
--03 'IMNP', Importe Neto Pesos
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_peso
  THEN    f.IMP_F_NETO
  ELSE    0
  END,
--04 'IMCP', Importe Complementario Pesos
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar
  THEN   (f.IMP_F_NETO * f.TIPO_CAMBIO) - f.IMP_F_NETO
  ELSE    0
  END,
--05 'IMBD', Importe Bruto Dólares
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar
  THEN    IMP_F_BRUTO  * f.TIPO_CAMBIO
  ELSE    0
  END,
--06 'IMID', Importe IVA Dólares
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar
  THEN    IMP_F_IVA * f.TIPO_CAMBIO
  ELSE    0
  END,
--07 'IMND', Importe Neto Dólares
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar
  THEN    f.IMP_F_NETO 
  ELSE    0
  END, 
--08 'CTCO', Cuenta Contable
  dbo.fnObtCtaContable(f.CVE_EMPRESA, c.ID_CLIENTE, f.CVE_F_MONEDA),
--09 'CTCM', Cuenta Contable Complementaria
  dbo.fnObtParAlfa(@k_cta_comp),
--10 'CTIN', Cuenta Contable Ingresos
  dbo.fnObtParAlfa(@k_cta_ingreso),
--11 'CTIV', Cuenta Contable IVA
  dbo.fnObtParAlfa(@k_cta_iva),
--12 'TCAM', Tipo de Cambio
  1,
--13 'DPTO', Departamento
  0,
--14 'PROY', Proyecto
  ' ',
--15 'CPTO', Concepto
  f.SERIE + CONVERT(VARCHAR(10), f.ID_CXC) + c.NOM_CLIENTE + CONVERT(VARCHAR(10), f.TIPO_CAMBIO),
-- Campos de trabajo
  f.SIT_TRANSACCION,
  f.F_OPERACION,
  f.CVE_F_MONEDA,
  c.NOM_CLIENTE,
  SERIE + '-' + CONVERT(VARCHAR(8),f.ID_CXC) + '-' + c.NOM_CLIENTE + '-' + CONVERT(VARCHAR(8),f.TIPO_CAMBIO)
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA          =  @pCveEmpresa   AND
          f.ID_VENTA   =  v.ID_VENTA       AND
          v.ID_CLIENTE =  c.ID_CLIENTE     AND
          f.SERIE      <>  @k_legada       AND                                         

        ((f.SIT_TRANSACCION      =  @k_activa                                   AND  
          f.F_OPERACION >= @f_inicio_mes and f.F_OPERACION <= @f_fin_mes)    OR

		 (f.SIT_TRANSACCION      =  @k_cancelada   AND
		  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes))               
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
  @sit_factura,
  @f_operacion,
  @cve_f_moneda,
  @nom_titular,
  @ident_transaccion  

-- select ' Termine Primer FETCH '     
  
--  SET  @imp_facturado  =  0
--  SET  @imp_fact_canc  =  0

  WHILE (@@fetch_status = 0 )
  BEGIN 
--  SELECT 'DB ** ENTRE A WHILE ** '
    IF   @sit_factura  =  @k_cancelada
	BEGIN
	  IF  dbo.fnArmaAnoMes (YEAR(@f_operacion), MONTH(@f_operacion))  < @pAnoMes
      BEGIN
        SET  @conc_movimiento  =  LTRIM(@conc_movimiento + '-CANCEL.ANT** ')
		IF   @cve_f_moneda  =  @k_peso
        BEGIN
          SET  @cve_oper_cont    =  @k_can_ma_pesos
 --         SET  @imp_fact_canc    =  @imp_fact_canc    +  @imp_bruto_p
        END
        ELSE
		BEGIN
          SET  @cve_oper_cont    =  @k_can_ma_dolar 
 --   	  SET  @imp_fact_canc    =  @imp_fact_canc    +  @imp_bruto_d
		END
      END
	  ELSE
	  BEGIN
        IF  @cve_f_moneda  =  @k_peso
        BEGIN
         SET  @cve_oper_cont    =  @k_can_mm_pesos  
--         SET  @imp_fact_canc    =  @imp_fact_canc  +  @imp_bruto_p
--         SET  @imp_facturado    =  @imp_facturado  +  @imp_bruto_p
        END
        ELSE
		BEGIN
          SET  @cve_oper_cont    =  @k_can_mm_dolar
--		  SET  @imp_fact_canc    =  @imp_fact_canc  +  @imp_bruto_d
-- 		  SET  @imp_facturado    =  @imp_facturado  +  @imp_bruto_d
		END
	  END
	END
    ELSE
    BEGIN
      IF  @cve_f_moneda    =  @k_dolar 
      BEGIN
	    SET  @cve_oper_cont  =  @k_fac_dolar
--		SET  @imp_facturado  =  @imp_facturado  +  @imp_bruto_d
	  END
      ELSE
	  BEGIN
	    SET  @cve_oper_cont  =  @k_fac_pesos
--		SET  @imp_facturado  =  @imp_facturado  +  @imp_bruto_p
      END
    END

--	select 'DB Voy a crear transaccion '
   
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
    @sit_factura,
    @f_operacion,
    @cve_f_moneda,
    @nom_titular,
    @ident_transaccion
  END
  
  CLOSE cur_transaccion
  DEALLOCATE cur_transaccion

-- Actualiza Información para cálculo de indicadores
  
--  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ind_factura, @k_no_act, @imp_facturado
--  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ind_fact_can, @k_no_act, @imp_fact_canc 

  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90

--  SELECT ' ** REGISTRO DE IMPUESTOS **'

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error Transacciones Facturacion ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

