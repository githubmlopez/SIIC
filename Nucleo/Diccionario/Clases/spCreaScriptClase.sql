USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC spCreaScriptClase
ALTER PROCEDURE  [dbo].[spCreaScriptClase]  
AS
BEGIN

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END
  BEGIN
    DELETE FROM #LINEAMODEL
  END

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
		  @k_nvarchar   varchar(8)     =  'nvarchar',
          @k_entero     varchar(3),
          @k_fecha_t    varchar(8),
          @k_fecha      varchar(4),
          @k_bit        varchar(3),
		  @k_foreign_key   varchar(2)  =  'FK'
         
  DECLARE @k_date_time  varchar(8),
          @k_int        varchar(5),
          @k_string     varchar(6),
          @k_decimal    varchar(7),
          @k_boleano    varchar(7)
        
  DECLARE @nom_tabla     varchar(30),
          @datatype      varchar(20),
          @cadena_script varchar(500)

-- Cursor Tabla Columna

  DECLARE  @nom_tabla_c   varchar(30),
           @nom_campo     varchar(30),
           @tipo_campo    varchar(20),
           @longitud      int,
           @enteros       int,
           @decimales     int,
           @posicion      int,
           @b_nulo        bit

-- Creación de DATA SETS

  SET @k_verdadero = 1
  SET @k_falso     = 0

  SET @k_numerico  =  'numeric'
  SET @k_varchar   =  'varchar'
  SET @k_entero    =  'int'
  SET @k_fecha_t   =  'datetime'
  SET @k_fecha     =  'date'
  SET @k_bit       =  'bit'

  SET @k_date_time =  'DateTime'
  SET @k_int       =  'Int32'
  SET @k_string    =  'string'
  SET @k_decimal   =  'decimal'
  SET @k_boleano   =  'Boolean'


  SET @sangria0  =  0
  SET @sangria1  =  4
  SET @sangria2  =  8
  SET @sangria3  =  12
  SET @sangria4  =  24


-- Cursor Tabla

  DECLARE cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA WHERE NOM_TABLA <> 'Sysdiagrams' 
 --   AND NOM_TABLA = 'CI_TRASP_BANCARIO'

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

  SET @cadena_script = 'using System.Collections;'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'namespace ModAdmon01'
  EXEC spInsertaScript @cadena_script, @sangria0
  SET @cadena_script = '{'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = ' '
  EXEC spInsertaScript @cadena_script, @sangria0
 
  OPEN  cur_tabla

  FETCH cur_tabla INTO  @nom_tabla

  SET @b_declara  =  @k_verdadero

  WHILE (@@fetch_status = 0 )
  BEGIN

     SET @cadena_script = '//  ' + 'Descripción Clase para tabla ' +
	 LTRIM((SELECT NOM_TABLA FROM FC_TABLA WHERE NOM_TABLA = @nom_tabla)) + ' --' 
     EXEC spInsertaScript @cadena_script, @sangria0

     SET @cadena_script = 'public class ' + dbo.fnConvierteCamello(@nom_tabla) 
     EXEC spInsertaScript @cadena_script, @sangria0
   
     SET @cadena_script = '{'
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
     FROM FC_TABLA_COLUMNA where
     NOM_TABLA = @NOM_TABLA ORDER BY POSICION
  
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

     WHILE (@@fetch_status = 0 )
     BEGIN
       SET  @datatype  =  ' '
       SET  @datatype  =
       CASE  
         WHEN  @tipo_campo  IN  (@k_fecha, @k_fecha_t)
         THEN  @k_date_time
         WHEN  @tipo_campo  =  @k_entero
         THEN  @k_int
         WHEN  @tipo_campo  =  @k_varchar
         THEN  @k_string
         WHEN  @tipo_campo  =  @k_numerico
         THEN  @k_decimal
         WHEN  @tipo_campo  =  @k_bit
         THEN  @k_boleano
		 WHEN  @tipo_campo  =  @k_decimal
         THEN  @k_decimal
		 WHEN  @tipo_campo   =  @k_nvarchar  
		 THEN  @k_string
         ELSE  'ERROR'
       END  
	   --SELECT 'DATA TYPE'
	   --SELECT @datatype
	   --SELECT 'NOMBRE CAMPO'
    --   SELECT @nom_campo
	   --SELECT dbo.fnConvierteCamello(@nom_campo)
       SET @cadena_script = 'public ' + @datatype + ' ' + dbo.fnConvierteCamello(@nom_campo) + ' {get; set;}' 
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

-- Crear llaves Colecciones

     IF  EXISTS(SELECT 1 FROM FC_CONSTRAINT WHERE
         NOM_TABLA = @nom_tabla and TIPO_LLAVE =  @k_foreign_key)
     BEGIN
       SET @cadena_script = '// Definición de Relaciones --'
       EXEC spInsertaScript @cadena_script, @sangria0
       EXEC spModelaRelacion @nom_tabla
     END
     
	 IF  EXISTS(SELECT 1 FROM FC_CONSTRAINT WHERE
         NOM_TABLA_REF = @nom_tabla and TIPO_LLAVE =  @k_foreign_key)
     BEGIN
       SET @cadena_script = '// Definición de Colecciones --'
       EXEC spInsertaScript @cadena_script, @sangria0
       EXEC spModelaColeccion @nom_tabla
     END

	 SET @cadena_script = '}'
     EXEC spInsertaScript @cadena_script, @sangria0

     FETCH cur_tabla INTO  @nom_tabla

  END

  CLOSE cur_tabla 
  DEALLOCATE cur_tabla 

  SET @cadena_script = '}'
  EXEC spInsertaScript @cadena_script, @sangria0

  SELECT * FROM #LINEAMODEL
END