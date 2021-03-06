USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtDirProc]    Script Date: 24/07/2020 07:41:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Funcion que obtiene el directorio desde donde se leen
-- los archivos para un proceso especifico.
CREATE   FUNCTION [dbo].[fnObtDirProceso]
(
  @pIdCliente   int,
  @pCveEmpresa  varchar(4),
  @pTipoInfo    varchar(6),
  @pIdBloque    varchar(6),
  @pIdFormato   varchar(6),
  @pSeparador   char
)
RETURNS nvarchar(200)
AS
BEGIN
  DECLARE  @vPathBase  varchar(50)

  SELECT @vPathBase = PATHS
    FROM FC_FORMATO
   WHERE CVE_EMPRESA      = @pCveEmpresa
     AND TIPO_INFORMACION = CONVERT(int, @pTipoInfo)
     AND ID_BLOQUE        = CONVERT(int, @pIdBloque)
     AND ID_FORMATO       = CONVERT(int, @pIdFormato)

  RETURN  @vPathBase +
          RIGHT(REPLICATE('0', 6) + CONVERT(nvarchar, @pIdCliente), 6) + @pSeparador +
          @pCveEmpresa + @pSeparador +
          @pTipoInfo + @pSeparador +
          @pIdFormato
END
