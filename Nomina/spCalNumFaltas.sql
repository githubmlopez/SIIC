USE [ADNOMINA01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalNumFaltas')
BEGIN
  DROP  PROCEDURE spCalNumFaltas
END
GO
--EXEC spCalNumFaltas 1,1,1,'CU','NOMINA','S','201801',1,0,' ',' '
CREATE PROCEDURE [dbo].[spCalNumFaltas]
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
@pDiasFaltas      int OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @num_dias          int

  DECLARE  @k_verdadero       bit         =  1,
           @k_falso           bit         =  0,
		   @k_error           varchar(1)  =  'E'
 
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
  i.ANO_PERIODO      = @pAnoPeriodo     AND
  i.ID_EMPLEADO      = @pIdEmpleado     AND
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
	FROM   @TFalta  WHERE  RowID = @RowCount

	SET  @pDiasFaltas  =  @pDiasFaltas  +  ISNULL(@num_dias,0)

    SET @RowCount     = @RowCount + 1
  END
-- SELECT CONVERT(VARCHAR(30), @pDiasFaltas)
END

