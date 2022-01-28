USE [ADMON01]
GO
--exec spTranFacturacion 'CU', 'MARIO', '201902', 4, 5, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
SET XACT_ABORT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spTranFacturacion')
DROP PROCEDURE [dbo].[spTranFacturacion]
GO
CREATE PROCEDURE spTranFacturacion 
  (
  @pIdCliente     int,
  @pCveEmpresa    varchar(4),
  @pCodigoUsuario varchar(20),
  @pCveAplicacion varchar(10),
  @pAnoPeriodo    varchar(6),
  @pIdProceso     numeric(9),
  @pFolioExe      int,
  @pIdTarea       numeric(9),
  @pBError        bit OUT,
  @pError         varchar(80) OUT,
  @pMsgError      varchar(400) OUT
)	
AS
BEGIN
-- Datos de la Transacción
  
--  DECLARE @LISTA AS VALOR_ALFA

  DECLARE
  @id_transac          int,
  @nom_titular         varchar(120),
  @cve_oper_cont       varchar(6),
  @tx_nota             varchar(250)

  DECLARE
  @imp_fact_ind     numeric(16,2)  =  0,
  @imp_fact_ind_can numeric(16,2)  =  0,
  @imp_iva_ind      numeric(16,2)  =  0,
  @imp_iva_ind_can  numeric(16,2)  =  0,
  @imp_neto_p_op    numeric(16,2)  =  0
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

  DECLARE  @k_activa          varchar(1)   =  'A',
           @k_cancelada       varchar(1)   =  'C',
           @k_legada          varchar(6)   =  'LEGACY',
           @k_peso            varchar(1)   =  'P',
           @k_dolar           varchar(1)   =  'D',
           @k_falso           bit          =  0,
           @k_verdadero       bit          =  1,
		   @k_cta_comp        varchar(10)  =  'CTACTECOMP',
		   @k_error           varchar(1)   =  'E',
		   @k_no_act          numeric(9,0) =  99999,
           @k_ind_factura     varchar(10)  =  'FACAING',
       	   @k_ind_fact_can    varchar(10)  =  'FACBING',
           @k_ind_iva         varchar(10)  =  'FACAIVA',
		   @k_ind_iva_can     varchar(10)  =  'FACBIVA',
		   @k_cta_utilidad    varchar(10)  =  'CTAGANCAM',
           @k_cta_perdida     varchar(10)  =  'CTAPERCAM',
		   @k_util_canc       varchar(6)   =  'FCGA',
		   @k_perd_canc       varchar(6)   =  'FCPE',
		   @k_util_camb       varchar(10)  =  'UTILC',
		   @k_can_util_camb   varchar(10)  =  'CANUTIL',
-- Constantes para folios
		   @k_cta_iva         varchar(10)  =  'CTAIVA',
		   @k_cta_ingreso     varchar(10)  =  'CTAINGRESO',
   		   @k_id_transaccion  varchar(4)   =  'TRAC',

-- Claves de operación para transacciones
		   @k_fac_pesos       varchar(6)   =  'FACP',
		   @k_fac_dolar       varchar(6)   =  'FACD',
		   @k_can_mm_pesos    varchar(6)   =  'FCMP',
           @k_can_mm_dolar    varchar(6)   =  'FCMD',
           @k_can_ma_pesos    varchar(6)   =  'FCAP',
           @k_can_ma_dolar    varchar(6)   =  'FCAD',

-- Claves de operaciòn para registro de campos para càlculo de ISR
           @k_ing_factura     varchar(6)   =  'INGFAC' ,
           @k_fac_cancel      varchar(6)   =  'FACCAN'

  BEGIN TRY

  EXEC spBorraTransac  @pCveEmpresa, @pAnoPeriodo, @pIdProceso
                       
  SET  @gpo_transaccion  =  @pFolioExe  
  
