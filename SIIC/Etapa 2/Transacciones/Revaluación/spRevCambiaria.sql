USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spRevCambiaria]    Script Date: 08/05/2018 03:20:08 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
-- exec spRevCambiaria 'CU', 'MARIO', '201902', 13, 1, ' ', ' '
ALTER PROCEDURE [dbo].[spRevCambiaria] @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                               @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
							   @pMsgError varchar(400) OUT

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
		 
  DECLARE @k_activa          varchar(1)  =  'A',
          @k_cancelada       varchar(1)  =  'C',
		  @k_operativo       varchar(1)  =  'O',
          @k_legada          varchar(6)  =  'LEGACY',
          @k_peso            varchar(1)  =  'P',
          @k_dolar           varchar(1)  =  'D',
          @k_falso           bit         =  0,
          @k_verdadero       bit         =  1, 
		  @k_error           varchar(1)  =  'E',
		  @k_conc_total      varchar(2)  =  'CC',
		  @k_con_error       varchar(2)  =  'CE',

  
-- Constantes para folios

		  @k_cta_iva         varchar(10) =  'CTAIVA',
		  @k_per_cambiaria   varchar(10) =  'CTAPERCAM',
   		  @k_gan_cambiaria   varchar(10) =  'CTAGANCAM',
		  @k_cta_comp        varchar(10) =  'CTACTECOMP',
   		  @k_id_transaccion  varchar(4)  =  'TRAC',
		  @k_gpo_transac     varchar(4)  =  'GPOT',
          @k_util_camb       varchar(6)  =  'UTILC',

-- Claves de operación para transacciones

		   @k_perdida        varchar(6)  =  'RVCP',
		   @k_utilidad       varchar(6)  =  'RVCG'

  DECLARE @imp_dolares      numeric(12,2)  =  0,
          @imp_valua_dolar  numeric(12,2)  =  0,
		  @imp_tot_com_cmes numeric(12,2)  =  0,
          @imp_tot_comp     numeric(12,2)  =  0,
          @imp_renovacion   numeric(12,2)  =  0,
		  @imp_mes_ant      numeric(12,2)  =  0,
		  @tipo_cam_f_mes   numeric(8,4)   =  0

  DECLARE @k_no_concilia   varchar(2)  =  'NC',
	      @k_conc_par_ct   varchar(2)   = 'PC',
		  @k_conc_despues  varchar(2)   = 'CD',
		  @k_conc_antes    varchar(2)   = 'CA',
		  @k_conc_par_nc   varchar(2)   = 'PN',
		  @k_no_cxc        int          = 0,
   		  @k_cxc_sdo_ini   int          = 9,
  		  @k_f_dummy       varchar(10)  = '1900-01-01',
		  @k_mes_ant       varchar(4)   = 'MANT',
		  @k_cxc           varchar(4)   = 'CXC',
		  @k_val_usd       varchar(4)   = 'VUSD',
		  @k_revaluacion   varchar(4)   = 'REVA',
		  @k_tipo_cxc      varchar(1)   = 'C'

  DECLARE @REVALUACION TABLE
  (CVE_EMPRESA      varchar(4),
   ID_CXC           int,
   CVE_CHEQUERA     varchar(6),
   F_OPERACION      date,
   IMP_NETO         numeric(12,2),
   TIPO_CAMBIO      NUMERIC(8,4),
   IMP_COMPLENTARIA numeric(12,2))

 -- Borra transacciones creadas con anterioridad

  DELETE FROM CI_BIT_REV_CAMBIARIA  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
                                          CVE_TIPO     =  @k_tipo_cxc   


  IF  (SELECT CVE_TIPO_VAL FROM CI_PERIODO_CONTA WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes) =
       @k_operativo
  BEGIN
    SET  @imp_mes_ant =  
   (SELECT  SUM(IMP_RENOVACION)  FROM CI_PERIODO_CONTA
    WHERE
    CVE_EMPRESA  =  @pCveEmpresa  AND
    ANO_MES      <  @pAnoMes)
  END
  ELSE
  BEGIN
    SET  @imp_mes_ant = 0
  END
   
  INSERT  @REVALUACION  (CVE_EMPRESA, ID_CXC, CVE_CHEQUERA, F_OPERACION, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA) VALUES
  (@pCveEmpresa, @k_cxc_sdo_ini, ' ', @k_f_dummy, 0,  0, @imp_mes_ant)

  INSERT  @REVALUACION  (CVE_EMPRESA, ID_CXC, CVE_CHEQUERA, F_OPERACION, IMP_NETO, TIPO_CAMBIO, IMP_COMPLENTARIA)
 
  SELECT    
  f.CVE_EMPRESA,
  f.ID_CXC,
  ' ',
  f.F_OPERACION,
  f.IMP_F_NETO, 
  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, f.F_OPERACION),
  (f.IMP_F_NETO * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, f.F_OPERACION)) - f.IMP_F_NETO 
  FROM CI_FACTURA f     
  WHERE dbo.fnObtSitCxC(f.ID_CONCILIA_CXC, @pAnoMes)    IN (@k_conc_par_ct, @k_conc_par_nc, @k_no_concilia, @k_conc_despues) and    
        dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  <= @pAnoMes AND
       ((f.SIT_TRANSACCION     = @k_activa) OR
		(f.SIT_TRANSACCION     = @k_CANCELADA  AND 
         dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes)) AND
		 f.CVE_F_MONEDA        =   @k_dolar and    
         f.SERIE <> @k_legada

  INSERT  CI_BIT_REV_CAMBIARIA
  (CVE_EMPRESA, ANO_MES, CVE_TIPO, CVE_CONCEPTO, ID_CXC, CVE_CHEQUERA, F_OPERACION, IMP_NETO, TIPO_CAMBIO, IMP_COMPLEMENTARIA) 
   SELECT @pCveEmpresa, @pAnoMes, @k_tipo_cxc,
   CASE
   WHEN ID_CXC = @k_cxc_sdo_ini
   THEN @k_mes_ant 
   ELSE @k_cxc
   END, 
   ID_CXC, ' ', F_OPERACION, IMP_NETO, TIPO_CAMBIO, (IMP_COMPLENTARIA)
   FROM @REVALUACION ORDER BY ID_CXC DESC

 --  Calcula complementaria por cada CXC, considerando los acumulados del mes
  
