USE DICCIONARIO
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spInsertaScript]  @pCadena varchar(500), @pSangria int
as

BEGIN

INSERT INTO #LINEAMODEL VALUES
(REPLICATE(' ',@pSangria) + @pCadena)

END