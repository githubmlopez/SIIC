USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegDeducPer')
BEGIN
  DROP  PROCEDURE spRegDeducPer
END
GO
--EXEC spRegDeducPer 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '
CREATE PROCEDURE [dbo].[spRegDeducPer] 
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
@pZona            int,
@pCvePuesto       varchar(15),
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pIdRegFiscal     int,
@pIdTipoCont      int,
@pIdBanco         int,
@pIdJorLab        int,
@pIdRegContrat    int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

--  SELECT 'pRegDeducPer'
  DECLARE  @cve_concepto      varchar(4)  =  ' ',
           @imp_concepto      int         =  0,
		   @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_error           varchar(1)  =  'E'

  DECLARE  @NumRegistros      int, 
           @RowCount          int

  DELETE FROM NO_PRE_NOMINA WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN 
  (SELECT  CVE_CONCEPTO
   FROM    NO_PER_DESC_PER pp
   WHERE
   pp.ID_CLIENTE       = @pIdCliente  AND
   pp.CVE_EMPRESA      = @pCveEmpresa AND
   pp.ID_EMPLEADO      = @pIdEmpleado)

-------------------------------------------------------------------------------
-- Calculo de deducciones fijas por periodo indefinido
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TDeduccion       TABLE
          (RowID             int  identity(1,1),
		   CVE_CONCEPTO      varchar(2),
		   IMP_CONCEPTO      numeric(16,2))
 
  INSERT  @TDeduccion(CVE_CONCEPTO, IMP_CONCEPTO) 
  SELECT  p.CVE_CONCEPTO, p.IMP_CONCEPTO
  FROM    NO_PER_DESC_PER p
  WHERE
  p.ID_CLIENTE       = @pIdCliente      AND
  p.CVE_EMPRESA      = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  p.ID_EMPLEADO      = @pIdEmpleado     AND
  B_PER_DEFINIDO     = @k_falso         AND
  ANO_PER_INI        >= @pAnoPeriodo
  SET @NumRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  BEGIN TRY

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @cve_concepto = CVE_CONCEPTO, @imp_concepto = IMP_CONCEPTO
	FROM   @TDeduccion  WHERE  RowID = @RowCount

	EXEC spInsPreNomina  
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @cve_concepto,
    @imp_concepto,
    0,
    0,
    0,
    ' ',
    ' ',
    @pError OUT,
    @pMsgError OUT

    SET @RowCount     = @RowCount + 1

  END

  END TRY
  
  BEGIN CATCH
    SET  @pError    =  'E- Deduc. Pers. ' + '(P)' + ERROR_PROCEDURE() 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
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
-------------------------------------------------------------------------------
-- Calculo de deducciones por periodo definido
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TDeduccion2      TABLE
          (RowID             int  identity(1,1),
		   CVE_CONCEPTO      varchar(2),
		   IMP_CONCEPTO      numeric(16,2))

  INSERT  @TDeduccion2(CVE_CONCEPTO, IMP_CONCEPTO) 
  SELECT  p.CVE_CONCEPTO, a.IMP_CAPITAL + a.IMP_INTERES
  FROM    NO_PER_DESC_PER p, NO_AMORT_INICIO a
  WHERE
  p.ID_CLIENTE       = @pIdCliente        AND
  p.CVE_EMPRESA      = @pCveEmpresa       AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina    AND
  p.ID_EMPLEADO      = @pIdEmpleado       AND
  B_PER_DEFINIDO     = @k_verdadero       AND
  @pAnoPeriodo BETWEEN ANO_PER_INI AND ANO_PER_FIN  AND
  p.ID_CLIENTE       = a.ID_CLIENTE       AND
  p.CVE_EMPRESA      = a.CVE_EMPRESA      AND
  p.CVE_TIPO_NOMINA  = a.CVE_TIPO_NOMINA  AND
  p.ID_EMPLEADO      = a.ID_EMPLEADO      AND
  a.ANO_PERIODO      = @pAnoPeriodo
  SET @NumRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

  SET @RowCount     = 1

  BEGIN TRY

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @cve_concepto = CVE_CONCEPTO, @imp_concepto = IMP_CONCEPTO
	FROM   @TDeduccion2  WHERE  RowID = @RowCount

	EXEC spInsPreNomina  
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @cve_concepto,
    @imp_concepto,
    0,
    0,
    0,
    ' ',
    ' ',
    @pError OUT,
    @pMsgError OUT

    SET @RowCount     = @RowCount + 1
  END

  END TRY
  
  BEGIN CATCH
    SET  @pError    =  'E- Deduc. Periodo ' + CONVERT(VARCHAR(10), @pIdEmpleado) + '(P)' + ERROR_PROCEDURE() 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
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