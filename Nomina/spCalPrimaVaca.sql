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
										 @pPrima_vac       numeric(16,2) OUT,
										 @pPrima_vac_grab  numeric(16,2) OUT,
										 @pDiasVaca        int OUT)
AS
BEGIN

    DECLARE  @pje_prima_vac    numeric(8,4)  =  0,
	         @salario          numeric(16,2) =  0,
			 @imp_tope_prima   numeric(16,2) =  0,
			 @dias_int         numeric(4,2)  =  0,
			 @dias_int_m       numeric(4,2)  =  0,
			 @num_dias_mes     numeric(4,2)  =  0,
			 @imp_prima_ano    numeric(16,2) =  0,
			 @ano_prima        varchar(4)    =  ' '

    DECLARE  @k_verdadero      bit          =  1,
	         @k_fijo_min       varchar(2)   =  'FM',
			 @k_prima_vac      varchar(4)   =  '0015',
			 @k_prima_vac_dev  varchar(4)   =  '0028'

    SELECT @ano_prima  =  SUBSTRING(@pAnoPeriodo,1,4)

    SELECT  @num_dias_mes     = NUM_DIAS_MES,
	        @pje_prima_vac    = PJE_PRIMA_VAC
	FROM    NO_EMPRESA          WHERE
	        ID_CLIENTE        =  @pIdCliente     AND
			CVE_EMPRESA       =  @pCveEmpresa    
   
    SELECT  @pDiasVaca        = DIAS_PRIMA_VAC,
	        @imp_tope_prima   = IMP_TOPE_PRIMA
	FROM    NO_INF_EMP_PER      WHERE
			ANO_PERIODO       =  @pAnoPeriodo    AND
	        ID_CLIENTE        =  @pIdCliente     AND
			CVE_EMPRESA       =  @pCveEmpresa    AND
 			ID_EMPLEADO       =  @pIdEmpleado    AND
			CVE_TIPO_NOMINA   =  @pCveTipoNomina 

    SELECT  @imp_prima_ano = SUM(IMP_CONCEPTO)  FROM  NO_NOMINA WHERE
	        SUBSTRING(ANO_PERIODO,1,4)  =  @ano_prima AND
			ID_CLIENTE   =     @pIdCliente            AND
			CVE_EMPRESA  =     @pCveEmpresa           AND
			CVE_TIPO_NOMINA =  @pCveTipoNomina        AND
			ID_EMPLEADO  =     @pIdEmpleado           AND
		   (CVE_CONCEPTO IN (@k_prima_vac, @k_prima_vac_dev))
			
	SET  @pDiasVaca  =  ISNULL(@pDiasVaca,0)   

	SET  @pPrima_vac =  (@pSueldo / @num_dias_mes) * (@pje_prima_vac/100) * @pDiasVaca
	SELECT 'sdo ' + CONVERT(VARCHAR(10),@pSueldo)
	SELECT 'dias mes ' + CONVERT(VARCHAR(10),@num_dias_mes)
	SELECT 'Pje ' + CONVERT(VARCHAR(10),@pje_prima_vac)
	SELECT 'Dias Vaca ' + CONVERT(VARCHAR(10),@pDiasVaca)
    SET  @pPrima_vac_grab  =  0

	IF  @imp_prima_ano  > @imp_tope_prima
	BEGIN
	  SET @pPrima_vac_grab = @pPrima_vac
   	  SET @pPrima_vac      = 0
	END
	ELSE
	BEGIN
	  IF  (@imp_prima_ano + @pPrima_vac) > @imp_tope_prima
	  BEGIN
	    SET @pPrima_vac_grab  =  (@imp_prima_ano + @pPrima_vac - @imp_tope_prima)
		SET @pPrima_vac = @pPrima_vac - @pPrima_vac_grab
	  END
	END
END

SET @pPrima_vac_grab = (@imp_prima_ano + @pPrima_vac) - @imp_tope_prima

