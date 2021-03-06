USE [ADNOMINA01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnCalDiasVacaciones')
BEGIN
  DROP  FUNCTION fnCalDiasVacaciones
END
GO
CREATE FUNCTION [dbo].[fnCalDiasVacaciones] 
(
@pIdCliente    int,
@pCveEmpresa   varchar(4),
@pIdEmpleado   int,
@pFFinPeriodo  date
)
RETURNS int						  
AS
BEGIN
  
  DECLARE @f_ingreso  date,
          @ano_i      varchar(4),
		  @ano_p      varchar(4),
          @mes_dia_i  varchar(4),
		  @mes_dia_p  varchar(4),
		  @anos_antig int,
		  @dias_vaca  int
		  
  
  SET @f_ingreso =  (SELECT F_INGRESO FROM NO_EMPLEADO  WHERE
                     ID_CLIENTE  = @pIdCliente      AND
		     		 CVE_EMPRESA = @pCveEmpresa      AND 
		 			 ID_EMPLEADO = @pIdEmpleado)
					 
  SET  @ano_i  = convert(varchar, YEAR(@f_ingreso))

  SET  @ano_p  = convert(varchar, YEAR(@pFFinPeriodo))

  SET  @mes_dia_i  =
  (replicate ('0',(02 - len(MONTH(@f_ingreso)))) + convert(varchar, MONTH(@f_ingreso))) +
  (replicate ('0',(02 - len(DAY(@f_ingreso)))) + convert(varchar, DAY(@f_ingreso))) 

  SET  @mes_dia_p  =
  (replicate ('0',(02 - len(MONTH(@pFFinPeriodo)))) + convert(varchar, MONTH(@pFFinPeriodo))) +
  (replicate ('0',(02 - len(DAY(@pFFinPeriodo)))) + convert(varchar, DAY(@pFFinPeriodo)))

  SET  @anos_antig  =  YEAR(@pFFinPeriodo)  -  YEAR(@f_ingreso)

  IF   @mes_dia_i  > @mes_dia_p
  BEGIN
    SET  @anos_antig  =  @anos_antig  -  1
  END

  SET @dias_vaca  = (SELECT DIAS_VACACIONES FROM NO_VACA_DERECHO  WHERE 
                            ID_CLIENTE  =  @pIdCliente      AND
		     		        CVE_EMPRESA =  @pCveEmpresa     AND 
		 			        NUM_ANOS    =  @anos_antig)

  SET @dias_vaca  =  ISNULL(@dias_vaca,0)

  RETURN(@dias_vaca)
END

