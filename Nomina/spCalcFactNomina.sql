USE [ADNOMINA01]
GO
/****** Calcula Factor de Integración para cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalcFactNomina')
BEGIN
  DROP  PROCEDURE spCalcFactNomina
END
GO
-- EXEC spCalcFactNomina 1,1,1,'CU','NOMINA','S','201801',1,0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spCalcFactNomina] 
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
@pPropDiaAguin    numeric(16,6) OUT,
@pPropDiaPrima    numeric(16,6) OUT,
@pFactIntegracion numeric(16,6) OUT,
@pDiasDerVaca     int OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
--  SELECT 'ANO PERIODO' + @pAnoPeriodo 
  
  DECLARE  @dias_aguinaldo     numeric(6,2)   =  0.0,
           @dias_ano           numeric(6,2)   =  0.0,
		   @pje_prima_vac      numeric(8,4)   =  0.0,
		   @prima_vacacional   numeric(8,4)   =  0.0,
		   @ano_bim_ant        varchar(6)     = ' ',
		   @dias_vacaciones    int            =  0,
		   @f_fin_periodo      date,
		   @b_correcto         bit            =  1

  DECLARE  @k_verdadero        bit            =  1,
           @k_falso            bit            =  0,
		   @k_warning          varchar(1)     =  'W'

  IF EXISTS(
  SELECT 1 FROM NO_EMPRESA ce  WHERE 
  ce.ID_CLIENTE  = @pIdCliente      AND
  ce.CVE_EMPRESA = @pCveEmpresa)      
  BEGIN
    SELECT  @dias_ano  = ce.DIAS_ANO, @dias_aguinaldo = ce.DIAS_AGUINALDO, @pje_prima_vac = ce.PJE_PRIMA_VAC
	FROM NO_EMPRESA ce WHERE
    ce.ID_CLIENTE  = @pIdCliente      AND
    ce.CVE_EMPRESA = @pCveEmpresa      
  END
  ELSE
  BEGIN
    SET  @b_correcto     =  0
	SET  @dias_ano       =  0
	SET  @dias_aguinaldo =  0
	SET  @pje_prima_vac  =  0
  END

  SET @ano_bim_ant = dbo.fnCalBimAnterior 
  (
  @pIdCliente,
  @pCveEmpresa,
  @pCveTipoNomina,
  @pAnoPeriodo
  )

  IF 
 (SELECT 1 FROM NO_BIMESTRE b WHERE 
  b.CVE_BIMESTRE    = @ano_bim_ant) = 1      
  BEGIN
     SELECT @f_fin_periodo = b.F_FIN FROM NO_BIMESTRE b WHERE 
	 b.CVE_BIMESTRE        = @ano_bim_ant  
     SELECT '(B)' + LEFT(CONVERT(VARCHAR, @f_fin_periodo, 120), 10)
  END
  ELSE
  BEGIN
    SET  @b_correcto     =  @k_falso
	SET  @pAnoPeriodo    =  ' '
  END

  IF  @b_correcto  =  @k_verdadero
  BEGIN
 --   SELECT  CONVERT(VARCHAR(16), @dias_aguinaldo)
	--SELECT  CONVERT(VARCHAR(16), @dias_ano)

    SET  @dias_vacaciones  =  ISNULL(dbo.fnCalDiasVacaciones(@pIdCliente, @pCveEmpresa, @pIdEmpleado, @f_fin_periodo),0)
	SET  @pDiasDerVaca     =  @dias_vacaciones
    SET  @pPropDiaAguin    =  @dias_aguinaldo  /  @dias_ano
    SET  @pPropDiaPrima    =  (@dias_vacaciones * (@pje_prima_vac / 100)) / @dias_ano
	--SELECT  CONVERT(VARCHAR(16), @pPropDiaPrima)
    SET  @pFactIntegracion =   1 + @pPropDiaAguin + @pPropDiaPrima
	--SELECT CONVERT(VARCHAR(10), @pIdEmpleado)
	--SELECT  CONVERT(VARCHAR(16), @dias_vacaciones)
	--SELECT  CONVERT(VARCHAR(30), @pPropDiaAguin)
	--SELECT  CONVERT(VARCHAR(30), @pPropDiaPrima)
  END
  ELSE
  BEGIN
    SET  @pError    =  'Empresa inexistente ' + '(P)' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento 
	  @pIdProceso,
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pCveAplicacion,
      @k_warning,
      @pError,
      @pMsgError
  END
END

