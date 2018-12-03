USE [ADNOMINA01]
GO
/****** Calcula cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalCuotaImms] (@pIdCliente       int,
                                         @pCveEmpresa      varchar(4),
									     @pIdEmpleado      int,
								         @pCveTipoNomina   varchar(2),
									     @pAnoPeriodo      varchar(6),
									     @pSdoEmpleado     numeric(16,2),
									     @pDiasTrabajados  int,
					                     @pDiasIncapacidad int,
					                     @pDiasFaltas      int,
                                         @pFactIntegracion numeric(8,4),
					                     @pSalarioMinimo   numeric(16,2),
AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @sal_dia_bim_ant   numeric(16,2),
           @imp_sbc           numeric(16,2),
		   @imp_sdi_fijo      numeric(16,6),
		   @imp_sbc_fijo      numeric(16,6),
		   @imp_sdi_mixto     numeric(16,6),
		   @dias_mes_periodo  int


  DECLARE  @prop_dia_aguin    numeric(8,4),
		   @prop_dia_prima    numeric(8,4),
		   @f_act_integracion numeric(8,4)

  DECLARE  @sal_bim_ant       numeric,
		   @sdo_dia_bim_ant   numeric,
           @dias_bim_ant      int,
           @incap_bim_ant     int,
		   @faltas_Bim_ant    int

  DECLARE  @cve_entidad       varchar(4),
		   @id_ramo           int,
		   @id_concepto       int)

  EXEC spCalcFactNomina    @pIdCliente,       
                           @pCveEmpresa,      
						   @pIdEmpleado,      
						   @pCveTipoNomina,   
						   @pAnoPeriodo,      
                           @prop_dia_aguin OUT,
						   @prop_dia_prima OUT,
						   @f_act_integracion OUT


  EXEC spCalcInfBimAnt     @pIdCliente,
                           @pCveEmpresa,
						   @pIdEmpleado,
						   @pCveTipoNomina,
						   @pAnoPeriodo,
                           @sal_bim_ant OUT,
						   @sdo_dia_bim_ant OUT,
                           @dias_bim_ant OUT,
                           @incap_bim_ant OUT,
						   @faltas_Bim_ant OUT

  SELECT  @dias_mes_periodo  
  ID_CLIENTE        =  @pIdCliente   
  CVE_EMPRESA       =  @pCveEmpresa
  CVE_TIPO_NOMINA   =  @pCveTipoNomina
  ANO_PERIODO       =  @pAnoPeriodo
  
  SET  @sal_dia_bim_ant   =  @sal_bim_ant / (@sdo_dia_bim_ant - @incap_bim_ant - @faltas_Bim_ant)	

  SET  @pSdoEmpleado  =  ISNULL(@pSdoEmpleado,0)
   
  SET  @imp_sdi_fijo  =  @pSdoEmpleado * @f_act_integracion      
  SET  @imp_sbc_fijo  =  @imp_sdi_fijo / @dias_mes_periodo    
  SET  @imp_sdi_mixto =  @sdo_dia_bim_ant +  @imp_sdi_fijo
  
  INSERT  INTO  NO_CONC_OBRERO_PAT 
 (ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_EMPLEADO,
  IMP_PROP_D_AGUI,
  IMP_PROP_D_PV,
  FACT_INTEGRACION,
  IMP_PERC_B_ANT,
  DIAS_BIM_ANT,
  IMP_SAL_DIA_B_ANT,
  SUELDO_MENSUAL,
  IMP_SDI_FIJO,
  DIAS_MES,
  IMP_SBC_FIJO,
  IMP_SBC_MIXTO)  VALUES
 (@pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pIdEmpleado,
  @prop_dia_aguin,
  @prop_dia_prima,
  @f_act_integracion,
  @sal_bim_ant,
  @dias_bim_ant,
  @sal_dia_bim_ant,
  @pSdoEmpleado,
  @imp_sdi_fijo,
  @dias_mes_periodo,
  @imp_sbc_fijo,
  @imp_sdi_mixto)  

-------------------------------------------------------------------------------
-- Calculo de Conceptos para IMSS
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TConcImss         TABLE
          (RowID             int  identity(1,1),
		   CVE_ENTIDAD       varchar(4),
		   ID_RAMO           int,
		   ID_CONCEPTO       int)

  INSERT  @TConcImss (CVE_ENTIDAD, ID_RAMO, ID_CONCEPTO) 
  SELECT  c.CVE_ENTIDAD, c.ID_RAMO, @c.ID_CONCEPTO
  FROM    NO_CONC_CUOTA c

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_entidad = c.CVE_ENTIDAD, @id_ramo = c.ID_RAMO, @id_concepro = c.ID_CONCEPTO
	FROM   @TPeriodo  WHERE  RowID = @RowCount

	spCalCuotObrPat  @pAnoPeriodo,      
                     @pIdCliente,
					 @pCveEmpresa,
					 @pIdEmpleado,
                     @pCveEntidad,
                     @pIdRamo,
					 @pIdConcepto,
					 dias_mes_periodo,
					 @pDiasTrabajados,
					 @pDiasIncapacidad,
					 @pDiasFaltas,
                     @pFactIntegracion,
					 @pSalarioMinimo,
                     @pCuotaObrero,
                     @pCuotaPatron,
					 @pBCorrecto   

    SET @RowCount     = @RowCount + 1


END

