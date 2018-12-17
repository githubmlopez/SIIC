USE [ADNOMINA01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalDiasVaca')
BEGIN
  DROP  PROCEDURE spCalDiasVaca
END
GO
--EXEC spCalDiasVaca 1,1,1,'CU','NOMINA','S','201801',1,0,' ',' '
CREATE PROCEDURE [dbo].[spCalDiasVaca]
(
@pIdProceso       int,
@pIdTarea         int,
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pDiasVacaciones  int OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @k_verdadero       bit         =  1,
           @k_falso           bit         =  0,
		   @k_error           varchar(1)  =  'E'

  SELECT @pDiasVacaciones = SUM(DIAS_VACACIONES) FROM NO_VACACIONES_ANO v, NO_VAC_EMPLEADO ve WHERE
  v.ID_CLIENTE     =  @pIdCliente    AND
  v.CVE_EMPRESA    =  @pCveEmpresa   AND
  v.ID_EMPLEADO    =  @pIdEmpleado   AND
  v.ANO_PERIODO    =  @pAnoPeriodo   AND
  v.ID_CLIENTE     =  ve.ID_CLIENTE  AND
  v.CVE_EMPRESA    =  ve.CVE_EMPRESA AND
  v.ID_EMPLEADO    =  ve.ID_EMPLEADO AND
  v.ANO_PERIODO    =  ve.ANO_PERIODO AND
  v.FOL_VACACIONES =  ve.FOL_VACACIONES
  
END

