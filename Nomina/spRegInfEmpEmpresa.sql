USE [ADNOMINA01]
GO
/****** Calcula Incidencia por Periodo ******/
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
@pCodigoUsuario   varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pZona            int,
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT

)
AS
BEGIN
  DECLARE  @dias_incap  int = 0,
           @dias_falta  int = 0,
		   @dias_vaca   int = 0

  DECLARE  @k_error     varchar(1) = 'E'


  EXEC spCalNumIncap  @pIdProceso,
                      @pIdTarea,
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
                      @pIdCliente,
                      @pCveEmpresa,
	                  @pCveAplicacion,
					  @pCveTipoNomina,
					  @pAnoPeriodo,
		              @pIdEmpleado,
					  @dias_vaca  OUT,
					  @pError OUT,
                      @pMsgError OUT

  BEGIN TRY

  UPDATE  NO_INF_EMP_PER  SET NUM_FALTAS = @dias_falta, NUM_INCAPACIDAD = @dias_incap,
                              DIAS_PRIMA_VAC = @dias_vaca WHERE
  ANO_PERIODO     =  @pAnoPeriodo   AND
  ID_CLIENTE      =  @pIdCliente    AND
  CVE_EMPRESA     = @pCveEmpresa    AND
  ID_EMPLEADO     = @pIdEmpleado    AND
  CVE_TIPO_NOMINA = @pCveTipoNomina 

  END TRY

  BEGIN CATCH
 
  SET  @pError    =  'Error Act. Inf. Emp. Periodo ' + CONVERT(VARCHAR(10), @pIdEmpleado) +
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
