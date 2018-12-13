USE [ADNOMINA01]
GO
/****** Calcula Incidencia por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegImss')
BEGIN
  DROP  PROCEDURE spRegImss
END
GO
--EXEC spRegImss 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '
CREATE PROCEDURE [dbo].[spRegImss]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveUsuario      varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pSueldoMensual   numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @cve_concepto      varchar(4)  =  ' ',
           @imp_concepto      int         =  0,
		   @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_imss            varchar(4)  =  'IMSS',
		   @k_infonavit       varchar(4)  =  'INFO',
		   @k_sar             varchar(4)  =  'SAR',
		   @k_c_imss          varchar(4)  =  '06',
		   @k_c_infonavit     varchar(4)  =  '07',
		   @k_c_sar           varchar(4)  =  '08'


  DECLARE  @NunRegistros      int, 
           @RowCount          int

  EXEC spCalculaSBC 
  @pIdProceso,
  @pIdTarea,
  @pCveUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @pSueldoMensual,
  @pError OUT,
  @pMsgError OUT

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_c_imss,@k_c_infonavit,@k_c_sar)

  SET  @cve_concepto  =  @k_c_imss

  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_imss

  EXEC spInsPreNomina  
  @pIdProceso,
  @pIdTarea,
  @pCveUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @cve_concepto,
  @imp_concepto,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

  SET  @cve_concepto  =  @k_c_infonavit

  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_infonavit

  SET @imp_concepto = ISNULL(@imp_concepto,0)

  EXEC spInsPreNomina  
  @pIdProceso,
  @pIdTarea,
  @pCveUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @cve_concepto,
  @imp_concepto,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

  SET  @cve_concepto  =  @k_c_sar

  SELECT  @imp_concepto = SUM(IMP_CUOT_OBRERO)  FROM  NO_DET_CONC_OB_PAT WHERE
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente AND
  CVE_EMPRESA  =  @pCveEmpresa AND
  ID_EMPLEADO  =  @pIdEmpleado AND
  CVE_ENTIDAD  =  @k_sar

  SET @imp_concepto = ISNULL(@imp_concepto,0)

  EXEC spInsPreNomina  
  @pIdProceso,
  @pIdTarea,
  @pCveUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCveTipoNomina,
  @pAnoPeriodo,
  @pIdEmpleado,
  @cve_concepto,
  @imp_concepto,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

END