-- Obten datos del periodo contable
  
  SELECT @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL,  @tipo_cam_f_mes =  TIPO_CAM_F_MES
  from CI_PERIODO_CONTA  where ANO_MES  =  @pAnoPeriodo
  
  SET  @f_dia  =  GETDATE()

  DECLARE cur_transaccion CURSOR LOCAL FORWARD_ONLY STATIC FOR SELECT
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
  WHEN    f.CVE_F_MONEDA  =  @k_dolar  AND  f.SIT_TRANSACCION  =  @k_activa
  THEN   (f.IMP_F_NETO *
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
                     f.F_OPERACION, f.CVE_F_MONEDA)) - 
  f.IMP_F_NETO
  WHEN    f.CVE_F_MONEDA  =  @k_dolar  AND  f.SIT_TRANSACCION  =  @k_cancelada
  THEN   (f.IMP_F_NETO * dbo.fnObtTipoCamCan(@pCveEmpresa, @pAnoPeriodo, f.CVE_F_MONEDA) - f.IMP_F_NETO)
  ELSE    0
  END,
--05 'IMBD', Importe Bruto Dólares	
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar AND  f.SIT_TRANSACCION  =  @k_activa 
  THEN    IMP_F_BRUTO  *
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
                     f.F_OPERACION, f.CVE_F_MONEDA)
  WHEN    f.CVE_F_MONEDA  =  @k_dolar AND  f.SIT_TRANSACCION  =  @k_cancelada
  THEN    IMP_F_BRUTO  *
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
  f.F_OPERACION, f.CVE_F_MONEDA)
  ELSE    0
  END,
--06 'IMID', Importe IVA Dólares
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar  AND  f.SIT_TRANSACCION  =  @k_activa 
  THEN    IMP_F_IVA * 
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
                     f.F_OPERACION, f.CVE_F_MONEDA)
  WHEN    f.CVE_F_MONEDA  =  @k_dolar  AND  f.SIT_TRANSACCION  =  @k_cancelada 
  THEN    IMP_F_IVA * 
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
                     f.F_OPERACION, f.CVE_F_MONEDA)
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
  CASE
  WHEN    f.CVE_F_MONEDA  =  @k_dolar AND  f.SIT_TRANSACCION  =  @k_activa 
  THEN    
  UUID + ' ' +
  ISNULL(f.SERIE_CTE,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + ' ' +
  ISNULL(c.NOM_CLIENTE,0) + ' ' +
  ISNULL(f.SIT_TRANSACCION,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoPeriodo, f.F_OPERACION, f.CVE_F_MONEDA)),0) + ' '
  WHEN    f.CVE_F_MONEDA  =  @k_dolar AND  f.SIT_TRANSACCION  =  @k_cancelada
  THEN    
  UUID + ' ' +
  ISNULL(f.SERIE_CTE,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + ' ' +
  ISNULL(c.NOM_CLIENTE,0)  + ' ' + 
  f.SIT_TRANSACCION + ' ' +
  ISNULL(CONVERT(VARCHAR(10), dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoPeriodo, f.F_OPERACION, f.CVE_F_MONEDA)),0) + ' '
  ELSE  
  ISNULL(f.SERIE_CTE,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + ' ' +
  ISNULL(c.NOM_CLIENTE,' ')  + ' ' + 
  f.SIT_TRANSACCION + ' ' 
  END,
-- Campos de trabajo
  f.SIT_TRANSACCION,
  f.F_OPERACION,
  f.CVE_F_MONEDA,
  c.NOM_CLIENTE,
  ISNULL(f.SERIE_CTE,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + ' ' +
  c.NOM_CLIENTE + '-' +
  CONVERT(VARCHAR(8),dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoPeriodo, f.F_OPERACION, f.CVE_F_MONEDA))
  FROM    CI_CUENTA_X_COBRAR f, CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa   AND
          f.ID_CLIENTE    =  c.ID_CLIENTE   AND
          f.SERIE_CTE    <>  @k_legada      AND                                         
        ((f.SIT_TRANSACCION      =  @k_activa                                   AND  
          f.F_OPERACION >= @f_inicio_mes and f.F_OPERACION <= @f_fin_mes)    OR

		 (f.SIT_TRANSACCION      =  @k_cancelada   AND
		  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoPeriodo))               
  -----
  UNION
  SELECT
--01 'IMBP', Importe Bruto Pesos
  0,
--02 'IMIP', Importe IVA Pesos
  0,
--03 'IMNP', Importe Neto Pesos
 (f.IMP_F_NETO * dbo.fnObtTipoCamCan(@pCveEmpresa, @pAnoPeriodo, f.CVE_F_MONEDA) -  f.IMP_F_NETO) -
 (f.IMP_F_NETO *
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
  f.F_OPERACION, f.CVE_F_MONEDA) -  f.IMP_F_NETO),
