USE DICCIONARIO
GO 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
-- EXEC spCreaSinonimo
ALTER PROCEDURE [dbo].[spCreaSinonimo]  
AS

BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @nom_tabla         varchar(30),
           @nom_tabla_c       varchar(30), 
           @nom_tabla_ref     varchar(30),
		   @nom_constraint    varchar(100) 

----------------------------------------------------------------------------------
-- Asignacion de Sinonimos para tablas con mas de una referencia a la misma tabla
----------------------------------------------------------------------------------

  DECLARE  @TSinonimos       TABLE 
          (RowID            int  identity(1,1),
		   NOM_TABLA        varchar(30),
		   NOM_TABLA_REF    varchar(30))
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TSinonimos  (NOM_TABLA,NOM_TABLA_REF)  
  SELECT NOM_TABLA, NOM_TABLA_REF FROM FC_CONSTRAINT WHERE NOM_TABLA_REF IS NOT NULL GROUP BY 
  NOM_TABLA, NOM_TABLA_REF
  HAVING COUNT(*) > 1

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA, @nom_tabla_ref = NOM_TABLA_REF FROM @TSinonimos 
	WHERE RowID = @RowCount 

	SELECT TOP(1) @nom_tabla_c = NOM_TABLA, @nom_constraint = NOM_CONSTRAINT  FROM  FC_CONSTRAINT
	WHERE NOM_TABLA = @nom_tabla AND NOM_TABLA_REF = @nom_tabla_ref

	UPDATE  FC_CONSTRAINT SET SINONIMO = '1' WHERE  NOM_TABLA = @nom_tabla AND NOM_CONSTRAINT = @nom_constraint

    SET @RowCount     =  @RowCount + 1
  END

  UPDATE FC_CONSTRAINT SET PREF_TAB_RECUR = '1' WHERE NOM_TABLA = NOM_TABLA_REF

END
