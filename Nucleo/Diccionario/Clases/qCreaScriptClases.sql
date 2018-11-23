DROP TABLE #LINEAMODEL 
CREATE TABLE #LINEAMODEL (LINEA varchar(200))

declare @sangria0     int,
        @sangria1     int,
        @sangria2     int,
        @sangria3     int,
        @sangria4     int,
        @b_declara    bit

declare @k_verdadero  bit,
        @k_falso      bit,
        @k_numerico   varchar(7),
        @k_varchar    varchar(7),
        @k_entero     varchar(3),
        @k_fecha      varchar(4),
        @k_bit        varchar(3)
         
declare @k_date_time  varchar(8),
        @k_int        varchar(5),
        @k_string     varchar(6),
        @k_decimal    varchar(7),
        @k_boleano    varchar(7)
        
declare @nom_tabla     varchar(30),
        @datatype      varchar(20),
        @cadena_script varchar(500)

-- Cursor Tabla Columna

declare  @nom_tabla_c   varchar(30),
         @nom_campo     varchar(30),
         @tipo_campo    varchar(20),
         @longitud      int,
         @enteros       int,
         @decimales     int,
         @posicion      int,
         @b_nulo        bit

-- Creación de DATA SETS

set @k_verdadero = 1
set @k_falso     = 0

set @k_numerico  =  'numeric'
set @k_varchar   =  'varchar'
set @k_entero    =  'int'
set @k_fecha     =  'date'
set @k_bit       =  'bit'

set @k_date_time =  'DateTime'
set @k_int       =  'Int32'
set @k_string    =  'string'
set @k_decimal   =  'decimal'
set @k_boleano   =  'Boolean'


set @sangria0  =  0
set @sangria1  =  4
set @sangria2  =  8
set @sangria3  =  12
set @sangria4  =  24


-- Cursor Tabla

declare cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA -- WHERE NOM_TABLA = 'CI_FACTURA'
  
open  cur_tabla

FETCH cur_tabla INTO  @nom_tabla

set @b_declara  =  @k_verdadero

WHILE (@@fetch_status = 0 )
BEGIN

   set @cadena_script = '//  ' + LTRIM((SELECT DESC_TABLA FROM FC_TABLA_EX WHERE NOM_TABLA = @nom_tabla)) +
                        ' --' 
   exec spInsertaScript @cadena_script, @sangria0

   set @cadena_script = 'public class ' + dbo.fnConvierteCamello(@nom_tabla) 
   exec spInsertaScript @cadena_script, @sangria0
   
   set @cadena_script = '{'
   exec spInsertaScript @cadena_script, @sangria0
                    
   declare cur_tabla_columna cursor for SELECT 
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
  
   open  cur_tabla_columna

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
     set  @datatype  =  ' '
     set  @datatype  =
     CASE  
       when  @tipo_campo  =  @k_fecha
       then  @k_date_time
       when  @tipo_campo  =  @k_entero
       then  @k_int
       when  @tipo_campo  =  @k_varchar
       then  @k_string
       when  @tipo_campo  =  @k_numerico
       then  @k_decimal
       when  @tipo_campo  =  @k_bit
       then  @k_boleano

     END  

     set @cadena_script = 'public ' + @datatype + ' ' + dbo.fnConvierteCamello(@nom_campo) + ' {get; set;}' 
     exec spInsertaScript @cadena_script, @sangria1

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

   close cur_tabla_columna 
   deallocate cur_tabla_columna

-- Crear llaves Colecciones

   set @cadena_script = '// Definición de Colecciones --'
   exec spInsertaScript @cadena_script, @sangria0

   exec spModelaColeccion @nom_tabla

FETCH cur_tabla INTO  @nom_tabla

END

close cur_tabla 
deallocate cur_tabla 

set @cadena_script = '}'
exec spInsertaScript @cadena_script, @sangria0

SELECT * FROM #LINEAMODEL