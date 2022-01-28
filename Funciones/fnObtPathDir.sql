USE ADMON01
GO
-- Funcion que obtiene el directorio desde donde se leen
-- los archivos para un proceso especifico.
CREATE OR ALTER FUNCTION dbo.fnObtDirProc
(
  @pIdCliente   int,
  @pCveEmpresa  varchar(4),
  @pIdProceso   numeric(9, 0),
  @pSeparador   char
)
RETURNS nvarchar(200)
AS
BEGIN
  DECLARE @vTipoInfo  varchar(6),
          @vIdBloque  varchar(6),
          @vIdFormato varchar(6),
          @vPathBase  varchar(50)

  SELECT @vTipoInfo  = SUBSTRING(PARAMETRO,1,6),
         @vIdBloque  = SUBSTRING(PARAMETRO,7,6),
         @vIdFormato = SUBSTRING(PARAMETRO,13,6)
    FROM FC_PROCESO
   WHERE CVE_EMPRESA  = @pCveEmpresa
     AND ID_PROCESO   = @pIdProceso

  SELECT @vPathBase = PATHS
    FROM FC_FORMATO
   WHERE CVE_EMPRESA      = @pCveEmpresa
     AND TIPO_INFORMACION = CONVERT(int, @vTipoInfo)
     AND ID_BLOQUE        = CONVERT(int, @vIdBloque)
     AND ID_FORMATO       = CONVERT(int, @vIdFormato)

  RETURN  @vPathBase +
          RIGHT(REPLICATE('0', 6) + CONVERT(nvarchar, @pIdCliente), 6) + @pSeparador +
          @pCveEmpresa + @pSeparador +
          @vTipoInfo + @pSeparador +
          @vIdFormato
END
GO