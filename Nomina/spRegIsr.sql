USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegIsr] (@pIdProceso       numeric(9),
								   @pIdTarea         numeric(9),
								   @pCveUsuario      varchar(8),
								   @pIdCliente       int,
                                   @pCveEmpresa      varchar(4),
								   @pCveTipoNomina   varchar(2),
								   @pAnoPeriodo      varchar(6),
								   @pIdEmpleado      int,
								   @pError           varchar(80) OUT,
								   @pMsgError        varchar(400) OUT)
AS
BEGIN
  DECLARE  @cve_concepto      varchar(4)    =  ' ',
           @imp_concepto      int           =  0,
		   @tot_ing_grab      numeric(16,2) =  0,
		   @imp_isr           numeric(16,2) =  0,
		   @imp_subsidio      numeric(16,2) =  0,
		   @imp_isr_sub       numeric(16,2) =  0,
		   @gpo_transaccion   int           =  0

  DECLARE  @k_verdadero       bit           =  1,
		   @k_falso           bit           =  0,
		   @k_cve_isr         varchar(4)    =  'ISR ',
		   @k_cve_subsidio    varchar(4)    =  'SUB'

  SELECT   @tot_ing_grab = SUM(n.IMP_CONCEPTO)  
  FROM     NO_PRE_NOMINA n, NO_CONCEPTO c  WHERE
  n.ANO_PROCESO     = @pAnoPeriodo     AND
  n.ID_CLIENTE      = @pIdCliente      AND
  n.CVE_EMPRESA     = @pCveEmpresa     AND
  n.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  n.ID_EMPLEADO     = @pIdEmpleado     AND
  n.CVE_CONCEPTO    = @pCveConcepto    AND
  n.CVE_CONCEPTO    = c.CVE_CONCEPTO   AND
  c.B_GRABABLE      = @k_verdadero

  SET  @tot_ing_grab  =  ISNULL(@tot_ing_grab,0) 

  EXEC spCalculaISR (@tot_ing_grab, @imp_isr OUT, @imp_subsidio OUT)

  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_cve_isr,
                       @imp_isr,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '
  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_cve_subsidio,
                       @imp_subsidio,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '
END