--  SELECT @@ROWCOUNT

  SET  @imp_tot_comp    = (SELECT SUM(IMP_COMPLENTARIA)  FROM  @REVALUACION)   

 -- Calcula la valución de la complementaria valuada a cierre de mes 

  SET  @imp_dolares = (SELECT SUM(IMP_NETO)  FROM  @REVALUACION)  
       
  SET  @tipo_cam_f_mes  =  (SELECT TIPO_CAM_F_MES FROM  CI_PERIODO_CONTA  WHERE
						   CVE_EMPRESA  =  @pCveEmpresa  AND
						   ANO_MES      =  @pAnoMes)
  SET @tipo_cam_f_mes   =  ISNULL(@tipo_cam_f_mes,0)

  SET  @imp_valua_dolar = @imp_dolares * @tipo_cam_f_mes

  SET  @imp_tot_com_cmes  =  @imp_valua_dolar - @imp_dolares 

-- Calcula importe de renovación del mes

  SET  @imp_renovacion  =  @imp_tot_com_cmes -  @imp_tot_comp

  INSERT  CI_BIT_REV_CAMBIARIA
  (CVE_EMPRESA, ANO_MES, CVE_TIPO, CVE_CONCEPTO, ID_CXC, CVE_CHEQUERA, F_OPERACION, IMP_NETO, TIPO_CAMBIO, IMP_COMPLEMENTARIA) VALUES
 (@pCveEmpresa, @pAnoMes, @k_tipo_cxc, @k_val_usd, @k_no_cxc, ' ', @k_f_dummy, @imp_dolares, @tipo_cam_f_mes, @imp_tot_com_cmes)

  SET  @imp_renovacion  =
 (SELECT SUM(IMP_COMPLEMENTARIA)  FROM  CI_BIT_REV_CAMBIARIA  WHERE
         CVE_EMPRESA  =  @pCveEmpresa  AND
	     ANO_MES      =  @pAnoMes      AND
	     CVE_TIPO     =  @k_tipo_cxc        AND
	     CVE_CONCEPTO = @k_val_usd)   -
 (SELECT SUM(IMP_COMPLEMENTARIA)  FROM  CI_BIT_REV_CAMBIARIA  WHERE
         CVE_EMPRESA  =  @pCveEmpresa  AND
	     ANO_MES      =  @pAnoMes      AND
	     CVE_TIPO     =  @k_tipo_cxc        AND
	     CVE_CONCEPTO <>  @k_val_usd)   
		      
  INSERT  CI_BIT_REV_CAMBIARIA
  (CVE_EMPRESA, ANO_MES, CVE_TIPO, CVE_CONCEPTO, ID_CXC, CVE_CHEQUERA, F_OPERACION, IMP_NETO, TIPO_CAMBIO, IMP_COMPLEMENTARIA) VALUES
 (@pCveEmpresa, @pAnoMes, @k_tipo_cxc, @k_revaluacion, @k_no_cxc, ' ', @k_f_dummy, 0, 0, @imp_renovacion)

  UPDATE CI_PERIODO_CONTA SET IMP_RENOVACION = @imp_renovacion  WHERE ANO_MES = @pAnoMes
 
   IF  @imp_renovacion  >  0  
  BEGIN
    SET @cve_oper_cont =  @k_utilidad
    EXEC spInsIsrItem @pCveEmpresa, @pAnoMes,  @k_util_camb, @imp_renovacion
  END
  ELSE
  BEGIN
    SET @cve_oper_cont =  @k_perdida  END
  
  --01 'IMBP', Importe Bruto Pesos
  SET  @imp_bruto_p  =  0
