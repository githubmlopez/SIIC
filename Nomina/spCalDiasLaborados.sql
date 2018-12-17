USE [ADNOMINA01]
GO
/****** Calcula dias laborados del periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalDiasLaborados')
BEGIN
  DROP  PROCEDURE spCalDiasLaborados
END
GO
CREATE PROCEDURE [dbo].[spCalDiasLaborados] 
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
@pDiasPeriodo     int OUT,
@pDiasIncap       int OUT,
@pDiasFaltas      int OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
  
  DECLARE  @k_verdadero   bit         =  1,
	       @k_falso       bit         =  0

  IF  EXISTS(SELECT 1 FROM NO_PERIODO  p WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina)
  BEGIN
    SELECT @pDiasPeriodo = NUM_DIAS_PERIODO FROM NO_PERIODO  p WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina
  END
    
  EXEC spCalNumIncap  @pIdProceso,
                      @pIdTarea,
					  @pCodigoUsuario,
                      @pIdCliente,
                      @pCveEmpresa,
	                  @pCveAplicacion,
					  @pCveTipoNomina,
					  @pAnoPeriodo,
		              @pIdEmpleado,
					  @pDiasIncap  OUT,
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
					  @pDiasFaltas OUT,
					  @pError OUT,
                      @pMsgError OUT

END

