USE [DICCIONARIO]
GO
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
create FUNCTION [dbo].[fnCveCatalogo] (@pUrlApi varchar(120))
RETURNS varchar(80)
AS
BEGIN
    DECLARE  @k_cve_catal  varchar(11) = 'cveCatalogo'

  DECLARE  @cve_catalogo varchar(120),
           @indice1      int

  SET  @indice1 = (SELECT CHARINDEX(@k_cve_catal,@pUrlApi) + 12)
  RETURN SUBSTRING(@pUrlApi, @indice1, 120)
END
