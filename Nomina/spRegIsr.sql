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
		   @imp_isr           numeric(16,2) =  0,
		   @imp_subsidio      numeric(16,2) =  0,
		   @imp_isr_sub       numeric(16,2) =  0,
		   @gpo_transaccion   int           =  0,
		   @ano_mes           varchar(6)    =  ' ',
           @b_fin_mes         bit           =  0,
		   @imp_grab_mensual  numeric(16,2) =  0,
		   @imp_isr_men       numeric(16,2) =  0,
		   @imp_sub_men       numeric(16,2) =  0

  DECLARE  @k_verdadero       bit           =  1,
		   @k_falso           bit           =  0,
		   @k_error           varchar(1)    =  'E',
		   @k_cve_isr         varchar(4)    =  '0001',
		   @k_cve_subsidio    varchar(4)    =  '0014'

  BEGIN TRY

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_cve_isr,@k_cve_subsidio)

  SELECT @ano_mes= ANO_MES, @b_fin_mes = B_FIN_MES FROM NO_PERIODO WHERE
         ID_CLIENTE      =  @pIdCliente      AND
		 CVE_EMPRESA     =  @pCveEmpresa     AND
		 CVE_TIPO_NOMINA =  @pCveTipoNomina  AND
		 ANO_PERIODO     =  @pAnoPeriodo

  SELECT   @tot_ing_grab = SUM(n.IMP_CONCEPTO)  
  FROM     NO_PRE_NOMINA n, NO_CONCEPTO c  WHERE
  n.ANO_PERIODO     = @pAnoPeriodo     AND
  n.ID_CLIENTE      = @pIdCliente      AND
  n.CVE_EMPRESA     = @pCveEmpresa     AND
  n.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  n.ID_EMPLEADO     = @pIdEmpleado     AND
  n.ID_CLIENTE      = c.ID_CLIENTE     AND
  n.CVE_EMPRESA     = c.CVE_EMPRESA    AND
  n.CVE_CONCEPTO    = c.CVE_CONCEPTO   AND
  c.B_GRABABLE      = @k_verdadero

  SELECT   @imp_grab_mensual = SUM(i.IMP_PER_GRAB), @imp_isr_men = SUM(IMP_PER_ISR),
           @imp_sub_men  =  SUM(IMP_PER_SUB)  
  FROM     NO_INF_EMP_PER i, NO_ANO_MES a, NO_PERIODO p  WHERE
  i.ANO_PERIODO     = @pAnoPeriodo      AND
  i.ID_CLIENTE      = @pIdCliente       AND
  i.CVE_EMPRESA     = @pCveEmpresa      AND
  i.CVE_TIPO_NOMINA = @pCveTipoNomina   AND
  i.ID_EMPLEADO     = @pIdEmpleado      AND
  i.ID_CLIENTE      = p.ID_CLIENTE      AND
  i.CVE_EMPRESA     = p.CVE_EMPRESA     AND
  i.CVE_TIPO_NOMINA = p.CVE_TIPO_NOMINA AND
  i.ANO_PERIODO     = p.ANO_PERIODO     AND
  p.ID_CLIENTE      = a.ID_CLIENTE      AND
  p.CVE_EMPRESA     = a.CVE_EMPRESA     AND
  p.CVE_TIPO_NOMINA = a.CVE_TIPO_NOMINA AND
  p.ANO_MES         = a.ANO_MES

  SET @imp_grab_mensual = @imp_grab_mensual + @tot_ing_grab

  UPDATE NO_INF_EMP_PER  SET IMP_PER_GRAB = @tot_ing_grab WHERE
  ID_CLIENTE       =  @pIdCliente  AND
  CVE_EMPRESA      =  @pCveEmpresa AND
  CVE_TIPO_NOMINA  =  @pCveTipoNomina  AND
  ANO_PERIODO      =  @pAnoPeriodo  AND
  ID_EMPLEADO      =  @pIdEmpleado

  SET  @tot_ing_grab  =  ISNULL(@tot_ing_grab,0) 
  SELECT 'GRAB ' + CONVERT(VARCHAR(10),@tot_ing_grab)
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
  @tot_ing_grab,
  @imp_grab_mensual,
  @imp_isr_men,
  @imp_sub_men,
  @imp_isr OUT,
  @imp_subsidio OUT,
  @b_fin_mes,
  @pError OUT,
  @pMsgError OUT

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