USE [ADNOMINA01]
GO
/****** Registra informacion del empleado por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegInfEmpEmpresa')
BEGIN
  DROP  PROCEDURE spRegInfEmpEmpresa
END
GO
--EXEC spRegInfEmpEmpresa 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,' ',' '
CREATE PROCEDURE [dbo].[spRegInfEmpEmpresa]
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
--  SELECT 'spRegInfEmpEmpresa'
  DECLARE  @dias_incap   int = 0,
           @dias_falta   int = 0,
		   @dias_vaca    int = 0,
		   @dias_int     numeric(4,2)  =  0,
		   @dias_int_m   numeric(4,2)  =  0,
		   @num_dias_mes numeric(4,2)  =  0

  DECLARE  @k_error     varchar(1)      = 'E',
  		   @k_fijo_min       varchar(2) =  'FM'


  BEGIN TRY

  DELETE FROM NO_INF_EMP_PER WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado

  EXEC spCalNumIncap  @pIdProceso,
                      @pIdTarea,
					  @pCodigoUsuario,
	                  @pIdCliente,
                      @pCveEmpresa,
	                  @pCveAplicacion,
					  @pCveTipoNomina,
					  @pAnoPeriodo,
		              @pIdEmpleado,
					  @dias_incap  OUT,
					  @pError OUT,
                      @pMsgError OUT

  EXEC spCalNumFaltas @pIdProceso,
                      @pIdTarea,
					  @pCodigoUsuario,
                      @pIdCliente,
                      @pCveEmpresa,
	                  @pCveAplicacion,
					  @pCveTipoNomina,
					  @pAnoPeriodo,
		              @pIdEmpleado,
					  @dias_falta  OUT,
					  @pError OUT,
                      @pMsgError OUT

  EXEC spCalDiasVaca  @pIdProceso,
                      @pIdTarea,
					  @pCodigoUsuario,
                      @pIdCliente,
                      @pCveEmpresa,
	                  @pCveAplicacion,
					  @pCveTipoNomina,
					  @pAnoPeriodo,
		              @pIdEmpleado,
					  @dias_vaca  OUT,
					  @pError OUT,
                      @pMsgError OUT


  SELECT  @dias_int      = NUM_DIAS_INT,
	      @dias_int_m    = NUM_DIAS_INT_M
  FROM    NO_EMPRESA c   WHERE
	      ID_CLIENTE  =  @pIdCliente  AND
	      CVE_EMPRESA =  @pCveEmpresa 

  SET @num_dias_mes    =  @dias_int
  IF  @pCveTipoPercep  =  @k_fijo_min
  BEGIN
    SET  @num_dias_mes  =  @dias_int_m
  END

  INSERT NO_INF_EMP_PER
 (
  ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  ZONA,
  CVE_PUESTO,
  CVE_TIPO_EMPLEADO,
  CVE_TIPO_PERCEP,
  F_INGRESO,
  SUELDO_MENSUAL,
  ID_REG_FISCAL, 
  ID_TIPO_CONT,
  ID_BANCO,
  ID_JOR_LAB,
  ID_REG_CONTRAT,
  NUM_DIAS_INT)
  VALUES
 (
  @pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pIdEmpleado,
  @pCveTipoNomina, 
  @pZona,
  @pCvePuesto,
  @pCveTipoEmpleado,
  @pCveTipoPercep,
  @pFIngreso,
  @pSueldoMensual,
  @pIdRegFiscal,
  @pIdTipoCont,
  @pIdBanco,
  @pIdJorLab,
  @pIdRegContrat,
  @num_dias_mes)

  END TRY

  BEGIN CATCH
 
  SET  @pError    =  'E- Reg. Inf. Empl. ' + CONVERT(VARCHAR(10), @pIdEmpleado) +
  ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
  SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
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
