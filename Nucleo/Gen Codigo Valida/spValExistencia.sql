USE [DICCIONARIO]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC spValExistencia 'CI_FACTURA', 'FK_CI_FACTU_REFERENCE_CI_VENTA','A'
ALTER PROCEDURE spValExistencia  @pBaseDatos varchar(10), @pTabla  varchar(30), @pNomConstraint varchar(100),
                                 @pTipoMovto varchar(1) 
AS
BEGIN
  DECLARE @NunRegistros  int, 
          @RowCount      int,
		  @cadena_script varchar(500),
		  @nom_tabla_sel varchar(30),
		  @nom_campo_w   varchar(30),
		  @remplazo      varchar(80),
		  @remp_part1    varchar(80),
		  @nom_const_ant varchar(100),
		  @b_perm_null   bit,
		  @b_end_pk      bit,
		  @incremento    int,
		  @incremento2   int,
		  @num_error     int 

  DECLARE @k_verdadero  bit         = 1,
          @k_falso      bit         = 0,
          @k_numerico   varchar(7)  = 'numeric',
          @k_varchar    varchar(7)  = 'varchar',
          @k_entero     varchar(3)  = 'int',
          @k_fecha      varchar(4)  = 'date',
		  @k_fecha_h    varchar(8)  = 'datetime',
		  @k_decimal    varchar(7)  = 'decimal',
		  @k_bit        varchar(3)  = 'bit'

  DECLARE @k_primaria varchar(2)  =  'PK',
          @k_unique   varchar(2)  =  'UQ',
		  @k_foranea  varchar(2)  =  'FK',
          @k_alta     varchar(1)  =  'A',
		  @k_modifica varchar(1)  =  'M',
		  @k_baja     varchar(1)  =  'D',
		  @k_tabla    varchar(5)  =  'T'

  DECLARE @sangria0     int  =  0,
          @sangria1     int  =  2,
          @sangria2     int  =  4,
          @sangria3     int  =  6,
          @sangria4     int  =  8,
		  @sangriav     int 

  DECLARE @nom_tabla      varchar(30),
          @nom_tabla_ref  varchar(30),
		  @nom_campo      varchar(30),
		  @nom_campo_ref  varchar(30),
		  @tipo_llave     varchar(2),
		  @nom_constraint varchar(100)

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
         c.NOM_CONSTRAINT  =  cc.NOM_CONSTRAINT  ORDER BY TIPO_LLAVE DESC

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  
  SET @RowCount     = 1

  SET @nom_const_ant = ' '
  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SET  @b_perm_null  =  @k_falso
    SELECT @nom_tabla = NOM_TABLA, @nom_tabla_ref  = NOM_TABLA_REF,
	       @nom_campo =  NOM_CAMPO, @nom_campo_ref = NOM_CAMPO_REF, 
		   @tipo_llave = TIPO_LLAVE, @nom_constraint = NOM_CONSTRAINT
	FROM  @TTablaRef  
	WHERE RowID  =  @RowCount 

    IF  @tipo_llave IN (@k_primaria,@k_unique) 
    BEGIN
	  SET  @nom_tabla_sel = @nom_tabla
      SET  @nom_campo_w   = @nom_campo 
      SET  @remplazo = @nom_tabla_sel 
      IF  @nom_constraint <> @nom_const_ant
	  BEGIN
        SET @nom_const_ant = @nom_constraint
		SET @num_error     = 19
        SET @cadena_script =  'IF EXISTS(SELECT 1 FROM ' + @nom_tabla_sel + ' WHERE '
        EXEC spInsertaScript @cadena_script, @sangria1
      END
    END
    ELSE
    BEGIN
      IF  @tipo_llave IN (@k_foranea) 
	  BEGIN
        SET @cadena_script = ' '
        IF  EXISTS (SELECT 1 FROM FC_CONSTR_CAMPO cc, FC_TABLA_COLUMNA tc
            WHERE  cc.NOM_TABLA       =  @pTabla  AND
            cc.NOM_CONSTRAINT  =  @pNomConstraint AND
		    cc.NOM_TABLA       =  tc.NOM_TABLA  AND
		    cc.NOM_CAMPO       =  tc.NOM_CAMPO AND
		    tc.B_NULO          =  @k_verdadero)
        BEGIN
          SET  @b_perm_null  =  @k_verdadero
          IF  @nom_constraint <> @nom_const_ant
	      BEGIN
            SET @cadena_script = ' '
			EXEC spInsertaScript @cadena_script, @sangria0
            SET @cadena_script = '-- Validación Referencia (FK) de '  + @nom_tabla + ' a ' +
	        @nom_tabla_ref
			EXEC spInsertaScript @cadena_script, @sangria0
    	    SET @cadena_script = '  '
            EXEC spInsertaScript @cadena_script, @sangria0
            SET @cadena_script = '-- Validación Referencia'
		    EXEC spArmaValNull  @pTabla, @pNomConstraint
		  END
		END
 
        SET  @nom_tabla_sel =   @nom_tabla_ref
	    SET  @nom_campo_w   =   @nom_campo_ref
        IF  @nom_constraint <> @nom_const_ant
	    BEGIN
          IF  @cadena_script NOT LIKE '%-- Validación Referencia%'
		  BEGIN
            EXEC spInsBlanco 
		    SET @cadena_script = '-- Validación Referencia (FK) de '  + @nom_tabla + ' a ' +
	        @nom_tabla_ref
			EXEC spInsertaScript @cadena_script, @sangria0
            EXEC spInsBlanco
		  END
          SET @nom_const_ant = @nom_constraint
          SET @cadena_script  =  'IF NOT EXISTS(SELECT 1 FROM ' + @nom_tabla_sel + ' WHERE '
          SET @num_error = 21
          SET  @remplazo      = @nom_tabla_sel 
          IF  @b_perm_null  =  @k_verdadero
		  BEGIN
            EXEC spInsertaScript @cadena_script, @sangria2
          END
          ELSE
		  BEGIN
            EXEC spInsertaScript @cadena_script, @sangria1
          END

		END
      END
    END

    SET @incremento  = 0
	SET @incremento2 = 0

	IF  @b_perm_null  =  @k_verdadero
    BEGIN
      SET @incremento = 2
    END

	IF  @tipo_llave  =  @k_foranea
	BEGIN
      SET @incremento2 = 2
	END

    SET  @cadena_script = @nom_campo_w + REPLICATE(' ', (25 - LEN(@nom_campo_w))) + '=  '  +  
	'@' + LOWER(@nom_campo)

	IF  @RowCount < @NunRegistros
	BEGIN
	  SET  @cadena_script =  @cadena_script + '  AND'
	END
	ELSE
	BEGIN
	  SET  @cadena_script =  @cadena_script + ')'
	END

    SET  @sangriav  =  @sangria1 + @incremento
	EXEC spInsertaScript @cadena_script, @sangriav

    SET @RowCount     =  @RowCount + 1
  END

  SET  @cadena_script  =  'BEGIN'

  SET  @sangriav  =  @sangria1 + @incremento 
  EXEC spInsertaScript @cadena_script, @sangriav

  IF  @tipo_llave  =  @k_foranea
  BEGIN
    SET  @cadena_script = 'SET @num_foraneas  =  @num_foraneas - 1'
	SET  @sangriav  =  @sangria1 + @incremento + @incremento2
    EXEC spInsertaScript @cadena_script, @sangriav
    SET  @cadena_script = 'IF  @pTipoMovto  IN (@k_alta, @k_modificacion)'
    EXEC spInsertaScript @cadena_script, @sangriav
    SET  @cadena_script = 'BEGIN'
    EXEC spInsertaScript @cadena_script, @sangriav
  END

  IF  @tipo_llave  =  @k_primaria
  BEGIN
    SET  @cadena_script =  'IF  @pTipoMovto  =  @k_alta'
    EXEC spInsertaScript @cadena_script, @sangria2
	SET  @cadena_script =  'BEGIN'
    EXEC spInsertaScript @cadena_script, @sangria2
	SET @incremento = 2
  END
    
  SET  @cadena_script =  'SET  @nom_tabla = ' + CHAR(39) + @remplazo + CHAR(39)

  SET  @sangriav  =  @sangria2 + @incremento + @incremento2
  EXEC spInsertaScript @cadena_script, @sangriav

