USE [ADNOMINA01]
GO
/****** Calcula SBC para cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalculaSBC')
BEGIN
  DROP  PROCEDURE spCalculaSBC
END
GO
--EXEC spCalculaSBC 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '
CREATE PROCEDURE [dbo].[spCalculaSBC] 
(
@pIdProceso       int,
@pIdTarea         int,
@pCveUsuario      varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pSdoEmpleado     numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @imp_sbc           numeric(16,2)  = 0,
		   @imp_sdi_fijo      numeric(16,6)  = 0,
		   @imp_sbc_fijo      numeric(16,6)  = 0,
		   @imp_sbc_mixto     numeric(16,6)  = 0,
		   @dias_mes_periodo  int

  DECLARE  @prop_dia_aguin    numeric(8,4)   = 0,
		   @prop_dia_prima    numeric(8,4)   = 0,
		   @f_act_integracion numeric(8,4)   = 0

  DECLARE  @sal_bim_ant       numeric(16,2)  = 0,
		   @sdo_dia_bim_ant   numeric(16,6)  = 0,
           @dias_bim_ant      int            = 0,
           @incap_bim_ant     int            = 0,
		   @faltas_bim_ant    int            = 0

  DECLARE  @k_error           varchar(1)     = 'E'

  DELETE  FROM  NO_DET_CONC_OB_PAT  WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado

  DELETE  NO_CONC_OBRERO_PAT WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado

  EXEC spCalcFactNomina         
  @pIdProceso,
  @pIdTarea,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,  
  @pAnoPeriodo,
  @pIdEmpleado,
  @prop_dia_aguin OUT,
  @prop_dia_prima OUT,
  @f_act_integracion OUT,
  @pError OUT,
  @pMsgError OUT

  EXEC spCalcInfBimAnt     
  @pIdProceso,
  @pIdTarea,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @sal_bim_ant OUT,
  @sdo_dia_bim_ant OUT,
  @dias_bim_ant OUT,
  @incap_bim_ant OUT,
  @faltas_bim_ant OUT,
  @pError OUT,
  @pMsgError OUT

  --SELECT '1*' + CONVERT(VARCHAR(18),@sal_bim_ant)
  --SELECT '2*' + CONVERT(VARCHAR(18),@sdo_dia_bim_ant)
  --SELECT '3*' + CONVERT(VARCHAR(18),@incap_bim_ant)
  --SELECT '4*' + CONVERT(VARCHAR(18),@faltas_bim_ant)
  
  SET  @pSdoEmpleado  =  ISNULL(@pSdoEmpleado,0)
  
  SELECT @dias_mes_periodo = NUM_DIAS_PERIODO  FROM  NO_PERIODO
  WHERE  ID_CLIENTE      =  @pIdCliente  AND
         CVE_EMPRESA     =  @pCveEmpresa AND
		 CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		 ANO_PERIODO     =  @pAnoPeriodo
   
  SET  @imp_sdi_fijo  =  @pSdoEmpleado * @f_act_integracion      
  SET  @imp_sbc_fijo  =  @imp_sdi_fijo / @dias_mes_periodo    
  SET  @imp_sbc_mixto =  @sdo_dia_bim_ant +  @imp_sbc_fijo

  BEGIN TRY
  
  INSERT  INTO  NO_CONC_OBRERO_PAT 
 (ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  IMP_PROP_D_AGUI,
  IMP_PROP_D_PV,
  FACT_INTEGRACION,
  IMP_PERC_B_ANT,
  DIAS_BIM_ANT,
  IMP_SAL_DIA_B_ANT,
  SUELDO_MENSUAL,
  IMP_SDI_FIJO,
  DIAS_MES,
  DIAS_FALT_B_ANT,
  DIAS_INCA_B_ANT,
  IMP_SBC_FIJO,
  IMP_SBC_MIXTO)  VALUES
 (@pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pIdEmpleado,
  @pCveTipoNomina,
  @prop_dia_aguin,
  @prop_dia_prima,
  @f_act_integracion,
  @sal_bim_ant,
  @dias_bim_ant,
  @sdo_dia_bim_ant,
  @pSdoEmpleado,
  @imp_sdi_fijo,
  @dias_mes_periodo,
  @faltas_bim_ant,
  @incap_bim_ant,
  @imp_sbc_fijo,
  @imp_sbc_mixto)  

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Insert SBC. IMSS ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento
	@pIdCliente, @pCveEmpresa, @pCveAplicacion, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  EXEC spCalCuotaImms
  @pIdProceso,
  @pIdTarea,
  @pCveUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @imp_sbc_mixto,
  @pError OUT,
  @pMsgError OUT

END