--04 'IMCP', Importe Complementario Pesos
  0,
--05 'IMBD', Importe Bruto Moneda Extranjera
  0,
--06 'IMID', Importe IVA Moneda Extranjera
  0,
--07 'IMND', Importe Neto Moneda Extranjera
  0,
--08 'CTCO', Cuenta Contable
  CASE
  WHEN
 (f.IMP_F_NETO * dbo.fnObtTipoCamCan(@pCveEmpresa, @pAnoPeriodo, f.CVE_F_MONEDA) -  f.IMP_F_NETO) -
 (f.IMP_F_NETO *
  dbo.fnObtTipoCambC(@pCveEmpresa, dbo.fnObtAnoMesFact(@pAnoPeriodo, f.SIT_TRANSACCION,f.F_OPERACION),
  f.F_OPERACION, f.CVE_F_MONEDA) -  f.IMP_F_NETO) > 0
  THEN  dbo.fnObtParAlfa(@k_cta_utilidad)
  ELSE
  dbo.fnObtParAlfa(@k_cta_perdida)
  END,
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
  UUID + ' ' +
  ISNULL(f.SERIE_CTE,0) + ' ' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + ' ' +
  ISNULL(c.NOM_CLIENTE,' ') + ' ' +
  f.SIT_TRANSACCION + ' ',
-- Campos de trabajo
  f.SIT_TRANSACCION,
  f.F_OPERACION,
  f.CVE_F_MONEDA,
  c.NOM_CLIENTE,
  UUID + '-' +
  ISNULL(f.SERIE_CTE,0) + '-' +
  ISNULL(CONVERT(VARCHAR(10), f.FOLIO_CTE),0) + '-' +
  c.NOM_CLIENTE + '-' +
  CONVERT(VARCHAR(8),dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoPeriodo, f.F_OPERACION, f.CVE_F_MONEDA))
  FROM    CI_CUENTA_X_COBRAR f, CI_CLIENTE c
  WHERE   f.CVE_EMPRESA          =  @pCveEmpresa   AND
          f.ID_CLIENTE           =  c.ID_CLIENTE   AND
          f.SERIE_CTE           <>  @k_legada      AND
		  f.CVE_F_MONEDA         =  @k_dolar        AND                                        
		 (f.SIT_TRANSACCION      =  @k_cancelada   AND
		  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoPeriodo  AND
		  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION)  , MONTH(f.F_OPERACION))    < @pAnoPeriodo)
		  
-------

