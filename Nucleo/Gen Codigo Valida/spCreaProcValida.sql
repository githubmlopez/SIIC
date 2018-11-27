USE DICCIONARIO
GO

--EXEC spCreaProcValida 'ADMON01'

ALTER PROCEDURE  [dbo].[spCreaProcValida] @pBaseDatos varchar(10)
AS
BEGIN

  CREATE TABLE #LINEAMODEL (LINEA varchar(200))

-------------------------------------------------------------------------------
-- Creación de Procedimientos de Validación de Integridad
-------------------------------------------------------------------------------
  DECLARE  @NunRegistros int, 
           @RowCount     int

  DECLARE  @nom_tabla    varchar(30)

  DECLARE  @k_total      varchar(1)  =  'T'

  DECLARE  @TTabla       TABLE
          (RowID         int  identity(1,1),
		   NOM_TABLA     varchar(30))
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTabla  (NOM_TABLA)  
  SELECT NOM_TABLA  FROM FC_TABLA  WHERE
  NOM_TABLA <> 'sysdiagrams'

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA FROM @TTabla
	WHERE  RowID  =  @RowCount

    BEGIN TRY
    EXEC spCreaScriptValida @pBaseDatos, @nom_tabla, @k_total
	END TRY
	BEGIN CATCH
	SELECT LTRIM(@nom_tabla + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
	END CATCH
    SET  @RowCount = @RowCount + 1
  END

  SELECT * FROM #LINEAMODEL

END
