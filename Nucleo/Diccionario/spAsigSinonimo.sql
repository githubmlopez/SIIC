USE DICCIONARIO
GO
/****** Valida existencia de archivo a cargar ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM DICCIONARIO.sys.procedures WHERE Name =  'spAsigSinonimo')
BEGIN
  DROP  PROCEDURE spAsigSinonimo
END
GO
--EXEC spAsigSinonimo 
CREATE PROCEDURE [dbo].[spAsigSinonimo] 
--(
--@pNomTabla  varchar(30)
--)

AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @nom_tabla         varchar(30),
           @sin_max           int

-------------------------------------------------------------------------------
-- Verificación de Tipos de Conciliación
-------------------------------------------------------------------------------

  DECLARE  @TTabla       TABLE
          (RowID          int  identity(1,1),
		   NOM_TABLA      varchar(30))
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTabla (NOM_TABLA)  
  SELECT NOM_TABLA  FROM FC_TABLA_EX
  WHERE SINONIMO  IS NULL OR SINONIMO = ' '
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA FROM @TTabla
	WHERE  RowID  =  @RowCount

	SET @sin_max = CONVERT(INT,
	(SELECT ISNULL(MAX(SINONIMO),0) FROM FC_TABLA_EX))
    
	SET @sin_max = @sin_max + 1

	UPDATE FC_TABLA_EX
	SET SINONIMO = replicate ('0',(06 - len(@sin_max))) + CONVERT(VARCHAR, @sin_max)
	WHERE NOM_TABLA = @nom_tabla

	SET @RowCount     =  @RowCount  + 1
  END
END