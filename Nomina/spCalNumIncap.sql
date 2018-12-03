USE [ADNOMINA01]
GO
/****** Calcula incapacidades por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalNumIncap] (@pIdCliente       int,
                                        @pCveEmpresa      varchar(4),
									    @pIdEmpleado      int,
								        @pCveTipoNomina   varchar(2),
									    @pAnoPeriodo      varchar(6),
									    @pDiasIncap       int OUT)
AS
BEGIN

  DECLARE  @ano_periodo   varchar(6)  =  ' '
           @num_dias_p1   int,
		   @num_dias_p2   int

  DECLARE  @k_verdadero   bit         =  1
 
  SELECT  @ano_periodo  =  ANO_PERIODO,
          @num_dias_p1  =  NUM_DIAS_P1,
		  @num_dias_pn   = NUM_DIAS_PN
  FROM    NO_AUSENCIA_PER a
  WHERE
  a.ID_CLIENTE       = @pIdCliente      AND
  a.CVE_EMPRESA      = @pCveEmpresa     AND
  a.ID_EMPLEADO      = @pIdEmpleado     AND
  a.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  @pAnoPeriodo BETWEEN  i.ANO_PERIODO_INI, i.ANO_PERIODO_FIN

  SET  @num_dias_p1  =  ISNULL(@num_dias_p1,0)
  SET  @num_dias_pn  =  ISNULL(@num_dias_pn,0)

  IF  @pAnoPeriodo = ANO_PERIODO_INI
  BEGIN
	SET  @pDiasIncap  =  @num_dias_p1
  END
  ELSE
  BEGIN
    IF  @pAnoPeriodo = ANO_PERIODO_INI
    BEGIN
	  SET  @pDiasIncap  =  @num_dias_pn
	END
	ELSE
	BEGIN
      SET  @pDiasIncap  =  ISNULL((SELECT  p.NUM_DIAS_PERIODO  FROM  NO_PERIODO p WHERE 
	                        p.ID_CLIENTE       = @pIdCliente      AND
                            p.CVE_EMPRESA      = @pCveEmpresa     AND
                            p.ID_EMPLEADO      = @pIdEmpleado     AND
                            p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
                            p.ANO_PERIODO      = @pAnoPeriodo),999999)
	END
  END

END

