USE [ADNOMINA01]
GO
/****** Calcula SBC para cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalculaSBC] (@pIdCliente       int,
                                       @pCveEmpresa      varchar(4),
									   @pIdEmpleado      int,
								       @pCveTipoNomina   varchar(2),
									   @pAnoPeriodo      varchar(6),
									   @pSdoEmpleado     numeric(16,2))

AS
BEGIN

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

END
















  DECLARE  @ano_bimestre       varchar(4)     =  ' ',
           @num_bimestre       varchar(2)     =  ' ',
           @cve_bim_ant        varchar(6)     =  ' ',
		   @ano_periodo        varchar(6)     =  ' ',
           @dias_bim_ant       int            =  0,
		   @sdo_bim_ant        numeric(16,2)  =  0,
		   @acum_percep        numeric(16,2)  =  0,
		   @dias_incap         int            =  0,
		   @dias_falta         int            =  0

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_prim_bim         varchar(2)     =  '01'
  DECLARE  @k_ult_bim          varchar(2)     =  '06',
           @k_verdadero        bit            =  1

  IF EXISTS(
  SELECT 1 FROM NO_PERIODO p  WHERE 
  p.ID_CLIENTE      = @pIdCliente      AND
  p.CVE_EMPRESA     = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  p.ANO_PERIODO     = @pAnoPeriodo)      
  BEGIN
      SELECT @ano_bimestre =  SUBSTRING(p.CVE_BIMESTRE,1,4), @num_bimestre = SUBSTRING(p.CVE_BIMESTRE,5,2)
	  FROM NO_PERIODO p  WHERE 
      p.ID_CLIENTE      = @pIdCliente      AND
      p.CVE_EMPRESA     = @pCveEmpresa     AND
      p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
      p.ANO_PERIODO     = @pAnoPeriodo      
  END
  ELSE
  BEGIN
    SET  @ano_bimestre    =  ' '
	SET  @num_bimestre    =  ' '
  END

  IF  @num_bimestre  =  @k_prim_bim
  BEGIN
    SET  @cve_bim_ant  =  CONVERT(VARCHAR(4),CONVERT(INT,@ano_bimestre) - 1)  +
	                      @k_ult_bim
  END
  ELSE
  BEGIN
    SET  @cve_bim_ant  =  @ano_bimestre  +
	replicate ('0',(02 - len(CONVERT(INT,@num_bimestre) -1))) + convert(varchar, CONVERT(INT,@num_bimestre -1))
  END

-------------------------------------------------------------------------------
-- Calculo de periodos del bimestre anterior
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TPeriodo         TABLE
          (RowID             int  identity(1,1),
		   ANO_PERIODO       varchar(6))

  INSERT  @TPeriodo(ANO_PERIODO) 
  SELECT  p.ANO_PERIODO
  FROM    NO_PERIODO p
  WHERE
  p.ID_CLIENTE       = @pIdCliente      AND
  p.CVE_EMPRESA      = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  p.ID_CVE_BIMESTRE  = @cve_bim_ant

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_periodo = ANO_PERIODO
	FROM   @TPeriodo  WHERE  RowID = @RowCount

	SET @acum_percep  =  0

    SELECT  @acum_percep = isnull(SUM(n.IMP_CONCEPTO),0)
    FROM    NO_NOMINA n
    WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
    p.ANO_PERIODO      = @ano_periodo     AND
	p.CVE_CONCEPTO     IN
	(SELECT c.CVE_CONCEPTO FROM NO_CONCEPTO c WHERE
	 c.ID_CLIENTE      = @pIdCliente      AND
     c.CVE_EMPRESA     = @pCveEmpresa     AND
	 c.B_GRABABLE      = @k_verdadero) 

    SET  @sdo_bim_ant  =  @sdo_bim_ant  + @acum_percep

    EXEC spCalNumIncap (@pIdCliente,
                        @pCveEmpresa,
		                @pIdEmpleado,
			            @pCveTipoNomina,
					    @pAnoPeriodo,
					    @dias_incap  OUT)

    SET  @pIncapBimAnt  =  @pIncapBimAnt  +  @dias_incap

    SET @RowCount     = @RowCount + 1

  END

  EXEC spCalNumFaltas (@pIdCliente,
                       @pCveEmpresa,
	                   @pIdEmpleado,
		               @pCveTipoNomina,
			           @pAnoPeriodo,
					   @pFaltasBimAnt  OUT)

  SET  @pDiasBimAnt   =  ISNULL((SELECT DIAS_BIMESTRE FROM NO_BIMESTRE  WHERE CVE_BIMESTRE = @cve_bim_ant),0)
  SET  @pSdoDiaBimAnt =  @sdo_bim_ant / @pDiasBimAnt
END

