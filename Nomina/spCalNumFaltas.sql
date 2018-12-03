USE [ADNOMINA01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalNumFaltas] (@pIdCliente       int,
                                         @pCveEmpresa      varchar(4),
									     @pIdEmpleado      int,
								         @pCveTipoNomina   varchar(2),
									     @pAnoPeriodo      varchar(6),
									     @pDiasFaltas      int OUT)
AS
BEGIN

  DECLARE  @k_verdadero          bit         =  1
 
-------------------------------------------------------------------------------
-- Calculo faltas del periodo
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TFalta           TABLE
          (RowID             int  identity(1,1),
		   NUM_DIAS          int)

  INSERT  @TFalta(NUM_DIAS) 
  SELECT  NUM_DIAS
  FROM    NO_INCIDENCIA i, NO_CONCEPTO c
  WHERE
  i.ID_CLIENTE       = @pIdCliente      AND
  i.CVE_EMPRESA      = @pCveEmpresa     AND
  i.ID_EMPLEADO      = @pIdEmpleado     AND
  i.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  i.ANO_PERIODO      = @pAnoPeriodo
  i.ID_CLIENTE       = c.ID_CLIENTE     AND
  i.CVE_EMPRESA      = c.CVE_EMPRESA    AND
  i.CVE_CONCEPTO     = c.CVE_CONCEPTO   AND
  c.B_FALTA_INJUST   = @k_verdadero

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @num_dias = NUM_DIAS
	FROM   @TFaltas  WHERE  RowID = @RowCount

	SET  @pDiasFaltas  =  @pDiasFaltas  +  @num_dias

    SET @RowCount     = @RowCount + 1
  END

END

