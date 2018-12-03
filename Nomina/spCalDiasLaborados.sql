USE [ADNOMINA01]
GO
/****** Calcula dias laborados del periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalDiasLaborados] (@pIdCliente       int,
                                             @pCveEmpresa      varchar(4),
									         @pIdEmpleado      int,
								             @pCveTipoNomina   varchar(2),
									         @pAnoPeriodo      varchar(6),
									         @pDiasPeriodo     int OUT,
											 @pDiasIncap       int OUT,
											 @pDiasFaltas      int OUT,
											 @pDiasLaborados   int OUT,
											 @BCorrecto        bit OUT)
AS
BEGIN
  
  DECLARE  @k_verdadero   bit         =  1
	       @k_falso       bit         =  0

  IF  EXISTS(SELECT 1 FROM NO_PERIODO  p WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina)
  BEGIN
    SELECT @pDiasPeriodo = NUM_DIAS_PERIODO FROM NO_PERIODO  p WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina)
  END
  ELSE
  BEGIN
    SET  @BCorrecto  =  @k_falso  
  END
    
  EXEC spCalNumIncap  (@pIdCliente,
                       @pCveEmpresa,
			           @pIdEmpleado,
	                   @pCveTipoNomina,
				       @pAnoPeriodo,
				       @pDiasIncap OUT)

  EXEC spCalNumFaltas (@pIdCliente,
                       @pCveEmpresa      varchar(4),
					   @pIdEmpleado      int,
					   @pCveTipoNomina   varchar(2),
					   @pAnoPeriodo      varchar(6),
					   @pDiasFaltas      int OUT)

  SET  @pDiasLaborados  =  @pDiasPeriodo - @pDiasIncap - @pDiasFaltas

END

