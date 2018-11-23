USE [DICCIONARIO]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC spArmaValNull 'ADMON01','CI_FACTURA', 'FK_CI_FACTU_REFERENCE_CI_VENTA','A'

ALTER PROCEDURE spArmaValNull  @pTabla varchar(30),
                               @pNomConstraint varchar(100)
AS
BEGIN
  DECLARE @NunRegistros  int, 
          @RowCount      int,
		  @cadena_script varchar(500),
		  @nom_tabla_sel varchar(30),
		  @nom_campo_w   varchar(30),
		  @remplazo      varchar(80),
		  @remp_part1    varchar(20),
		  @nom_const_ant varchar(100)

  DECLARE @nom_tabla      varchar(30),
          @nom_tabla_ref  varchar(30),
		  @nom_campo      varchar(30),
		  @nom_campo_ref  varchar(30),
		  @tipo_llave     varchar(2),
		  @nom_constraint varchar(100)

  DECLARE @sangria0     int  =  0,
          @sangria1     int  =  2,
          @sangria2     int  =  4,
          @sangria3     int  =  6,
          @sangria4     int  =  8

  DECLARE @TTablaRef AS TABLE
 (RowId                int  IDENTITY(1,1),
  NOM_TABLA            varchar(30), 
  NOM_TABLA_REF        varchar(30),
  NOM_CAMPO            varchar(30),
  NOM_CAMPO_REF        varchar(30),
  TIPO_LLAVE           varchar(2),
  NOM_CONSTRAINT       varchar(100))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTablaRef  (NOM_TABLA, NOM_TABLA_REF, NOM_CAMPO, NOM_CAMPO_REF, TIPO_LLAVE,
                      NOM_CONSTRAINT)
  
  SELECT c.NOM_TABLA, c.NOM_TABLA_REF, cc.NOM_CAMPO, cc.NOM_CAMPO_REF, c.TIPO_LLAVE,
         c.NOM_CONSTRAINT FROM
  FC_CONSTRAINT c, FC_CONSTR_CAMPO cc
  WHERE  c.NOM_TABLA       =  @pTabla            AND
         c.NOM_CONSTRAINT  =  @pNomConstraint    AND
		 c.NOM_TABLA       =  cc.NOM_TABLA       AND
         c.NOM_CONSTRAINT  =  cc.NOM_CONSTRAINT  ORDER BY NOM_CONSTRAINT

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  SET @nom_const_ant = ' '

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @nom_tabla =  NOM_TABLA, @nom_tabla_ref  = NOM_TABLA_REF,
	       @nom_campo =  NOM_CAMPO, @nom_campo_ref = NOM_CAMPO_REF, 
		   @tipo_llave = TIPO_LLAVE, @nom_constraint = NOM_CONSTRAINT
	FROM  @TTablaRef 
	WHERE RowID  =  @RowCount 

    SET  @nom_tabla_sel =   @nom_tabla
    SET  @nom_campo_w   =   @nom_campo_ref
 
    IF  @nom_constraint <> @nom_const_ant
    BEGIN
      SET @nom_const_ant = @nom_constraint
      SET @cadena_script  =  'IF '
      EXEC spInsertaScript @cadena_script, @sangria1
    END

    SET  @cadena_script = '@' + LOWER(@nom_campo) +
	REPLICATE(' ', (25 - LEN(@nom_campo))) +  '  IS NOT NULL'

	IF  @RowCount < @NunRegistros
	BEGIN
	  SET  @cadena_script =  @cadena_script + '  AND'
	END
	ELSE
	BEGIN
	  SET  @cadena_script =  @cadena_script + ' '
	END

    EXEC spInsertaScript @cadena_script, @sangria1

    SET @RowCount     =  @RowCount + 1
  END

  SET  @cadena_script = 'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria1

END