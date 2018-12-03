USE [ADNOMINA01]
GO
/****** Calcula Factore de Integración para cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalcFactNomina] (@pIdCliente       int,
                                           @pCveEmpresa      varchar(4),
										   @pIdEmpleado      int,
										   @pCveTipoNomina   varchar(2),
										   @pAnoPeriodo      varchar(6),
                                           @pPropDiaAguin    numeric(8,4) OUT,
										   @pPropDiaPrima    numeric(8,4) OUT,
										   @pFactIntegracion numeric(8,4) OUT)
AS
BEGIN
  DECLARE  @dias_aguinaldo     numeric(16,2)  =  0,
           @dias_ano           int            =  0,
		   @pje_prima_vac      numeric(8,4)   =  0,
		   @prima_vacacional   numeric(8,4)   =  0,
		   @dias_vacaciones    int            =  0,
		   @f_fin_periodo      date

  IF EXISTS(
  SELECT 1 FROM NO_CTE_EMPRESA ce  WHERE 
  ce.ID_CLIENTE  = @pIdCliente      AND
  ce.CVE_EMPRESA = @pCveEmpresa)      
  BEGIN
    SELECT  @dias_ano  = ce.DIAS_ANO, @dias_aguinaldo = ce.DIAS_AGUINALDO, @pje_prima_vac = ce.PJE_PRIMA_VAC
	FROM NO_CTE_EMPRESA ce WHERE
    ce.ID_CLIENTE  = @pIdCliente      AND
    ce.CVE_EMPRESA = @pCveEmpresa      
  END
  ELSE
  BEGIN
    SET  @dias_ano       =  0
	SET  @dias_aguinaldo =  0
	SET  @pje_prima_vac  =  0
  END

  IF EXISTS(
  SELECT 1 FROM NO_EMPLEADO p  WHERE 
  p.ID_CLIENTE      = @pIdCliente      AND
  p.CVE_EMPRESA     = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  p.ANO_PERIODO     = @pAnoPeriodo)      
  BEGIN
      SELECT @pAnoPeriodo =  p.ANO_PERIODO FROM NO_PERIODO p  WHERE 
      p.ID_CLIENTE      = @pIdCliente      AND
      p.CVE_EMPRESA     = @pCveEmpresa     AND
      p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
      p.ANO_PERIODO     = @pAnoPeriodo      
  END
  ELSE
  BEGIN
    SET  @pAnoPeriodo    =  ' '
  END

  SET  @dias_vacaciones  =  ISNULL(dbo.fnCalDiasAguinaldo (@pIdCliente, @pCveEmpresa, @pIdEmpleado, @pAnoPeriodo),0)
                                            
  SET  @pPropDiaAguin    =   @dias_aguinaldo  /  @dias_ano
  SET  @pPropDiaPrima    =  (@dias_vacaciones * (@pje_prima_vac / 100)) / @dias_ano
  SET  @pFactIntegracion =   1 + @pPropDiaAguin + @pPropDiaPrima
END

