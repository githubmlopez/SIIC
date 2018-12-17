USE [ADNOMINA01]
GO
/****** Calcula Incidencia por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegIncidencias')
BEGIN
  DROP  PROCEDURE spRegIncidencias
END
GO
--EXEC spRegIncidencias 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '

CREATE PROCEDURE [dbo].[spRegIncidencias] 
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
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @cve_concepto      varchar(4)  =  ' ',
           @imp_concepto      int         =  0,
		   @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0

  DECLARE  @NunRegistros      int, 
           @RowCount          int


  DELETE FROM NO_PRE_NOMINA WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN 
 (SELECT  i.CVE_CONCEPTO
  FROM    NO_INCIDENCIA i, NO_CONCEPTO c
  WHERE
  i.ANO_PERIODO      = @pAnoPeriodo     AND
  i.ID_CLIENTE       = @pIdCliente      AND
  i.CVE_EMPRESA      = @pCveEmpresa     AND
  i.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  i.ID_EMPLEADO      = @pIdEmpleado     AND
  i.ID_CLIENTE       = c.ID_CLIENTE     AND
  i.CVE_EMPRESA      = c.CVE_EMPRESA    AND
  i.CVE_CONCEPTO     = c.CVE_CONCEPTO   AND
  c.B_RECIBO         = @k_verdadero) 

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
  SELECT  i.CVE_CONCEPTO, i.IMP_CONCEPTO
  FROM    NO_INCIDENCIA i, NO_CONCEPTO c
  WHERE
  i.ANO_PERIODO      = @pAnoPeriodo     AND
  i.ID_CLIENTE       = @pIdCliente      AND
  i.CVE_EMPRESA      = @pCveEmpresa     AND
  i.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  i.ID_EMPLEADO      = @pIdEmpleado     AND
  i.ID_CLIENTE       = c.ID_CLIENTE     AND
  i.CVE_EMPRESA      = c.CVE_EMPRESA    AND
  i.CVE_CONCEPTO     = c.CVE_CONCEPTO   AND
  c.B_RECIBO         = @k_verdadero          

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
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
END