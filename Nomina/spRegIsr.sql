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
--  SELECT 'spRegIsr'
  DECLARE  @cve_concepto      varchar(4)    =  ' ',
           @imp_concepto      int           =  0,
		   @tot_ing_grab      numeric(16,2) =  0,
		   @imp_isr           numeric(16,2) =  0,
		   @imp_subsidio      numeric(16,2) =  0,
		   @imp_isr_sub       numeric(16,2) =  0,
		   @gpo_transaccion   int           =  0

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

  SELECT   @tot_ing_grab = SUM(n.IMP_CONCEPTO)  
  FROM     NO_PRE_NOMINA n, NO_CONCEPTO c  WHERE
  n.ANO_PERIODO     = @pAnoPeriodo     AND
  n.ID_CLIENTE      = @pIdCliente      AND
  n.CVE_EMPRESA     = @pCveEmpresa     AND
  n.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  n.ID_EMPLEADO     = @pIdEmpleado     AND
  n.CVE_CONCEPTO    = c.CVE_CONCEPTO   AND
  c.B_GRABABLE      = @k_verdadero

  SET  @tot_ing_grab  =  ISNULL(@tot_ing_grab,0) 

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
  @imp_isr OUT,
  @imp_subsidio OUT,
  @pError OUT,
  @pMsgError OUT

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
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

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
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

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