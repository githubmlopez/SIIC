USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtValDate')
BEGIN
  DROP  FUNCTION fnObtValDate
END
GO
CREATE FUNCTION [dbo].[fnObtValDate] 
(
@pIdCliente   int,
@pCveEmpresa  varchar(4),
@pTipoInfo    int,
@pIdBloque    int,
@pTipoFormato int,
@pAnoPeriodo  varchar(6),
@pRowCount    int,
@pColumna     int,
@pPosIni      int,
@pPosFin      int,
@pformato     int
)
RETURNS date						  
AS
BEGIN
  DECLARE  @val_dato_c  varchar(max),
           @val_dato_d  date
  
  SET  @val_dato_c =
 (SELECT SUBSTRING(LTRIM(VAL_DATO),@pPosIni,@pPosFin) FROM FC_CARGA_COL_DATO c WHERE
          CVE_EMPRESA       = @pCveEmpresa  AND
          TIPO_INFORMACION  = @pTipoInfo    AND
		  ID_FORMATO        = @pTipoFormato AND
          ID_BLOQUE         = @pIdBloque    AND
          PERIODO           = @pAnoPeriodo  AND
	      NUM_REGISTRO      = @pRowCount    AND
          NUM_COLUMNA       = @pColumna)

  IF  @val_dato_c  <>  ' '
  BEGIN
	SET  @val_dato_d  =
	CONVERT(DATE, LTRIM(@val_dato_c ), @pformato) 
  END
  ELSE
  BEGIN
	SET  @val_dato_d  =  NULL
  END

  RETURN @val_dato_d 

END

