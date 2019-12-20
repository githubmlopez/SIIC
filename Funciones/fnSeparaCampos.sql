USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnSeparaCampos')
BEGIN
  DROP  FUNCTION fnSeparaCampos
END
GO
CREATE FUNCTION [dbo].[fnSeparaCampos] 
(
@pIdCliente  int,
@pCveEmpresa varchar(4),
@pIdFormato  int,
@pIdBloque   int,
@pAnoPeriodo varchar(6),
@pRowCount   int,
@pColumna    int,
@pPosIni     int,
@pPosFin     int,
@pformato    int
)
RETURNS date						  
AS
BEGIN

END

