USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnobtObtColumna')
BEGIN
  DROP  FUNCTION fnobtObtColumna
END
GO
CREATE FUNCTION [dbo].[fnobtObtColumna] 
(
@pIdCliente  int,
@pCveEmpresa varchar(4),
@pTipoInf    int,
@pIdBloque   int,
@pIdFormato  int,
@pAnoPeriodo varchar(6),
@pRowCount   int,
@pColumna    int,
@pPosIni     int,
@pPosFin     int
)
RETURNS varchar(250)						  
AS
BEGIN
  RETURN 
  (SELECT SUBSTRING(LTRIM(VAL_DATO),@pPosIni,@pPosFin) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
          ID_CLIENTE       = @pIdCliente  AND
          CVE_EMPRESA      = @pCveEmpresa AND
          TIPO_INFORMACION = @pTipoInf    AND 
          ID_FORMATO       = @pIdFormato  AND
          ID_BLOQUE        = @pIdBloque   AND
          PERIODO          = @pAnoPeriodo AND
	      NUM_REGISTRO     = @pRowCount   AND
          NUM_COLUMNA      = @pColumna
)  

END

