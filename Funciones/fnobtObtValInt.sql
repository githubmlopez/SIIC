USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnobtObtValInt')
BEGIN
  DROP  FUNCTION fnobtObtValInt
END
GO
CREATE FUNCTION [dbo].[fnobtObtValInt] 
(
@pIdCliente  int,
@pCveEmpresa varchar(4),
@pTipoInfo   int,
@pIdBloque   int,
@pIdFormato  int,
@pAnoPeriodo varchar(6),
@pRowCount   int,
@pColumna    int,
@pPosIni     int,
@pPosFin     int
)
RETURNS int						  
AS
BEGIN
  DECLARE  @val_dato_c  varchar(max),
           @val_dato_n  int
  
  SET  @val_dato_c =
 (SELECT SUBSTRING(LTRIM(VAL_DATO),@pPosIni,@pPosFin) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
          ID_CLIENTE       = @pIdCliente  AND
          CVE_EMPRESA      = @pCveEmpresa AND
          TIPO_INFORMACION = @pTipoInfo   AND
          ID_BLOQUE        = @pIdBloque   AND
          ID_FORMATO       = @pIdFormato  AND
          PERIODO          = @pAnoPeriodo AND
	      NUM_REGISTRO     = @pRowCount   AND
          NUM_COLUMNA      = @pColumna)

  IF  @val_dato_c  <>  ' '
  BEGIN
	SET  @val_dato_n  =
	CONVERT(INT,REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0))
  END
  ELSE
  BEGIN
	SET  @val_dato_n  =  0
  END

  RETURN @val_dato_n 

END

