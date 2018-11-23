USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC spCreaScriptMB
ALTER PROCEDURE  [dbo].[spCreaScriptMB]  
AS
BEGIN

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END
  BEGIN
    DELETE FROM #LINEAMODEL
  END

  DECLARE @pnom_contexto varchar(100)

  SET @pnom_contexto = 'ContextoPrueba'

  DECLARE @sangria0     int,
          @sangria1     int,
          @sangria2     int,
          @sangria3     int,
          @sangria4     int,
          @b_declara    bit

  DECLARE @k_verdadero  bit,
          @k_falso      bit,
          @k_numerico   varchar(7),
          @k_varchar    varchar(7),
          @k_entero     varchar(2),
          @k_fecha      varchar(4)

  DECLARE @nom_tabla     varchar(30),
          @sinonimo      varchar(6),
          @sinonimo_ref  varchar(4),
          @cadena_script varchar(500),
		  @campos_llave  varchar(200)

-- Cursor Tabla Columna

  DECLARE  @nom_tabla_c   varchar(30),
           @nom_campo     varchar(30),
           @tipo_campo    varchar(20),
           @longitud      int,
           @enteros       int,
           @decimales     int,
           @posicion      int,
           @b_nulo        bit,
		   @b_identity    bit

-- Creación de DATA SETS

  SET @k_verdadero = 1
  SET @k_falso     = 0

  SET @k_numerico  =  'numeric'
  SET @k_varchar   =  'varchar'
  SET @k_entero    =  'int'
  SET @k_fecha     =  'date'


  SET @sangria0  =  0
  SET @sangria1  =  4
  SET @sangria2  =  8
  SET @sangria3  =  12
  SET @sangria4  =  24

  
  SET @cadena_script = 'using System;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Collections.Generic;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Linq;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Text;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Threading.Tasks;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Data.Entity;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Data.Entity.Infrastructure;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.Data.Entity.Core.Objects;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'using System.ComponentModel.DataAnnotations.Schema;'
  EXEC spInsertaScript @cadena_script, @sangria0
  
  SET @cadena_script = 'using ModAdmon01;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = '// Definición de namespace que tendrá el CONTEXTO'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ('namespace EF_Contextos')
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = '{'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '// Definición de la clase que heredará de DbContext'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'public class ' + @pnom_contexto + ': DbContext'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script = '{'
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '// Definición de Propiedades de la Clase de tipo DbSET<Entity>'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '// Se incluye el prefijo _s en las propiedades para indicar el conjunto (plural) '
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

-- A DbSet represents the collection of all entities in the context, or that can be queried from the database, of a given type.
-- DbSet objects are created from a DbContext using the DbContext.Set method.

  INSERT INTO #LINEAMODEL 
  SELECT 
  REPLICATE(' ', @sangria2) + 'public DbSet<' + dbo.fnConvierteCamello(tb.NOM_TABLA) +
  '>' + ' ' + dbo.fnConvierteCamello(tb.NOM_TABLA) + '_s ' + '{ get; set; }'
  FROM FC_TABLA tb  WHERE NOM_TABLA  NOT IN ('Sysdiagrams')
  -- AND NOM_TABLA = 'CI_ITEM_C_X_C'
  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '// Definición de metodo OnModelCreating en donde se ejectutaran los diferentes métodos'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '// que configuran las entidades. Pasa como argumento un objeto del tipo DbModelBuilder'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'protected override void OnModelCreating(DbModelBuilder ModelBuilder)'
  EXEC spInsertaScript @cadena_script, @sangria2

  SET @cadena_script = '{'
  EXEC spInsertaScript @cadena_script, @sangria2

  INSERT INTO #LINEAMODEL 
  SELECT REPLICATE(' ', @sangria3) + 'Configurar_' + LTRIM(dbo.fnConvierteCamello(tb.NOM_TABLA)) + ' ' +
  '(ModelBuilder);' 
  FROM FC_TABLA tb WHERE NOM_TABLA  NOT IN ('Sysdiagrams') -- WHERE NOM_TABLA IN ('CI_FACTURA', 'CI_CHEQUERA', 'CI_EMPRESA', 'CI_VENTA_FACTURA', 'CI_BANCO', 'CI_VENTA', 'CI_CLIENTE','CI_TRASP_BANCARIO', 'CI_ITEM_C_X_C')
  -- AND NOM_TABLA = 'CI_CONCILIA_C_X_C'
  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria3

  SET @cadena_script = 'base.OnModelCreating(ModelBuilder);'
  EXEC spInsertaScript @cadena_script, @sangria3

  SET @cadena_script = '}'
  EXEC spInsertaScript @cadena_script, @sangria2


  DECLARE cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA WHERE NOM_TABLA  NOT IN ('Sysdiagrams')-- WHERE NOM_TABLA IN ('CI_FACTURA', 'CI_CHEQUERA', 'CI_EMPRESA', 'CI_VENTA_FACTURA', 'CI_BANCO', 'CI_VENTA', 'CI_CLIENTE','CI_TRASP_BANCARIO', 'CI_ITEM_C_X_C')
  -- AND NOM_TABLA = 'CI_CONCILIA_C_X_C'
  OPEN  cur_tabla

  FETCH cur_tabla INTO  @nom_tabla

  SET @b_declara  =  @k_verdadero

  WHILE (@@fetch_status = 0 )
  BEGIN

    SET @cadena_script = ' '
    EXEC spInsertaScript @cadena_script, @sangria0
    SET @cadena_script = '// Configuración de la tabla ' + @nom_tabla
    EXEC spInsertaScript @cadena_script, @sangria0
    SET @cadena_script = ' '
    EXEC spInsertaScript @cadena_script, @sangria0

 --   IF  @b_declara  =  @k_verdadero
 --   BEGIN 
      SET @cadena_script = 'private void Configurar_' + dbo.fnConvierteCamello(@nom_tabla) + '(DbModelBuilder ModelBuilder)'
      EXEC spInsertaScript @cadena_script, @sangria2
