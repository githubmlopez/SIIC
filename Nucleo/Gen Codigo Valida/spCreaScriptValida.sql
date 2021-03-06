USE [DICCIONARIO]
GO
/****** Object:  StoredProcedure [dbo].[spCreaScriptValida]    Script Date: 20/08/2018 01:17:06 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spCreaScriptValida 'ADMON01','CI_MOVTO_BANCARIO', 'P'

ALTER PROCEDURE  [dbo].[spCreaScriptValida] @pBaseDatos varchar(10), @pTabla varchar(30), @pOpcion varchar(1)
                                            
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
    IF  @pOpcion = @k_parcial
    BEGIN
	  DELETE #LINEAMODEL
    END
  END

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END

  IF object_id('tempdb..#EXISTESTORE') IS NOT NULL 
  BEGIN
    DELETE #EXISTESTORE
  END

  IF object_id('tempdb..#EXISTESTORE') IS  NULL 
  BEGIN
    CREATE TABLE #EXISTESTORE (LINEA varchar(200))
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
  'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_INT ' + CHAR(39) + ')'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'DROP PROCEDURE ' + 'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_INT ' 
  EXEC spInsertaScript @cadena_script, @sangria1
  SET @cadena_script = 'END'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  EXEC spInsBlanco 

  SET @cadena_script = 'CREATE PROCEDURE [dbo].[spValOB_' +
  LTRIM(SUBSTRING(@pTabla,4,26)) + '_INT' + '] ' +
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

  DECLARE @TConstraint TABLE
 (RowId                int  IDENTITY(1,1),
  NOM_TABLA            varchar(30),          
  NOM_CONSTRAINT       varchar(100),
  TIPO_LLAVE           varchar(2))          

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TConstraint  (NOM_TABLA, NOM_CONSTRAINT,TIPO_LLAVE)
  
  SELECT NOM_TABLA, NOM_CONSTRAINT, TIPO_LLAVE
         FROM FC_CONSTRAINT c
         WHERE  c.NOM_TABLA   =  @pTabla  ORDER BY TIPO_LLAVE DESC

  SET @NumRegistros = @@ROWCOUNT

-----------------------------------------------------------------------------------------------------
  SET @b_enca_foranea  =  @k_falso
  SET @RowCount     = 1
 
  SET @num_foraneas = (SELECT COUNT(*) FROM FC_CONSTRAINT c
                       WHERE  c.NOM_TABLA   =  @pTabla  AND TIPO_LLAVE = @k_foreing)

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA, @nom_constraint = NOM_CONSTRAINT, @tipo_llave = TIPO_LLAVE FROM @TConstraint
	WHERE  RowId = @RowCount

    IF  @tipo_llave  in  (@k_unique, @k_primary)
	BEGIN
      SET @cadena_script = '--------------------------------------------------------------------------'
      EXEC spInsertaScript @cadena_script, @sangria0
      IF  @tipo_llave  in  (@k_unique)
	  BEGIN 
        SET @cadena_script = '--  Validación de Llave Unica (UQ)                                       --'
        EXEC spInsertaScript @cadena_script, @sangria0
        SET @cadena_script = '--------------------------------------------------------------------------'
        EXEC spInsertaScript @cadena_script, @sangria0
        SET @cadena_script = 'IF  @pTipoMovto  in  (@k_Alta)'
        EXEC spInsertaScript @cadena_script, @sangria1
        SET @cadena_script = 'BEGIN'
        EXEC spInsertaScript @cadena_script, @sangria1
      END
      ELSE
	  BEGIN
        SET @cadena_script = '--  Validación de Llave Unica (PK)                                       --'
        EXEC spInsertaScript @cadena_script, @sangria0
        SET @cadena_script = '--------------------------------------------------------------------------'
        EXEC spInsertaScript @cadena_script, @sangria0
	  END

	END
	ELSE
	BEGIN
	  IF  @b_enca_foranea = @k_falso
	  BEGIN
        SET @b_enca_foranea =  @k_verdadero
        EXEC  spInsBlanco
        SET @cadena_script = '--------------------------------------------------------------------------'
        EXEC spInsertaScript @cadena_script, @sangria0
        SET @cadena_script = '--  Validación de Llave Unica Llaves Foraneas                           --'
        EXEC spInsertaScript @cadena_script, @sangria0
        SET @cadena_script = '--------------------------------------------------------------------------'
        EXEC spInsertaScript @cadena_script, @sangria0
        EXEC spInsBlanco
        SET @cadena_script = 'SET  @num_foraneas  =  ' + CONVERT(VARCHAR(2),@num_foraneas)
        EXEC spInsertaScript @cadena_script, @sangria1
      END
	END

    EXEC spValExistencia  @pBaseDatos, @nom_tabla, @nom_constraint, @k_alta

    IF  @tipo_llave  in  (@k_unique)
	BEGIN
      EXEC spInsBlanco
      SET @cadena_script = 'END'
      EXEC spInsertaScript @cadena_script, @sangria1
      EXEC spInsBlanco
	END
    
	SET @RowCount     =  @RowCount + 1
  END

  DECLARE @TTablaCol AS TABLE
 (RowId                int  IDENTITY(1,1),
  NOM_TABLA            varchar(30), 
  NOM_CAMPO            varchar(30),
  CVE_CATALOGO         varchar(10),
  CVE_ETIQUETA         varchar(20),
  ETIQUETA             varchar(30),
  TIPO_CAMPO           varchar(20),
  B_NULO               bit)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTablaCol  (NOM_TABLA, NOM_CAMPO, CVE_CATALOGO, CVE_ETIQUETA, ETIQUETA, TIPO_CAMPO, B_NULO)
  
  SELECT tc.NOM_TABLA, tc.NOM_CAMPO, dbo.fnCveCatalogo(fd.URL_API), fd.CVE_ETIQUETA, fd.TX_ETIQUETA, tc.TIPO_CAMPO,
         tc.B_NULO
  FROM
  FC_TABLA_COLUMNA tc, ADMON01.dbo.INF_FORMA_DET fd
  WHERE  fd.BASE_DATOS          =  SUBSTRING(@pBaseDatos,1,7)    AND
         tc.NOM_TABLA           =  @pTabla                       AND
		 tc.NOM_TABLA           =  fd.CVE_FORMA                  AND
         tc.NOM_CAMPO           =  fd.NOM_CAMPO_DB               AND 
		 fd.CVE_TIPO_COMPONENTE =  @k_combo                      AND
		 fd.URL_API       LIKE  '%' + @k_cve_catal + '%'

  SET @NumRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  IF  @NumRegistros <> 0
  BEGIN 
    EXEC spInsBlanco
    SET @cadena_script = '--------------------------------------------------------------------------'
    EXEC spInsertaScript @cadena_script, @sangria0
    SET @cadena_script = '--  Validación de Campos relacionados a Catálogos                       --'
    EXEC spInsertaScript @cadena_script, @sangria0
    SET @cadena_script = '--------------------------------------------------------------------------'
    EXEC spInsertaScript @cadena_script, @sangria0

    SET @cadena_script = 'IF  @pTipoMovto  in  (@k_Alta, @k_modificacion)'
    EXEC spInsertaScript @cadena_script, @sangria1
    SET @cadena_script = 'BEGIN'
    EXEC spInsertaScript @cadena_script, @sangria1
    EXEC spInsBlanco
  END
 
  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA, @nom_campo = NOM_CAMPO, @cve_catalogo = CVE_CATALOGO, @cve_etiqueta = CVE_ETIQUETA,
	@etiqueta = ETIQUETA, @tipo_campo = TIPO_CAMPO, @b_nulo = B_NULO
	FROM  @TTablaCol 
	WHERE RowID  =  @RowCount  ORDER BY CVE_CATALOGO

    IF  ISNULL(@cve_catalogo,' ') <> ' ' 
	BEGIN		
      EXEC spInsBlanco
      SET @cadena_script = '--  Validación contra catálogo campo ' + @nom_campo
      EXEC spInsertaScript @cadena_script, @sangria0
      EXEC spInsBlanco
      SET  @cadena_script =
      'SET  @cve_cat_key  = ' + CHAR(39) + LTRIM(@cve_catalogo) + CHAR(39) 
      EXEC spInsertaScript @cadena_script, @sangria1

      SET  @cadena_script = 'IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO'
      EXEC spInsertaScript @cadena_script, @sangria1
	  SET  @cadena_script = 'WHERE  BASE_DATOS  = @pBaseDatos AND '
      EXEC spInsertaScript @cadena_script, @sangria1
      SET  @cadena_script = '       CVE_CATALOGO = @cve_cat_key  AND'
      EXEC spInsertaScript @cadena_script, @sangria1
	  SET  @cadena_script = '       CVE_CAMPO    = ' + '@' + LOWER(@nom_campo) + ')'
      EXEC spInsertaScript @cadena_script, @sangria1
      SET  @cadena_script  =  'BEGIN'
      EXEC spInsertaScript @cadena_script, @sangria1

      SET  @cadena_script =  'SET @cve_etiqueta = ' + CHAR(39) + @cve_etiqueta + CHAR(39) 
      EXEC spInsertaScript @cadena_script, @sangria2

      SET  @cadena_script =  'SET @etiqueta = ' + CHAR(39) + @etiqueta + CHAR(39) 
      EXEC spInsertaScript @cadena_script, @sangria2
	  
      SET  @cadena_script  = 'INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(' +
      '@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))'

	  EXEC spInsertaScript @cadena_script, @sangria2

      SET  @cadena_script  =  'END'
      EXEC spInsertaScript @cadena_script, @sangria1
    END

    SET @RowCount     =  @RowCount + 1
  END
  
  IF  @NumRegistros  <>  0
  BEGIN
    EXEC spInsBlanco
    SET  @cadena_script  =  'END '
    EXEC spInsertaScript @cadena_script, @sangria1
  END
    
  EXEC spInsBlanco

  SET  @cadena_script  ='IF  @pTipoMovto  =  @k_baja AND  @num_foraneas <> 0'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET  @cadena_script  ='BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET  @cadena_script  = 'INSERT #TError (DESC_ERROR) VALUES ' +
      '(dbo.fnObtDescError(@pBaseDatos, 23, @idioma, @k_no_dato, @k_no_dato, @k_no_dato, @k_no_dato))'
  EXEC spInsertaScript @cadena_script, @sangria2
  
  SET  @cadena_script  ='END'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET  @sql = 'INSERT INTO #EXISTESTORE ' +
  'SELECT ' + CHAR(39) + '1' + CHAR(39) +  'FROM ' + 
  REPLACE(@pBaseDatos + '.sys.procedures',' ','') + ' WHERE Name = ' + CHAR(39) +
  'spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_NEG ' + CHAR(39) 
  
  EXEC(@sql)

  IF  (SELECT COUNT(*)  FROM #EXISTESTORE) <> 0
  BEGIN
    SET  @cadena_script  ='SET  @nom_tabla  =  '  +  CHAR(39) + @pTabla + CHAR(39)
    EXEC spInsertaScript @cadena_script, @sangria1
    SET  @cadena_script  =  'EXEC spValOB_' +  LTRIM(SUBSTRING(@pTabla,4,26)) + '_Neg ' +
    '@pBaseDatos, @pTipoMovto, @pTVP, @pIdioma' 
    EXEC spInsertaScript @cadena_script, @sangria1
  END

  SET  @cadena_script  =  'SELECT DESC_ERROR FROM #TError'
  EXEC spInsertaScript @cadena_script, @sangria1
  SET  @cadena_script  =  'END'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET  @cadena_script  =  'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  EXEC spInsBlanco
  EXEC spInsBlanco
  
  IF  @pOpcion = @k_parcial
  BEGIN
    SELECT * FROM #LINEAMODEL
  END

END