--02 'IMIP', Importe IVA Pesos
  SET  @imp_iva_p    =  0
--03 'IMNP', Importe Neto Pesos
  SET  @imp_neto_p   =  ABS(@imp_renovacion)
--04 'IMCP', Importe Complementario Pesos
  SET @imp_comp_p    =  0
--05 'IMBD', Importe Bruto Dólares
  SET @imp_bruto_d   =  0
--06 'IMID', Importe IVA Dólares
  SET @imp_iva_d     =  0
--07 'IMND', Importe Neto Dólares
  SET @imp_neto_d    =  0
--08 'CTCO', Cuenta Contable
  IF  @cve_oper_cont =  @k_utilidad
  BEGIN
    SET @cta_contable  =  dbo.fnObtParAlfa(@k_gan_cambiaria)
  END
  ELSE
  BEGIN
    SET @cta_contable  =  dbo.fnObtParAlfa(@k_per_cambiaria)
  END 
--09 'CTCM', Cuenta Contable Complementaria
  SET @cta_contable_comp = dbo.fnObtParAlfa(@k_cta_comp )
--10 'CTIN', Cuenta Contable Ingresos
  SET @cta_contable_ing  =  ' '
--11 'CTIV', Cuenta Contable IVA
  SET @cta_contable_iva  =  ' '
--12 'TCAM', Tipo de Cambio
  SET @tipo_cambio     = 1
--13 'DPTO', Departamento
  SET @departamento  = 0
--14 'PROY', Proyecto
  SET @proyecto  =  ' '
--15 'CPTO', Concepto
  SET @conc_movimiento  =  'Valuación Moneda Extranjera' + ' ' + @pAnoMes

  EXEC spBorraTransac  @pCveEmpresa, @pAnoMes, @pIdProceso
  
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

  INSERT FC_GEN_PROCESO_BIT (CVE_EMPRESA, ID_PROCESO, FT_PROCESO, GPO_TRANSACCION) 
  VALUES
  (@pCveEmpresa,
   @pIdProceso, 
   @pAnoMes + '00',
   @gpo_transaccion)

  SET  @f_dia  =  GETDATE()

  SET  @ident_transaccion  =  @pAnoMes
  SET  @nom_titular  =  'REVALUACION CAMBIARIA CTES'
  SET  @tx_nota  =  ' '

  --	select ' Voy a crear transaccion '
   
  SET @id_transac  =  0
  
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_transaccion
  SET  @id_transac  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_transaccion)   
-- SELECT ' **** VOY A INSERTAR TRANSACCION ** '

  BEGIN TRY

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

  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error de Ejecucion Proceso Renovación Cambiaria'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END