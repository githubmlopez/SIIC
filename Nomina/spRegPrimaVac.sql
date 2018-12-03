USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegPrimaVac]   (@pIdProceso     numeric(9),        
                                          @pIdTarea       numeric(9),
										  @pCveUsuario    varchar(8),
                                          @pIdCliente     int,
									 	  @pCveEmpresa    varchar(4),
										  @pIdEmpleado    int,
										  @pCveTipoNomina varchar(2),
										  @pAnoPeriodo    varchar(6))
AS
BEGIN
  DECLARE  @imp_concepto  numeric(16,2)

  DECLARE  @K_prima_vac   varchar(4)  =  'PVAC'

  IF  ISNULL(SELECT DIAS_PRIMA_VAC FROM NO_CTE_EMPRESA
             WHERE  ID_CLIENTE  =  @pIdCliente  AND
			        CVE_EMPRESA =  @pCveEmpresa AND
 			        ID_EMPLEADO =  @pIdEmpleado AND
					CVE_TIPO_NOMINA = @pCveTipoNomina AND
					ANO_PERIODO =  @pAnoPeriodo),0) <> 0
  BEGIN
    SET  @imp_concepto  =  ISNULL(SELECT PJE_PRIMA_VAC  FROM NO_CTE_EMPRESA
                        WHERE  ID_CLIENTE  =  @pIdCliente  AND
	                           CVE_EMPRESA =  @pCveEmpresa),0)  *
                       (SELECT DIAS_PRIMA_VAC FROM NO_CTE_EMPRESA
                        WHERE  ID_CLIENTE      =  @pIdCliente  AND
						       CVE_EMPRESA     =  @pCveEmpresa AND
 						       ID_EMPLEADO     =  @pIdEmpleado AND
							   CVE_TIPO_NOMINA =  @pCveTipoNomina AND
							   ANO_PERIODO     =  @pAnoPeriodo)
  END

  EXEC spInsPreNomina  @pAnoPeriodo,
                        @pIdCliente,
                        @pCveEmpresa,
                        @pCveTipoNomina,
                        @pIdEmpleado,
                        @k_prima_vac,
                        @imp_concepto,
	                    0,
                        0,
                        @gpo_transaccion,
                        ' '  

END

