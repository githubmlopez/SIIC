USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtValNum')
BEGIN
  DROP  FUNCTION fnObtValNum
END
GO
CREATE FUNCTION [dbo].[fnObtValNum] 
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
RETURNS numeric(16,2)						  
AS
BEGIN
  DECLARE  @val_dato_c  varchar(max),
           @val_dato_n  numeric(16,2)
  
  SET  @val_dato_c =
 (SELECT SUBSTRING(LTRIM(VAL_DATO),@pPosIni,@pPosFin) FROM FC_CARGA_COL_DATO c WHERE
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
	CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0))
  END
  ELSE
  BEGIN
	SET  @val_dato_n  =  0
  END

  RETURN @val_dato_n 

END

