USE [ADNOMINA01]
GO
/****** Calcula prima vacacional ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalPrimaVaca')
BEGIN
  DROP  PROCEDURE spCalPrimaVaca
END
GO

CREATE PROCEDURE [dbo].[spCalPrimaVaca] (@pIdCliente       int,
                                         @pCveEmpresa      varchar(4),
									     @pIdEmpleado      int,
								         @pCveTipoNomina   varchar(2),
										 @pCveTipo_Percep  varchar(2),
									     @pAnoPeriodo      varchar(6),
                                         @pSueldo          numeric(16,2),
										 @prima_vacacional numeric(16,2) OUT)
AS
BEGIN

    DECLARE  @pje_prima_vac    numeric(8,4)  =  0,
	         @salario          numeric(16,2) =  0,
			 @dias_int         numeric(4,2)  =  0,
			 @dias_int_m       numeric(4,2)  =  0,
			 @num_dias_mes     numeric(4,2)  =  0,
			 @dias_vacaciones  int

    DECLARE  @k_verdadero      bit          =  1,
	         @k_fijo_min       varchar(2)   =  'FM'

    SELECT  @dias_vacaciones  = DIAS_PRIMA_VAC,
	        @num_dias_mes     = NUM_DIAS_INT
	FROM    NO_INF_EMP_PER      WHERE
			ANO_PERIODO       =  @pAnoPeriodo    AND
	        ID_CLIENTE        =  @pIdCliente     AND
			CVE_EMPRESA       =  @pCveEmpresa    AND
 			ID_EMPLEADO       =  @pIdEmpleado    AND
			CVE_TIPO_NOMINA   =  @pCveTipoNomina 
			
	SET  @dias_vacaciones  =  ISNULL(@dias_vacaciones,0)   

	SET  @prima_vacacional =  (@pSueldo / @num_dias_mes) * (@pje_prima_vac/100) * @dias_vacaciones

END

