USE [ADNOMINA01]
GO
/* Calcula información acumulada de percepciones grabables, isr y subsidios ademas de   */
/* montos grabables por concepto de sueldo y monto grabado de todas las percepciones    */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spAcumPeriodo')
BEGIN
  DROP  PROCEDURE spAcumPeriodo
END
GO
--EXEC 'spAcumPeriodo' 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,' ',' '
CREATE PROCEDURE [dbo].[spAcumPeriodo]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pSueldoMensual   numeric(18,2),
@pGrabIsrAcum     varchar(1),
@pCveTipoPago     varchar(1),
@pImpCalIsr       numeric(18,2) OUT,
@pImpGravPer      numeric(18,2) OUT,
@pImpGravAcum     numeric(18,2) OUT,
@pImpIsrAcum      numeric(18,2) OUT,
@pImpSubAcum      numeric(18,2) OUT,
@pError           varchar(80)   OUT,
@pMsgError        varchar(400)  OUT

)
AS
BEGIN
  DECLARE  @k_verdadero       bit           =  1,
		   @k_falso           bit           =  0,
		   @k_error           varchar(1)    =  'E',
		   @k_cve_isr         varchar(4)    =  '0001',
		   @k_cve_subsidio    varchar(4)    =  '0014',
   		   @k_cve_sdo         varchar(4)    =  '0011',
		   @k_cve_bono        varchar(4)    =  '0100',
		   @k_cve_aguinaldo   varchar(4)    =  '0150',
		   @k_no_aplica       varchar(1)    =  'N',
		   @k_mes             varchar(1)    =  'M',
		   @k_ano             varchar(1)    =  'A',
		   @k_normal          varchar(1)    =  'N',
		   @k_sueldo          varchar(1)    =  'S',
		   @k_bono            varchar(1)    =  'B',
		   @k_aguinaldo       varchar(1)    =  'A'

  DECLARE  @imp_per_sdo       numeric(16,2) =  0,
           @tot_ing_grab      numeric(16,2) =  0,
		   @imp_grab_acum     numeric(16,2) =  0,
		   @num_meses_bono    int,
		   @mes_periodo       varchar(6)    =  ' ',
		   @num_mes           int           =  0,
		   @cve_grab_isr      varchar(1)    =  ' '

  /* Calculo del importe por concepto de salario del periodo actual, bono o aguinaldo */

  SELECT   @imp_per_sdo = n.IMP_CONCEPTO  
  FROM     NO_PRE_NOMINA n WHERE
  n.ANO_PERIODO     = @pAnoPeriodo     AND
  n.ID_CLIENTE      = @pIdCliente      AND
  n.CVE_EMPRESA     = @pCveEmpresa     AND
  n.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  n.ID_EMPLEADO     = @pIdEmpleado     AND
((@pCveTipoPago     = @k_sueldo        AND  
  n.CVE_CONCEPTO    = @k_cve_sdo)      OR
 (@pCveTipoPago     = @k_bono          AND  
  n.CVE_CONCEPTO    = @k_cve_bono)     OR
 (@pCveTipoPago     = @k_aguinaldo     AND  
  n.CVE_CONCEPTO    = @k_cve_aguinaldo))

/*  Obtiene el mes del periodo que se esta procesando */

  SELECT   @mes_periodo =  CVE_MES, @cve_grab_isr  =  CVE_GRAV_ISR  FROM  NO_PERIODO  WHERE
           ID_CLIENTE       =  @pIdCliente     AND
		   CVE_EMPRESA      =  @pCveEmpresa    AND
		   CVE_TIPO_NOMINA  =  @pCveTipoNomina AND
		   ANO_PERIODO      =  @pAnoPeriodo

/* Obtiene Acumulados (sin contar periodo actual) dependiendo de la clave que indica periodos a acumular  */

  IF  @pCveTipoPago  =  @k_sueldo  
  BEGIN
    SELECT   @pImpGravAcum = SUM(i.IMP_BASE_GRAV), @pImpIsrAcum = SUM(IMP_ISR),
             @pImpSubAcum      = SUM(IMP_SUBSIDIO)    
     FROM     NO_INF_EMP_PER i WHERE
    i.ANO_PERIODO     = @pAnoPeriodo      AND
    i.ID_CLIENTE      = @pIdCliente       AND
    i.CVE_EMPRESA     = @pCveEmpresa      AND
    i.CVE_TIPO_NOMINA = @pCveTipoNomina   AND
    i.ID_EMPLEADO     = @pIdEmpleado      AND
  ((@cve_grab_isr     = @k_ano            AND
    SUBSTRING(i.ANO_PERIODO,1,4)  =  SUBSTRING(@pAnoPeriodo,1,4)) OR
   (@cve_grab_isr   IN  (@k_mes, @k_normal)            AND
    dbo.fnVerMesCont(i.ID_CLIENTE, i.CVE_EMPRESA, i.CVE_TIPO_NOMINA, i.ANO_PERIODO, @pAnoPeriodo) = @k_verdadero)) 
  END
  ELSE
  BEGIN
    SET  @pImpCalIsr    = 0
    SET  @pImpGravAcum  = 0
	SET  @pImpIsrAcum   = 0
	SET  @pImpSubAcum   = 0
  END

/* Para pago de bono */

  IF  @pCveTipoPago  =  @k_bono
  BEGIN
    SELECT @num_meses_bono  =  COUNT(*)  FROM  NO_PERIODO  WHERE
    ID_CLIENTE      = @pIdCliente       AND
    CVE_EMPRESA     = @pCveEmpresa      AND
    CVE_TIPO_NOMINA = @pCveTipoNomina   AND
    ANO_PERIODO     = @pAnoPeriodo      AND
    SUBSTRING(ANO_PERIODO,1,4)  =  SUBSTRING(@pAnoPeriodo,1,4)  AND
	CVE_MES        <=  @num_mes         AND
	@pCveTipoPago      NOT IN  (@k_bono)
	
	SET  @num_meses_bono  =  ISNULL(@num_meses_bono,0)

	SET  @pImpCalIsr  =  (@imp_per_sdo /  @num_meses_bono) + @pSueldoMensual
  END
  ELSE
  BEGIN

/* Para pago de aguinaldo */

  IF  @pCveTipoPago  =  @k_aguinaldo
  BEGIN
    SET  @pImpCalIsr  =  @imp_per_sdo 
  END

  END
END
