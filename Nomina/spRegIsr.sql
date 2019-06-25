USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegIsr')
BEGIN
  DROP  PROCEDURE spRegIsr
END
GO
--EXEC spRegIsr 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,' ',' '
CREATE PROCEDURE [dbo].[spRegIsr]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pZona            int,
@pCvePuesto       varchar(15),
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pIdRegFiscal     int,
@pIdTipoCont      int,
@pIdBanco         int,
@pIdJorLab        int,
@pIdRegContrat    int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  SELECT 'spRegIsr'
  DECLARE  @cve_concepto      varchar(4)    =  ' ',
           @imp_concepto      int           =  0,
		   @tot_ing_grab      numeric(16,2) =  0,
		   @tot_sdo_per       numeric(16,2) =  0,
		   @gpo_transaccion   int           =  0,
           @cve_tipo_ajuste   varchar(1)    =  ' ',
		   @cve_grab_isr      varchar(1)    =  ' ',
		   @imp_cal_isr       numeric(16,2) =  0,
		   @imp_isr           numeric(16,2) =  0,
	       @imp_subsidio      numeric(16,2) =  0,
		   @imp_grav_per      numeric(16,2) =  0,
		   @imp_grav_acum     numeric(16,2) =  0, 
		   @imp_isr_acum      numeric(16,2) =  0,
		   @imp_sub_acum      numeric(16,2) =  0,
		   @cve_tipo_tabla    varchar(2)    =  ' ',
		   @cve_tipo_t_sub    varchar(2)    =  ' ',
		   @cve_tipo_pago     varchar(1)    =  ' ',
		   @dias_mes          int           =  0,
		   @dias_ano          int           =  0,
           @dias_periodo      int           =  0,
           @periodos_mes      int           =  0

  DECLARE  @k_verdadero       bit           =  1,
		   @k_falso           bit           =  0,
		   @k_error           varchar(1)    =  'E',
		   @k_cve_isr         varchar(4)    =  '0001',
		   @k_cve_subsidio    varchar(4)    =  '0014',
   		   @k_cve_sdo         varchar(4)    =  '0011',
		   @k_no_aplica       varchar(1)    =  'N',
		   @k_mes             varchar(1)    =  'M',
		   @k_ano             varchar(1)    =  'A',
		   @k_sueldo          varchar(1)    =  'S',
		   @k_aguinaldo       varchar(1)    =  'A',
		   @k_bono            varchar(1)    =  'B',
		   @k_meses_ano       int           =  12

  BEGIN TRY

  DELETE FROM NO_PRE_NOMINA     WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_cve_isr,@k_cve_subsidio)

  EXEC spCalBaseGrav
  @pIdProceso,
  @pIdTarea,
  @pCodigoUsuario,
  @pIdClient,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @pImp_base_grav,
  @pError OUT,
  @pMsgError OUT

  SELECT @cve_grab_isr = CVE_GRAB_ISR, @cve_tipo_tabla = CVE_TIPO_TABLA, @cve_tipo_t_sub = CVE_TIPO_TABLA_SUB,
  @cve_tipo_pago  =  CVE_TIPO_PAGO 
  FROM  NO_PERIODO  WHERE
  ID_CLIENTE      = @pIdCliente       AND
  CVE_EMPRESA     = @pCveEmpresa      AND
  CVE_TIPO_NOMINA = @pCveTipoNomina   AND
  ANO_PERIODO     = @pAnoPeriodo   
 
  EXEC spAcumPeriodo
  @pIdProceso,
  @pIdTarea,
  @pCodigoUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @pSueldoMensual,
  @cve_grab_isr,
  @cve_tipo_pago,
  @imp_cal_isr  OUT,   -- importe que se llevará a la tabla de ISR para calculo de impuesto
  @imp_grav_per OUT,   -- Importe de conceptos grabables del periodo
  @imp_gav_acum OUT,   -- Importe grabado acumulado en el periodo, anual o mensual dependiendo de CVE_GRAB_ISR
  @imp_isr_acum OUT,   -- Importe de ISR acumulado en el periodo, anual o mensual dependiendo de CVE_GRAB_ISR
  @imp_sub_acum OUT,   -- Importe de Subsidio acumulado en el periodo, anual o mensual dependiendo de CVE_GRAB_ISR
  @pError       OUT,
  @pMsgError    OUT

  SELECT  @dias_ano = DIAS_ANO  FROM NO_EMPRESA
  WHERE   ID_CLIENTE  =  @pIdCliente  AND
          CVE_EMPRESA =  @pCveEmpresa

  SET @dias_mes      =  @dias_ano / @k_meses_ano
  SET @dias_periodo  =  @dias_mes / 2
  SET @periodos_mes  =  @dias_mes / @dias_periodo

  IF  @cve_tipo_pago  =  @k_sueldo  AND  @cve_grab_isr NOT IN (@k_ano, @k_mes)
  BEGIN
    IF  @cve_grab_isr NOT IN (@k_ano, @k_mes)
	BEGIN
	  SET @imp_cal_isr   =  @imp_grav_per * @periodos_mes
      EXEC spCalculaISR  
      @pIdProceso,
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pCveAplicacion,
      @pCveTipoNomina,
      @pAnoPeriodo,
      @pIdEmpleado,
      @imp_cal_isr,
      @cve_tipo_tabla,
      @imp_isr OUT,
      @imp_subsidio OUT,
      @pError OUT,
      @pMsgError OUT

      SET  @imp_isr      = @imp_isr / @periodos_mes
	  SET  @imp_subsidio = @imp_isr / @periodos_mes

    END
    ELSE
	BEGIN
      SET @imp_cal_isr   =  @imp_grav_per * @imp_grav_acum
	  EXEC spCalculaISR  
      @pIdProceso,
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pCveAplicacion,
      @pCveTipoNomina,
      @pAnoPeriodo,
      @pIdEmpleado,
      @imp_cal_isr,
      @cve_tipo_tabla,
      @imp_isr OUT,
      @imp_subsidio OUT,
      @pError OUT,
      @pMsgError OUT

	  SET  @imp_isr      = @imp_isr       -  @imp_isr_acum
	  SET  @imp_subsidio = @imp_subsidio  -  @imp_sub_acum

	END
  END
  ELSE
  BEGIN
    IF  @cve_tipo_pago  IN  (@k_bono, @k_aguinaldo)  
    BEGIN
      EXEC spCalculaISR  
      @pIdProceso,
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pCveAplicacion,
      @pCveTipoNomina,
      @pAnoPeriodo,
      @pIdEmpleado,
      @imp_cal_isr,
      @cve_tipo_tabla,
      @imp_isr OUT,
      @imp_subsidio OUT,
      @pError OUT,
      @pMsgError OUT
    END
  END

  IF  @imp_isr <> 0
  BEGIN
    SET  @cve_concepto  =  @k_cve_isr

    EXEC spInsPreNomina  
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @cve_concepto,
    @imp_isr,
    0,
    0,
    0,
	0,
    ' ',
    ' ',
    @pError OUT,
    @pMsgError OUT
  END

  IF  @imp_subsidio <> 0
  BEGIN
    SET  @cve_concepto  =  @k_cve_subsidio

    EXEC spInsPreNomina  
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @cve_concepto,
    @imp_subsidio,
    0,
    0,
    0,
	0,
    ' ',
    ' ',
    @pError OUT,
    @pMsgError OUT
  END

  UPDATE  NO_INF_EMP_PER  SET IMP_BASE_GRAV  =  @imp_base_grav, IMP_ISR = @imp_isr, IMP_SUBSIDIO = @imp_subsidio   
  WHERE   ANO_PERIODO     =  @pAnoPeriodo    AND
          ID_CLIENTE      =  @pIdCliente     AND
		  CVE_EMPRESA     =  @pCveEmpresa    AND
		  CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		  ID_EMPLEADO     =  @pIdEmpleado


  END TRY

  BEGIN CATCH
    SET  @pError    =  'E- Cal. ISR ' + CONVERT(VARCHAR(10), @pIdEmpleado) + '(P)' + ERROR_PROCEDURE()  
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento 
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_error,
    @pError,
    @pMsgError
  END CATCH

END