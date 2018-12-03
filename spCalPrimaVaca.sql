USE [ADNOMINA01]
GO
/****** Calcula prima vacacional ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalPrimaVaca] (@pIdCliente       int,
                                         @pCveEmpresa      varchar(4),
									     @pIdEmpleado      int,
								         @pCveTipoNomina   varchar(2),
									     @pAnoPeriodo      varchar(6),
									     @pDiasVacaciones  int OUT,
										 @prima_vacacional numeric(16,2))
AS
BEGIN

    DECLARE  @pje_prima_vac    numeric(8,4) =  0,
	         @salario_diario   numeric(8,4) =  0

    DECLARE  @k_verdadero      bit          =  1

	SELECT  @salario_diario = c.PJE_PRIMA_VAC / 30 FROM NO_EMPLEADO e  WHERE
	        ID_CLIENTE  =  @pIdCliente  AND
			CVE_EMPRESA =  @pCveEmpresa AND
			ID_EMPLEADO =  @pIdEmpleado 

    SELECT  @pje_prima_vac = c.PJE_PRIMA_VAC FROM NO_CTE_EMPRESA c  WHERE
	        ID_CLIENTE  =  @pIdCliente  AND
			CVE_EMPRESA =  @pCveEmpresa 

	SELECT  @pDiasVacaciones  =  SUM(DIAS_VACACIONES)  FROM  NO_VAC_EMPLEADO v  WHERE 
            v.ID_CLIENTE      = @pIdCliente      AND
            v.CVE_EMPRESA     = @pCveEmpresa     AND
            v.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
            v.ANO_PERIODO     = @pAnoPeriodo
			
	SET  @pDiasVacaciones  =  ISNULL(@pDiasVacaciones,0)   

	SET  @prima_vacacional =  @salario_diario * (@pje_prima_vac/100) * @pDiasVacaciones

END