--  EXEC spActPctTarea @pIdTarea, 30
  
  OPEN  cur_transaccion
  
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

  WHILE (@@fetch_status = 0 )
  BEGIN 
    IF  @cta_contable  NOT IN (dbo.fnObtParAlfa(@k_cta_utilidad), dbo.fnObtParAlfa(@k_cta_perdida))
    BEGIN

    IF   @sit_factura  =  @k_cancelada
	BEGIN
      SET  @imp_fact_ind_can  =  @imp_fact_ind_can  +    @imp_bruto_p + @imp_bruto_d
      SET  @imp_iva_ind_can   =  @imp_iva_ind_can   +    @imp_iva_p + @imp_iva_d

	  IF  dbo.fnArmaAnoMes (YEAR(@f_operacion), MONTH(@f_operacion))  < @pAnoPeriodo
      BEGIN
        SET  @conc_movimiento  =  LTRIM(@conc_movimiento + '-CANCEL.ANT** ')
		IF   @cve_f_moneda  =  @k_peso
        BEGIN
		  SET  @cve_oper_cont    =  @k_can_ma_pesos
        END
        ELSE
		BEGIN
          SET  @cve_oper_cont    =  @k_can_ma_dolar 
		END
      END
	  ELSE
	  BEGIN
        SET  @imp_fact_ind  =  @imp_fact_ind  +    @imp_bruto_p + @imp_bruto_d
        SET  @imp_iva_ind   =  @imp_iva_ind   +    @imp_iva_p   + @imp_iva_d
        SET  @conc_movimiento  =  LTRIM(@conc_movimiento + '-(F) O (C) MES ** ')      
	    IF   @cve_f_moneda  =  @k_peso
        BEGIN
         SET  @cve_oper_cont    =  @k_can_mm_pesos  
        END
        ELSE
		BEGIN
          SET  @cve_oper_cont    =  @k_can_mm_dolar
		END
	  END
	END
    ELSE
    BEGIN
      SET  @imp_fact_ind  =  @imp_fact_ind  +    @imp_bruto_p + @imp_bruto_d
      SET  @imp_iva_ind   =  @imp_iva_ind   +    @imp_iva_p   + @imp_iva_d

      IF  @cve_f_moneda    =  @k_dolar 
      BEGIN
	    SET  @cve_oper_cont  =  @k_fac_dolar
	  END
      ELSE
	  BEGIN
	    SET  @cve_oper_cont  =  @k_fac_pesos
      END
    END

	END
    ELSE
	BEGIN
	  IF  @imp_neto_p  >  0
	  BEGIN
        SET  @imp_neto_p_op  =  @imp_neto_p *  -1 
        UPDATE CI_PERIODO_ISR SET IMP_CANC_UTILIDAD = 0 WHERE
		CVE_EMPRESA = @pCveEmpresa  AND
		ANO_MES     = @pAnoPeriodo

	    EXEC spInsIsrItem @pCveEmpresa, @pAnoPeriodo,  @k_can_util_camb,  @imp_neto_p
		SET  @cve_oper_cont  =  @k_util_canc
	  END
	  ELSE
	  BEGIN
	    SET  @cve_oper_cont  =  @k_perd_canc
	  END
	  SET  @imp_neto_p  =    ABS(@imp_neto_p) * -1
	END

    SET @tx_nota     =  0
	SET @id_transac  =  0
  
    UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_transaccion
    SET  @id_transac  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_transaccion)   
    EXEC  spCreaTransaccionCont
    @pIdProceso,
    @pIdTarea,
    @id_transac,
    @pCodigoUsuario,
    @pCveEmpresa,
    @pAnoPeriodo,
    @cve_oper_cont,
    @f_dia,
    @ident_transaccion,
    @nom_titular,
    @tx_nota,
    @gpo_transaccion,
    @pError OUT,
    @pMsgError OUT

    EXEC spLanzaCreaConTrans
    @pIdProceso,
    @pIdTarea,
    @pCveEmpresa,
    @pAnoPeriodo,
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

	EXEC spActPctTarea
    @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, 50

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
  IF  @cta_contable  NOT IN (@k_cta_utilidad, @k_cta_perdida)
  BEGIN

    EXEC spInsIndicador @pCveEmpresa, @pAnoPeriodo, @k_ind_factura,  @imp_fact_ind, @k_no_act 
    EXEC spInsIndicador @pCveEmpresa, @pAnoPeriodo, @k_ind_fact_can, @imp_fact_ind_can, @k_no_act 
    EXEC spInsIndicador @pCveEmpresa, @pAnoPeriodo, @k_ind_iva,  @imp_iva_ind, @k_no_act 
    EXEC spInsIndicador @pCveEmpresa, @pAnoPeriodo, @k_ind_iva_can, @imp_iva_ind_can, @k_no_act 

    EXEC spInsIsrItem @pCveEmpresa, @pAnoPeriodo,  @k_ing_factura, @imp_fact_ind
    EXEC spInsIsrItem @pCveEmpresa, @pAnoPeriodo,  @k_fac_cancel, @imp_fact_ind_can

    EXEC spActPctTarea
    @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, 90

  END

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  '(E) Carga Tran. Facturacion ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END