--  SET  @cadena_script =
--  'SET  @remplazo = (SELECT NOM_TAB_SIST FROM FC_NOMBRE_SIST WHERE NOM_TABLA = @nom_tabla AND CVE_IDIOMA = @idioma)'
--  EXEC spInsertaScript @cadena_script, @sangriav

  SET  @cadena_script  = 'INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(' + '@pBaseDatos,' +
  CONVERT(VARCHAR(4),@num_error) + ',' + '@idioma, @k_forma, @nom_tabla,' + 
  CHAR(39) + 'nom_tabla' + CHAR(39) + ', @k_no_dato))'

  SET  @sangriav  =  @sangria2 + @incremento + @incremento2
  EXEC spInsertaScript @cadena_script, @sangriav
  SET  @cadena_script  =  'END'
  SET  @sangriav  =  @sangria1 + @incremento + @incremento2
  EXEC spInsertaScript @cadena_script, @sangriav

  IF  @tipo_llave  =  @k_primaria
  BEGIN
	SET @num_error = 20
    SET  @cadena_script =  'END'
    EXEC spInsertaScript @cadena_script, @sangria1
	SET  @cadena_script =  'ELSE'
    EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script =  'BEGIN'
    EXEC spInsertaScript @cadena_script, @sangria1
	SET  @cadena_script = 'IF  @pTipoMovto  IN (@k_modificacion)'
    EXEC spInsertaScript @cadena_script, @sangria2
    SET  @cadena_script =  'BEGIN'
    EXEC spInsertaScript @cadena_script, @sangria2
    SET  @cadena_script =  'SET  @nom_tabla = ' + CHAR(39) + @nom_tabla_sel + CHAR(39)
	EXEC spInsertaScript @cadena_script, @sangria3
    SET  @cadena_script  = 'INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(' + '@pBaseDatos,' +
    CONVERT(VARCHAR(4),@num_error) + ',' + '@idioma, @k_tabla, @nom_tabla,' + 
	CHAR(39) + 'nom_tabla' + CHAR(39) + ', @k_no_dato))'
	EXEC spInsertaScript @cadena_script, @sangria3
    SET  @cadena_script =  'END'
    EXEC spInsertaScript @cadena_script, @sangria2
	SET  @cadena_script =  'END'
    EXEC spInsertaScript @cadena_script, @sangria1
 
  END

  IF  @tipo_llave  =  @k_foranea
  BEGIN
    SET  @cadena_script = 'END'
    SET  @sangriav  =  @sangria1 + @incremento
    EXEC spInsertaScript @cadena_script, @sangriav
  END
  
  IF  @b_perm_null  =  @k_verdadero
  BEGIN
	SET  @cadena_script  =  'END'
	EXEC spInsertaScript @cadena_script, @sangria1
  END

END






