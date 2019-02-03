USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegPrimaVac')
BEGIN
  DROP  PROCEDURE spRegPrimaVac
END
GO
--EXEC spRegPrimaVac 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '

CREATE PROCEDURE [dbo].[spRegPrimaVac]   
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
--  SELECT 'spRegPrimaVac'
  DECLARE  @imp_concepto  numeric(16,2)

  DECLARE  @k_prima_vac   varchar(4)    =  '0015',
           @k_error       varchar(1)    =  'E'

  BEGIN TRY

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_prima_vac)

  EXEC spCalPrimaVaca
  @pIdCliente,
  @pCveEmpresa,
  @pIdEmpleado,
  @pCveTipoNomina,
  @pCveTipoPercep,
  @pAnoPeriodo,
  @pSueldoMensual,
  @imp_concepto OUT

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
  @k_prima_vac,
  @imp_concepto,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

  END TRY

  BEGIN CATCH
    SET  @pError    =  'E- Prima Vac ' + CONVERT(VARCHAR(10), @pIdEmpleado) + '(P)' + ERROR_PROCEDURE() 
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