--      SET @b_declara  =  @k_falso
--    END
   
    SET @cadena_script = '{'
    EXEC spInsertaScript @cadena_script, @sangria2

    SELECT @sinonimo  =  (SELECT SINONIMO FROM FC_TABLA_EX WHERE NOM_TABLA = @nom_tabla) 

    SET @cadena_script = 'ModelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
    EXEC spInsertaScript @cadena_script, @sangria3

    SET @cadena_script = '.ToTable("' + @nom_tabla + '");'
    EXEC spInsertaScript @cadena_script, @sangria4
                      
    DECLARE cur_tabla_columna cursor for SELECT 
    NOM_TABLA,
    NOM_CAMPO,
    TIPO_CAMPO,
    LONGITUD,
    ENTEROS,
    DECIMALES,
    POSICION,
    B_NULO,
	B_IDENTITY
    FROM FC_TABLA_COLUMNA WHERE
    NOM_TABLA = @NOM_TABLA
  
    OPEN  cur_tabla_columna

    FETCH cur_tabla_columna INTO
    @nom_tabla_c,
    @nom_campo,
    @tipo_campo,
    @longitud,
    @enteros,
    @decimales,
    @posicion,
    @b_nulo,
	@b_identity
	

    WHILE (@@fetch_status = 0 )
    BEGIN
      SET @cadena_script = 'ModelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
      EXEC spInsertaScript @cadena_script, @sangria3
 
-- .HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity)
      SET @cadena_script = '.Property' + '(' + @sinonimo + ' => ' +  @sinonimo + '.' + dbo.fnConvierteCamello(@nom_campo) + ')'
      EXEC spInsertaScript @cadena_script, @sangria4

	  IF  @b_identity  =  @k_verdadero
	  BEGIN
	    SET @cadena_script = '.HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity)'
        EXEC spInsertaScript @cadena_script, @sangria4
	  END

      SET @cadena_script = '.HasColumnName("' + @nom_campo + '")'
      EXEC spInsertaScript @cadena_script, @sangria4

      SET @cadena_script = '.HasColumnType(' + '"' + @tipo_campo + '"' + ')'
      EXEC spInsertaScript @cadena_script, @sangria4

      IF  @tipo_campo  =  @k_numerico 
      BEGIN
        SET @cadena_script = '.HasPrecision(' + CONVERT(varchar(2), @enteros) + ',' + CONVERT(varchar(2), @decimales) + ')'
        EXEC spInsertaScript @cadena_script, @sangria4
      END

      IF  @tipo_campo  =  @k_varchar
      BEGIN
        SET @cadena_script = '.HasMaxLength(' + CONVERT(varchar(3), @longitud) + ')'
        EXEC spInsertaScript @cadena_script, @sangria4
        SET @cadena_script = '.IsUnicode(false)'
        EXEC spInsertaScript @cadena_script, @sangria4
      END

      IF  @b_nulo  =  @k_falso
      BEGIN
        SET @cadena_script = '.IsRequired();'
        EXEC spInsertaScript @cadena_script, @sangria4
      END
      ELSE
      BEGIN
        SET @cadena_script = '.IsOptional();'
        EXEC spInsertaScript @cadena_script, @sangria4
      END

      FETCH cur_tabla_columna INTO
            @nom_tabla_c,
            @nom_campo,
            @tipo_campo,
            @longitud,
            @enteros,
            @decimales,
            @posicion,
            @b_nulo,
			@b_identity
    END

    CLOSE cur_tabla_columna 
    DEALLOCATE cur_tabla_columna

    SET @cadena_script = ' '
    EXEC spInsertaScript @cadena_script, @sangria3

    SET @cadena_script = 'ModelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
    EXEC spInsertaScript @cadena_script, @sangria3

   
    SET @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'PK'))
    IF  @campos_llave NOT LIKE '%new%'
	BEGIN
	  SET @campos_llave = @sinonimo + ' => ' + @campos_llave 
	END

    SET @cadena_script = '.HasKey(' + @campos_llave + ');'
    EXEC spInsertaScript @cadena_script, @sangria4

    SET @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'UQ'))
    IF  @campos_llave  <> ' ' 
    BEGIN
      SET @cadena_script = 'ModelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
      EXEC spInsertaScript @cadena_script, @sangria3
      SET @cadena_script = '.HasIndex(' + @sinonimo + ' => ' + @campos_llave + ')' + '.IsUnique();'
      EXEC spInsertaScript @cadena_script, @sangria4
    END

    SET @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'IX'))
    IF  @campos_llave  <> ' ' 
    BEGIN
      SET @cadena_script = 'ModelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
      EXEC spInsertaScript @cadena_script, @sangria3
      SET @cadena_script = '.HasIndex(' + @campos_llave + ');'
      EXEC spInsertaScript @cadena_script, @sangria4
    END
    
    SET @cadena_script = ' '
    EXEC spInsertaScript @cadena_script, @sangria3

-- Crear llaves Foraneas

    EXEC spModelaFK @nom_tabla

    SET @cadena_script = '}'
    EXEC spInsertaScript @cadena_script, @sangria2


    FETCH cur_tabla INTO  @nom_tabla

  END

  CLOSE cur_tabla 
  DEALLOCATE cur_tabla 

  SET @cadena_script = '}'
  EXEC spInsertaScript @cadena_script, @sangria0

  SELECT * FROM #LINEAMODEL
END