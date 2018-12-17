USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalCuotObrPat')
BEGIN
  DROP  PROCEDURE spCalCuotObrPat
END
GO
--EXEC spCalCuotObrPat 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,'IMSS',2,2,100.567,' ',' '
CREATE PROCEDURE [dbo].[spCalCuotObrPat] 
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
@pCveEntidad      varchar(4),
@pIdRamo          int,
@pIdConcepto      int,
@pSBC             numeric(16,6),
@pError           varchar(80)  OUT,
@pMsgError        varchar(400)  OUT
)

AS
BEGIN
  DECLARE  @pje_obrero        numeric(8,4)  = 0,
           @pje_patron        numeric(8,4)  = 0,
		   @imp_base_calculo  numeric(16,2) = 0,
		   @dias_base         int           = 0,
	       @b_ausencia        bit           = 0,
		   @b_incapacidad     bit           = 0,
		   @b_correcto        bit           = 1,
		   @imp_tope          numeric(16,2) = 0,
		   @cve_base          varchar(4)    = 0,
		   @num_base          int           = 0,
		   @num_faltas        int           = 0,
		   @num_incapacidad   int           = 0,
		   @uma               numeric(16,2) = 0,
		   @dias_periodo      int           = 0,
		   @cuota_obrero      numeric(16,2) = 0 ,
		   @cuota_patron      numeric(16,2) = 0

  DECLARE  @imp_base          numeric(16,2) = 0

  DECLARE  @k_verdadero       bit           =  1,
		   @k_falso           bit           =  0,
		   @k_SBC             varchar(4)    =  'SBC',
		   @k_UMA             varchar(4)    =  'UMA',
		   @k_UMAS            varchar(4)    =  'UMAS',
		   @k_error           varchar(1)    =  'E',
		   @k_warning         varchar(1)    =  'W'

  SELECT @num_faltas = NUM_FALTAS, @num_incapacidad = NUM_INCAPACIDAD FROM NO_INF_EMP_PER  WHERE
  ANO_PERIODO     =  @pAnoPeriodo  AND
  ID_CLIENTE      =  @pIdCliente   AND
  CVE_EMPRESA     =  @pCveEmpresa  AND
  ID_EMPLEADO     =  @pIdEmpleado  AND
  CVE_TIPO_NOMINA =  @pCveTipoNomina

  SELECT @uma =  UMA FROM NO_EMPRESA WHERE
  ID_CLIENTE      =  @pIdCliente   AND
  CVE_EMPRESA     =  @pCveEmpresa    

  SELECT @dias_periodo = NUM_DIAS_PERIODO FROM NO_PERIODO  WHERE
  ANO_PERIODO     =  @pAnoPeriodo    AND
  ID_CLIENTE      =  @pIdCliente     AND
  CVE_EMPRESA     =  @pCveEmpresa    AND
  CVE_TIPO_NOMINA =  @pCveTipoNomina AND
  ANO_PERIODO     =  @pAnoPeriodo

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

	SET  @dias_base  =  @dias_periodo

	--SELECT 'Dias Base ' + CONVERT(VARCHAR(10), @dias_base)
	--SELECT 'Incap. ' + CONVERT(VARCHAR(10), @num_incapacidad)
	--SELECT 'Faltas ' + CONVERT(VARCHAR(10), @num_faltas)

    IF  @b_incapacidad  =  @k_verdadero
	BEGIN
      SET  @dias_base  =  @dias_base  -  @num_incapacidad
	END

	IF  @b_ausencia  =  @k_verdadero
	BEGIN
      SET  @dias_base  =  @dias_base  -  @num_faltas
	END
	--SELECT 'Dias Base 2 ' + CONVERT(VARCHAR(10), @dias_base)
	IF  @cve_base  =  @k_UMA
	BEGIN
	  SET   @imp_base_calculo  =  @uma  *  @num_base *  @dias_base    
      --SELECT 'uma ' + CONVERT(VARCHAR(10), @uma)
      --SELECT 'Num Base ' + CONVERT(VARCHAR(10), @num_base)
      --SELECT 'Imp Base ' + CONVERT(VARCHAR(10), @imp_base_calculo)
	END
	ELSE
	BEGIN
      IF  @cve_base  =  @K_UMAS
	  BEGIN
	    SET   @imp_base_calculo  =  (@pSBC  -  (@uma *  @num_base)) *  @dias_base
	  END
	  ELSE
      BEGIN
        IF  @cve_base  =  @k_SBC
	    BEGIN
	      SET   @imp_base_calculo  =  @pSBC  *  @num_base *  @dias_base
	    END
	    ELSE
	    BEGIN
	      SET  @b_correcto  =  @k_falso 
	    END
      END 
	END
  END
  ELSE
  BEGIN
    SET  @b_correcto  =  @k_falso  
  END

  IF   @b_correcto  =  @k_falso
  BEGIN
    SET  @pError    =  'No existe Periodo o Par. Empresa ' + CONVERT(VARCHAR(10),@pIdEmpleado) + ' ' +
	ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
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
  ELSE
  BEGIN 
    
	IF   @imp_base_calculo  >= @imp_tope
    BEGIN
      SET  @cuota_obrero  =  @imp_base_calculo *  (@pje_obrero / 100)
      --SELECT 'Pje Obrero ' + CONVERT(VARCHAR(10), @pje_obrero / 100)
      --SELECT 'Imp Tope ' + CONVERT(VARCHAR(10), @imp_tope)
      --SELECT 'Cuota Obrero ' + CONVERT(VARCHAR(10), @cuota_obrero)
    END
    ELSE
    BEGIN
      SET  @cuota_obrero  =  @imp_tope
    END

    BEGIN TRY

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
    @cuota_patron,
    @cuota_obrero,
    @imp_base_calculo)    

    END TRY
  
    BEGIN CATCH
      SET  @pError    =  'Error Insert Det. IMSS ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento
	  @pIdProceso,
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pCveAplicacion,
      @k_error,
      @pError,
      @pMsgError

    END CATCH
  END
END

