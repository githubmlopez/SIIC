USE [DICCIONARIO]
GO
/****** Object:  StoredProcedure [dbo].[spCreaScriptValida]    Script Date: 20/08/2018 01:17:06 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spCreaScriptValidaNeg 'ADMON01','CI_MOVTO_BANCARIO', 'P'

ALTER PROCEDURE  [dbo].[spCreaScriptValidaNeg] @pBaseDatos varchar(10), @pTabla varchar(30), @pOpcion varchar(1)
                                            
AS
BEGIN
  DECLARE  @NumRegistros      int, 
           @RowCount          int,
		   @var_nom_campo     varchar(20),
		   @cve_etiqueta      varchar(20),
		   @etiqueta          varchar(50),
		   @num_foraneas      int,
		   @b_existe_file     int,
		   @path              varchar(200),
		   @sql               varchar(200),
		   @k_parcial         varchar(1) = 'P'        

  IF object_id('tempdb..#LINEAMODEL') IS NOT NULL 
  BEGIN
    DELETE #LINEAMODEL
  END

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END

  DECLARE @TTablaCampo AS TABLE
 (RowId                int  IDENTITY(1,1),
  NOM_TABLA            varchar(30),          
  NOM_CAMPO            varchar(30),          
  TIPO_CAMPO           varchar(20),          
  LONGITUD             int,                  
  ENTEROS              int,                  
  DECIMALES            int,                  
  POSICION             int,                  
  B_NULO               bit,                  
  B_IDENTITY           bit,
  DESC_CAMPO           varchar(200))

  DECLARE 
  @nom_tabla           varchar(30),          
  @nom_campo           varchar(30),          
  @tipo_campo          varchar(20),          
  @longitud            int,                  
  @enteros             int,                  
  @decimales           int,                  
  @posicion            int,                  
  @b_nulo              bit,                  
  @b_identity          bit,
  @desc_campo          varchar(200)

  DECLARE
  @nom_constraint      varchar(100),
  @tipo_llave          varchar(2),
  @cve_catalogo        varchar(30),
  @remplazo            varchar(80),
  @b_enca_foranea      bit

  DECLARE @sangria0     int  =  0,
          @sangria1     int  =  2,
          @sangria2     int  =  4,
          @sangria3     int  =  6,
          @sangria4     int  =  8

  DECLARE @k_verdadero  bit         = 1,
          @k_falso      bit         = 0,
          @k_numerico   varchar(7)  = 'numeric',
          @k_varchar    varchar(7)  = 'varchar',
		  @k_nvarchar   varchar(8)  = 'nvarchar',
          @k_entero     varchar(3)  = 'int',
          @k_fecha      varchar(4)  = 'date',
		  @k_fecha_h    varchar(8)  = 'datetime',
		  @k_decimal    varchar(7)  = 'decimal',
		  @k_bit        varchar(3)  = 'bit',
		  @k_alta       varchar(1)  = 'A',
		  @k_primary    varchar(2)  = 'PK',
		  @k_foreing    varchar(2)  = 'FK',
		  @k_unique     varchar(2)  = 'UQ',
		  @k_combo      varchar(5)  = 'COMBO',
		  @k_cve_catal  varchar(11) = 'cveCatalogo',
		  @k_forma      varchar(1)  = 'F'

  DECLARE @cadena_script varchar(500)

  SET  @path = CHAR(39) + 'C:\' + @pBaseDatos + '\' + LOWER(@pTabla) + '\' + 
               'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_INT' + '.sql' + CHAR(39)

  SET @cadena_script = LTRIM('USE [' + @pBaseDatos + ']')
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'SET ANSI_NULLS ON'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'SET NOCOUNT ON'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'IF EXISTS (SELECT ' + CHAR(39) + '-- ' + CHAR(39) +  'FROM ' + 
  REPLACE(@pBaseDatos + '.sys.procedures',' ','') + ' WHERE Name = ' + CHAR(39) +
  'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_NEG ' + CHAR(39) + ')'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'DROP PROCEDURE ' + 'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_NEG ' 
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script = 'END'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  EXEC spInsBlanco 

  SET @cadena_script = 'CREATE PROCEDURE [dbo].[spValOB_' +
  LTRIM(SUBSTRING(@pTabla,4,26)) + '_NEG' + '] ' +
  '@pBaseDatos varchar(20), ' +
  '@pTipoMovto varchar(1), ' +
  '@pTVP' + ' ' +
  'OB_' + @pTabla + ' READONLY, ' +
  '@pIdioma varchar(5)'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'AS'
  EXEC spInsertaScript @cadena_script, @sangria0
  
  SET @cadena_script = 'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria0

  EXEC spInsBlanco 

  SET @cadena_script = 'DECLARE '
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@cve_cat_key' + REPLICATE(' ', (30 - LEN('cve_cat_key'))) + 'varchar(10),'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@cve_etiqueta' + REPLICATE(' ', (30 - LEN('cve_etiqueta'))) + 'varchar(20),'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@etiqueta' + REPLICATE(' ', (30 - LEN('etiqueta'))) + 'varchar(50),'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@idioma' + REPLICATE(' ', (30 - LEN('idioma'))) + 'varchar(5)  =  ' + '@pIdioma,' 
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@b_existe_ref' + REPLICATE(' ', (30 - LEN('b_existe_ref'))) + 'bit' + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@num_foraneas' + REPLICATE(' ', (30 - LEN('num_foraneas'))) + 'int = 0,'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@nom_tabla' + REPLICATE(' ', (30 - LEN('nom_tabla'))) + 'varchar(30),'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@cve_tipo_entidad' + REPLICATE(' ', (30 - LEN('cve_tipo_entidad'))) + 'varchar(5)'
  EXEC spInsertaScript @cadena_script, @sangria1

  EXEC spInsBlanco

  SET @cadena_script = 'DECLARE '
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_alta' + REPLICATE(' ', (30 - LEN('k_alta'))) + 'varchar(1)  =  ' + CHAR(39) + 'C' + CHAR(39) + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_modificacion' + REPLICATE(' ', (30 - LEN('k_modificacion'))) + 'varchar(1)  =  ' + CHAR(39) + 'U' + CHAR(39) + ','
  EXEC spInsertaScript @cadena_script, @sangria1

   SET @cadena_script =
  '@k_baja' + REPLICATE(' ', (30 - LEN('k_baja'))) + 'varchar(1)  =  ' + CHAR(39) + 'D' + CHAR(39) + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_falso' + REPLICATE(' ', (30 - LEN('k_falso'))) + 'bit  =  ' + '0' + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_verdadero' + REPLICATE(' ', (30 - LEN('k_verdadero'))) + 'bit  =  ' + '1,' 
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_tabla' + REPLICATE(' ', (30 - LEN('k_tabla'))) + 'varchar(5)  =  ' + CHAR(39) + 'T' + CHAR(39) + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_forma' + REPLICATE(' ', (30 - LEN('k_forma'))) + 'varchar(5)  =  ' + CHAR(39) + 'F' + CHAR(39) + ','
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script =
  '@k_no_dato' + REPLICATE(' ', (30 - LEN('k_no_dato'))) + 'varchar(1)  =  ' +  CHAR(39) + ' ' + CHAR(39)
  EXEC spInsertaScript @cadena_script, @sangria1

  EXEC spInsBlanco 

  SET @cadena_script =
  'IF object_id(' + CHAR(39) + 'tempdb..#TError' + CHAR(39) +') IS  NULL' 
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script =
  'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script =
  'CREATE TABLE #TError (DESC_ERROR varchar(80))'
  EXEC spInsertaScript @cadena_script, @sangria2
  SET @cadena_script =
  'END'
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script =
  'ELSE'
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script =
  'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script =
  'DELETE #TError'
  EXEC spInsertaScript @cadena_script, @sangria2
  SET @cadena_script =
  'END'
  EXEC spInsertaScript @cadena_script, @sangria1

  --SET @cadena_script = 'DECLARE '
  --EXEC spInsertaScript @cadena_script, @sangria1

  --SET @cadena_script = '#TError TABLE(DESC_ERROR varchar(80))'
  --EXEC spInsertaScript @cadena_script, @sangria1

  EXEC spInsBlanco

  SET @cadena_script = 'DECLARE '
  EXEC spInsertaScript @cadena_script, @sangria1

  --SET @cadena_script =
  --'@' + LOWER(@nom_campo) + REPLICATE(' ', (25 - LEN(@nom_campo))) 

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTablaCampo  (NOM_TABLA, NOM_CAMPO, TIPO_CAMPO, LONGITUD, ENTEROS, DECIMALES,                  
                        POSICION, B_NULO, B_IDENTITY, DESC_CAMPO)
  
  SELECT tc.NOM_TABLA, tc.NOM_CAMPO, tc.TIPO_CAMPO, tc.LONGITUD, tc.ENTEROS, tc.DECIMALES,
         tc.POSICION, tc.B_NULO, tc.B_IDENTITY, ' '                  
         FROM FC_TABLA_COLUMNA tc
         WHERE  tc.NOM_TABLA  =  @pTabla     

  SET @NumRegistros = @@ROWCOUNT

-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT 
    @nom_tabla    =  tc.NOM_TABLA,         
    @nom_campo    =  tc.NOM_CAMPO,          
    @tipo_campo   =  tc.TIPO_CAMPO,          
    @longitud     =  tc.LONGITUD,                  
    @enteros      =  tc.ENTEROS,              
    @decimales    =  tc.DECIMALES,               
    @posicion     =  tc.POSICION,             
    @b_nulo       =  tc.B_NULO,              
    @b_identity   =  tc.B_IDENTITY,
    @desc_campo   =  tc.DESC_CAMPO
	FROM   @TTablaCampo tc
	WHERE  RowID  =  @RowCount

	SET @cadena_script =
	'@' + LOWER(@nom_campo) + REPLICATE(' ', (30 - LEN(@nom_campo))) 

	IF  @tipo_campo in (@k_entero, @k_bit, @k_fecha, @k_fecha_h)
	BEGIN
      SET  @cadena_script =  @cadena_script +
	  LTRIM(@tipo_campo) 
	END
	ELSE
	BEGIN
	  IF  @tipo_campo IN (@k_numerico, @k_decimal)
	  BEGIN
        SET  @cadena_script =  @cadena_script +
	    LTRIM(@tipo_campo) + '(' + LTRIM(@enteros) + ',' +  LTRIM(@decimales) +
		')' 
	  END
      ELSE
	  BEGIN
    	IF  @tipo_campo IN (@k_varchar, @k_nvarchar)
	    BEGIN
          IF  @longitud > 0
		  BEGIN
            SET  @cadena_script =  @cadena_script +
            LTRIM(@tipo_campo) + '(' + LTRIM(@longitud) + ')' 
		  END
          ELSE
		  BEGIN
            SET  @cadena_script =  @cadena_script +
	        LTRIM(@tipo_campo) + '(' + 'MAX' + ')' 
		  END
 		END
        ELSE
		BEGIN
          SET  @cadena_script =  @cadena_script + ' NO IDENTIFICADO'
		END
	  END
	END
    IF  @RowCount < @NumRegistros
	BEGIN
	  SET  @cadena_script =  @cadena_script + ','
	END

    EXEC spInsertaScript @cadena_script, @sangria1
    SET @RowCount =  @RowCount + 1

  END

  EXEC spInsBlanco

  SET @cadena_script =  'SELECT  TOP(1)' 
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @RowCount     = 1
 
  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT 
    @nom_tabla    =  tc.NOM_TABLA,         
    @nom_campo    =  tc.NOM_CAMPO,          
    @tipo_campo   =  tc.TIPO_CAMPO,          
    @longitud     =  tc.LONGITUD,                  
    @enteros      =  tc.ENTEROS,              
    @decimales    =  tc.DECIMALES,               
    @posicion     =  tc.POSICION,             
    @b_nulo       =  tc.B_NULO,              
    @b_identity   =  tc.B_IDENTITY,
    @desc_campo   =  tc.DESC_CAMPO
	FROM   @TTablaCampo tc
	WHERE  RowID  =  @RowCount

	SET @cadena_script =
	'@' + LOWER(@nom_campo) + REPLICATE(' ', (30 - LEN(@nom_campo))) +
	' = ' + @nom_campo

    IF  @RowCount < @NumRegistros
	BEGIN
	  SET  @cadena_script =  @cadena_script + ','
	END

	EXEC spInsertaScript @cadena_script, @sangria1
    SET @RowCount =  @RowCount + 1

  END

--  SET @cadena_script =  'FROM  ' + '@p' + LTRIM(SUBSTRING(@pTabla,4,26))
  SET @cadena_script =  'FROM  ' + '@pTVP' 

  EXEC spInsertaScript @cadena_script, @sangria1

  EXEC spInsBlanco
  EXEC spInsBlanco
--
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT 
    @nom_tabla    =  tc.NOM_TABLA,         
    @nom_campo    =  tc.NOM_CAMPO,          
    @tipo_campo   =  tc.TIPO_CAMPO,          
    @longitud     =  tc.LONGITUD,                  
    @enteros      =  tc.ENTEROS,              
    @decimales    =  tc.DECIMALES,               
    @posicion     =  tc.POSICION,             
    @b_nulo       =  tc.B_NULO,              
    @b_identity   =  tc.B_IDENTITY,
    @desc_campo   =  tc.DESC_CAMPO
	FROM   @TTablaCampo tc
	WHERE  RowID  =  @RowCount

    SET  @cadena_script  =  'IF  '  + @nom_campo + ' AND @pTipoMovto IN (@k_alta, @k_modificacion)' 
	EXEC spInsertaScript @cadena_script, @sangria1

    SET  @cadena_script  =  'BEGIN'
	EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script  =  '  -- CODIGO DE VALIDACION'
	EXEC spInsertaScript @cadena_script, @sangria2
    SET  @cadena_script  =  'END'
	EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script  =  'ELSE'
	EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script  =  'BEGIN'
	EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script  =  '  -- CODIGO DE VALIDACION'
	EXEC spInsertaScript @cadena_script, @sangria2
    SET  @cadena_script  =  'END'
	EXEC spInsertaScript @cadena_script, @sangria1

    SET @RowCount =  @RowCount + 1

  END

  SET @cadena_script = 'END'
  EXEC spInsertaScript @cadena_script, @sangria0

  SELECT * FROM #LINEAMODEL
END

