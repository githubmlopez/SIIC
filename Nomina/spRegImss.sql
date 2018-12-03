USE [ADNOMINA01]
GO
/****** Calcula Incidencia por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegImss] (@pIdProceso       numeric(9),
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
  DECLARE  @cve_concepto      varchar(4)  =  ' ',
           @imp_concepto      int         =  0,
		   @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_imss            varchar(4)  =  'IMSS',
		   @k_infonavit       varchar(4)  =  'INFO',
		   @k_sar             varchar(4)  =  'SAR'

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_imss

  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_imss,
                       @imp_concepto,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '

  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_infonavit

  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_infonavit,
                       @imp_concepto,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '
  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_imss

  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_sar,
                       @imp_concepto,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '


END