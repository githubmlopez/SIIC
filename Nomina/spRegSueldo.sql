USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegSueldo')
BEGIN
  DROP  PROCEDURE spRegSueldo
END
GO
--EXEC spRegSueldo 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '
CREATE PROCEDURE [dbo].[spRegSueldo]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveUsuario      varchar(8),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pSueldo          numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT)
AS
BEGIN
  DECLARE  @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_cve_sdo         varchar(4)  =  '04'

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_cve_sdo)


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
  @k_cve_sdo,
  @pSueldo,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT
END