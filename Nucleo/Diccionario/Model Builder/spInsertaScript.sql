USE [DICCIONARIO]
GO
/****** Object:  StoredProcedure [dbo].[spInsertaScript]    Script Date: 15/08/2018 01:16:23 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spInsertaScript]  @pCadena varchar(500), @pSangria int
AS

BEGIN

INSERT INTO #LINEAMODEL VALUES
(REPLICATE(' ',@pSangria) + @pCadena)

END