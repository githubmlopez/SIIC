USE [ADNOMINA01]
GO
/****** Calcula Incidencia por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegIncidencias] (@pIdProceso       numeric(9),
										   @pIdTarea         numeric(9),
										   @pCveUsuario      varchar(8),
										   @pIdCliente       int,
                                           @pCveEmpresa      varchar(4),
										   @pIdEmpleado      int,
								           @pCveTipoNomina   varchar(2),
									       @pAnoPeriodo      varchar(6),
										   @pError           varchar(80) OUT,
										   @pMsgError        varchar(400) OUT)
AS
BEGIN
  DECLARE  @cve_concepto      varchar(4)  =  ' ',
           @imp_concepto      int         =  0,
		   @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0

  DECLARE  @NunRegistros      int, 
           @RowCount          int

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
  FROM    NO_INCIDENCIA i
  WHERE
  p.ID_CLIENTE       = @pIdCliente      AND
  p.CVE_EMPRESA      = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  p.ID_EMPLEADO      = @pIdEmpleado     AND
  ANO_PER_INI        = @pAnoPeriodo

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_concepto = CVE_CONCEPTO, @imp_concepto = IMP_CONCEPTO
	FROM   @TDeduccion  WHERE  RowID = @RowCount

	EXEC spInsPreNomina  @pAnoPeriodo,
                         @pIdCliente,
                         @pCveEmpresa,
                         @pCveTipoNomina,
                         @pIdEmpleado,
                         @cve_concepto,
                         @imp_concepto,
						 0,
                         0,
                         @gpo_transaccion,
                         ' '
    SET @RowCount     = @RowCount + 1

  END

END