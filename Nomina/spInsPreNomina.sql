USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spInsPreNomina')
BEGIN
  DROP  PROCEDURE spInsPreNomina
END
GO
--EXEC spInsPreNomina 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,'01',0,0,0,0,' ',' ',' ',' '
CREATE PROCEDURE [dbo].[spInsPreNomina] 
(
@pIdProceso      int,
@pIdTarea        int,
@pCodigoUsuario  varchar(20),
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pCveAplicacion  varchar(10),
@pCveTipoNomina  varchar(2),
@pAnoPeriodo     varchar(6),
@pIdEmpleado     int,
@pCveConcepto    varchar(4) ,
@pImpConcepto    numeric(16,2),
@pImpAjuste      numeric(16,2),
@pDiasAjuste     int ,
@pGpoTransaccion int ,
@pTxtNota        varchar(200),
@pReferencia     varchar(100),
@pError          varchar(80) OUT,
@pMsgError       varchar(400) OUT
)  
AS
BEGIN
  DECLARE  @k_error varchar(1)  =  'E'

  BEGIN TRY 

  INSERT INTO NO_PRE_NOMINA 
 (ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  CVE_TIPO_NOMINA,
  ID_EMPLEADO,
  CVE_CONCEPTO,
  IMP_CONCEPTO,
  IMP_AJUSTE,
  DIAS_AJUSTE,
  GPO_TRANSACCION,
  TX_NOTA,
  REFERENCIA)  VALUES
 (@pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pCveTipoNomina,
  @pIdEmpleado,
  @pCveConcepto,
  @pImpConcepto,
  @pImpAjuste,
  @pDiasAjuste,
  @pGpoTransaccion,
  @pTxtNota,
  @pReferencia)

  UPDATE  FC_GEN_TAREA  SET  NUM_REGISTROS =  NUM_REGISTROS + 1  WHERE 
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso   AND
		  ID_TAREA     =  @pIdTarea  

  END TRY  

  BEGIN CATCH
    SET  @pError    =  'Error Insert Pre. Nomina ' + CONVERT(VARCHAR(10),@pIdEmpleado) + ' ' + 
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