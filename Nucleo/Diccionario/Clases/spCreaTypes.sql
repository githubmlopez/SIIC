/****** Object:  UserDefinedTableType [dbo].[CCINGIDENTIF]    Script Date: 26/11/2018 01:44:26 p. m. ******/

USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC spCreaTypes 'DICCIONARIO'
ALTER PROCEDURE  [dbo].[spCreaTypes]  
@pBaseDatos varCHAR(15)

AS
BEGIN

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END
  BEGIN
    DELETE FROM #LINEAMODEL
  END

  DECLARE @sangria0     int  =  0,
          @sangria1     int  =  4,
          @sangria2     int  =  8,
          @sangria3     int  = 12,
          @sangria4     int  = 24,
          @b_declara    bit

  DECLARE @k_verdadero  bit         = 1,
          @k_falso      bit         = 0,
          @k_numerico   varchar(7)  = 'numeric',
		  @k_decimal    varchar(7)  = 'decimal',    
          @k_varchar    varchar(7)  = 'varchar',
		  @k_nvarchar   varchar(8)  = 'nvarchar',
          @k_entero     varchar(3)  = 'int',
          @k_fecha_t    varchar(8)  = 'datetime',
          @k_fecha      varchar(4)  = 'date',
          @k_bit        varchar(3)  = 'bit'

  DECLARE @nom_tabla     varchar(30),
          @datatype      varchar(30),
          @cadena_script varchar(500),
		  @num_campos    int,
		  @cont_campos   int

-- Cursor Tabla Columna

  DECLARE  @nom_tabla_c   varchar(30),
           @nom_campo     varchar(30),
           @tipo_campo    varchar(20),
           @longitud      int,
           @enteros       int,
           @decimales     int,
           @posicion      int,
           @b_nulo        bit

-- Cursor Tabla

  DECLARE cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA WHERE BASE_DATOS = @pBaseDatos AND NOM_TABLA <> 'Sysdiagrams' 
  -- AND NOM_TABLA = 'FC_TABLA'

  OPEN  cur_tabla

  FETCH cur_tabla INTO  @nom_tabla

  SET @b_declara  =  @k_verdadero

  WHILE (@@fetch_status = 0 )
  BEGIN

     SET @cadena_script =
	 'IF EXISTS (SELECT 1 FROM sys.types WHERE is_table_type = 1 AND name = ' +
	 CHAR(39) +  'OB_' + @nom_tabla + CHAR(39) + ')'
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script = 'BEGIN'
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script =  'DROP TYPE OB_' + @nom_tabla
	 EXEC spInsertaScript @cadena_script, @sangria1

     SET @cadena_script = 'END'
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script = '--  ' + 'Creación de Tipos para tablas ' +
	 LTRIM((SELECT NOM_TABLA FROM FC_TABLA WHERE NOM_TABLA = @nom_tabla)) + ' --' 
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script = 'CREATE TYPE ' + 'OB_' + @nom_tabla + ' AS TABLE(' 
     EXEC spInsertaScript @cadena_script, @sangria0
                   
     DECLARE cur_tabla_columna cursor for SELECT 
     NOM_TABLA,
     NOM_CAMPO,
     TIPO_CAMPO,
     LONGITUD,
     ENTEROS,
     DECIMALES,
     POSICION,
     B_NULO
     FROM FC_TABLA_COLUMNA WHERE
     BASE_DATOS = @pBaseDatos AND
     NOM_TABLA = @nom_tabla ORDER BY POSICION
      
     SELECT @num_campos = COUNT(*)
     FROM FC_TABLA_COLUMNA WHERE
     BASE_DATOS = @pBaseDatos AND
     NOM_TABLA = @nom_tabla 
  
     OPEN  cur_tabla_columna

     FETCH cur_tabla_columna INTO
     @nom_tabla_c,
     @nom_campo,
     @tipo_campo,
     @longitud,
     @enteros,
     @decimales,
     @posicion,
     @b_nulo

     SET  @cont_campos = 0

     WHILE (@@fetch_status = 0 )
     BEGIN
       SET @cont_campos =  @cont_campos +  1
	   SET  @datatype  =  ' '
       SET  @datatype  =
       CASE  
         WHEN  @tipo_campo  =  @k_fecha
         THEN  @k_fecha
         WHEN  @tipo_campo  =  @k_fecha_t
         THEN  @k_fecha_t
         WHEN  @tipo_campo  =  @k_entero
         THEN  @k_entero
         WHEN  @tipo_campo  =  @k_varchar AND @longitud > 0 
         THEN  @k_varchar + '(' + CONVERT(VARCHAR(4),@longitud) + ')'
		 WHEN  @tipo_campo  =  @k_nvarchar AND  @longitud > 0
         THEN  @k_nvarchar + '(' + CONVERT(VARCHAR(4),@longitud) + ')'
		 WHEN  @tipo_campo  =  @k_varchar AND @longitud < 0 
         THEN  @k_varchar + '(' + 'max' + ')'
		 WHEN  @tipo_campo  =  @k_nvarchar AND  @longitud < 0
         THEN  @k_nvarchar + '(' + 'max' + ')'
         WHEN  @tipo_campo  =  @k_numerico
         THEN  @k_numerico + '(' + CONVERT(VARCHAR(4), @enteros) + ',' + CONVERT(VARCHAR(2),@decimales) + ')'
         WHEN  @tipo_campo  =  @k_decimal
         THEN  @k_decimal + '(' + CONVERT(VARCHAR(4), @enteros) + ',' + CONVERT(VARCHAR(2),@decimales) + ')'

         WHEN  @tipo_campo  =  @k_bit
         THEN  @k_bit
         ELSE  'ERROR'
       END  

       IF @b_nulo  =  @k_falso
	   BEGIN
         SET  @datatype  =  @datatype + ' NOT NULL'
	   END

       IF  @cont_campos  <>  @num_campos
       BEGIN
         SET  @datatype  =  @datatype + ','
       END

       SET @cadena_script =  @nom_campo +' ' + @datatype 
       EXEC spInsertaScript @cadena_script, @sangria1

       FETCH cur_tabla_columna INTO
       @nom_tabla_c,
       @nom_campo,
       @tipo_campo,
       @longitud,
       @enteros,
       @decimales,
       @posicion,
       @b_nulo
     END

     CLOSE cur_tabla_columna 
     DEALLOCATE cur_tabla_columna

	 SET @cadena_script = ')'
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script = 'GO'
     EXEC spInsertaScript @cadena_script, @sangria0

     FETCH cur_tabla INTO  @nom_tabla

  END

  CLOSE cur_tabla 
  DEALLOCATE cur_tabla 

  SELECT * FROM #LINEAMODEL
END