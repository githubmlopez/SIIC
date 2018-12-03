USE [ADNOMINA01]
GO@pDiasLabor
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalCuotObrPat] (@pAnoPeriodo      varchar(6),
                                          @pIdCliente       int,
										  @pCveEmpresa      varchar(4),
										  @pIdEmpleado      int,
                                          @pCveEntidad      varchar(4),
                                          @pIdRamo          int,
										  @pIdConcepto      int,
										  @pDiasMes         int,
										  @pDiasTrabajados  int,
										  @pDiasIncapacidad int,
										  @pDiasFaltas      int,
                                          @pFactIntegracion numeric(8,4),
										  @pSalarioMinimo   numeric(16,2),
                                          @pCuotaObrero     numeric(16,2) OUT,
                                          @pCuotaPatron     numeric(16,2) OUT,
										  @pBCorrecto       bit OUT)

AS
BEGIN
  DECLARE  @pje_obrero        numeric(8,4),
           @pje_patron        numeric(8,4),
		   @imp_base_calculo  numeric(16,2),
		   @dias_base         int,
	       @b_ausencia        bit,
		   @b_incapacidad     bit,
		   @imp_tope          numeric(16,2),
		   @cve_base          varchar(4),
		   @num_base          int

  DECLARE  @imp_base          numeric(16,2) 

  DECLARE  @k_verdadero       bit            =  1,
		   @k_falso           bit            =  0,
		   @k_SBC             varchar(4)     =  'SBC',
		   @K_UMA             varchar(4)     =  'UMA'

  IF EXISTS(
  SELECT 1 FROM NO_CONC_CUOTA c  WHERE 
  c.CVE_ENTIDAD   = @pCveEntidad    AND
  c.ID_RAMO       = @pIdRamo        AND
  c.ID_CONCEPTO   = @pIdConcepto)   
  BEGIN
    SELECT @pje_obrero = c.PJE_OBRERO, @pje_patron = c.PJE_PATRON,
	       @b_ausencia = c.B_AUSENCIA, @b_incapacidad  =  c.B_INCAPACIDAD,
		   @imp_tope = c.IMP_TOPE, @cve_base = c.CVE_BASE, @num_base = c.NUM_BASE
	FROM NO_CONC_CUOTA c  WHERE 
    c.CVE_ENTIDAD   = @pCveEntidad    AND
    c.ID_RAMO       = @pIdRamo        AND
    c.ID_CONCEPTO   = @pIdConcepto   

	SET  @dias_base  =  @pDiasTrabajados

    IF  @b_incapacidad  =  @k_verdadero
	BEGIN
      SET  @dias_base  =  @dias_base  -  @pDiasIncapacidad
	END

	IF  @b_ausencia  =  @k_verdadero
	BEGIN
      SET  @dias_base  =  @dias_base  -  @pDiasFaltas
	END

	IF  @cve_base  =  @k_UMA
	BEGIN
	  SET   @imp_base_calculo  =  @pSalarioMinimo  *  @num_base *  @dias_base    
	END
	ELSE
	BEGIN
      IF  @cve_base  =  @k_SBC
	  BEGIN
	    SET   @imp_base_calculo  =  @pFactIntegracion  *  @num_base *  @dias_base
	  END
	  ELSE
	  BEGIN
	    SET  @pBCorrecto  =  @k_falso 
	  END
	END
  END
  ELSE
  BEGIN
    SET  @pBCorrecto  =  @k_falso  
  END
 
  IF   @pCuotaObrero  <= @imp_tope
  BEGIN
    SET  @pCuotaObrero  =  @imp_base_calculo *  (@pje_obrero / 100)
  END
  ELSE
  BEGIN
    SET  @pCuotaObrero  =  @imp_tope
  END

  IF   @pCuotaPatron  <= @imp_tope
  BEGIN
    SET  @pCuotaPatron  =  @imp_base_calculo *  (@pje_obrero / 100)
  END
  ELSE
  BEGIN
    SET  @pCuotaPatron  =  @imp_tope
  END

  INSERT  INTO NO_DET_CONC_OB_PAT 
 (ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_EMPLEADO,
  CVE_ENTIDAD,
  ID_RAMO,
  ID_CONCEPTO,
  IMP_CUOT_PATRON,
  IMP_CUOT_OBRERO,
  IMP_BASE_SALARIAL)  VALUES
 (@pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pIdEmpleado,
  @pCveEntidad,
  @pIdRamo,
  @pIdConcepto,
  @pCuotaPatron,
  @pCuotaObrero,
  @imp_base_calculo)    
END

