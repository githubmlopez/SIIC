
DROP TABLE #LINEAMODEL 
CREATE TABLE #LINEAMODEL (LINEA varchar(200))

declare @pnom_contexto varchar(100)

set @pnom_contexto = 'ContextoPrueba'

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
        @k_entero     varchar(2),
        @k_fecha      varchar(4)

declare @nom_tabla     varchar(30),
        @sinonimo      varchar(6),
        @sinonimo_ref  varchar(4),
        @cadena_script varchar(500),
		@campos_llave  varchar(200)

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


set @sangria0  =  0
set @sangria1  =  4
set @sangria2  =  8
set @sangria3  =  12
set @sangria4  =  24

set @cadena_script = '// Definición de namespace que tendrá el CONTEXTO'
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = ('namespace EF_Contextos')
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = '{'
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// Definición de la clase que heredará de DbContext'
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = 'public class ' + @pnom_contexto + ': DbContext'
exec spInsertaScript @cadena_script, @sangria1

set @cadena_script = '{'
exec spInsertaScript @cadena_script, @sangria1

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// Definición de Propiedades de la Clase de tipo DBSET<Entity>'
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// Se incluye el prefijo _s en las propiedades para indicar el conjunto (plural) '
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0

INSERT INTO #LINEAMODEL 
SELECT 
REPLICATE(' ', @sangria2) + 'public DBSET<' + dbo.fnConvierteCamello(tb.NOM_TABLA) +
'>' + ' ' + dbo.fnConvierteCamello(tb.NOM_TABLA) + '_s ' + '{ get; set; }'
from FC_TABLA tb

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// Definición de metodo OnModelCreating en donde se ejectutaran los diferentes métodos'
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// que configuran las entidades. Pasa como argumento un objeto del tipo DbModelBuilder'
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0

set @cadena_script = 'protected override void OnModelCreating(DbModelBuilder modelBuilder)'
exec spInsertaScript @cadena_script, @sangria2

set @cadena_script = '{'
exec spInsertaScript @cadena_script, @sangria2

INSERT INTO #LINEAMODEL 
select REPLICATE(' ', @sangria3) + 'Configurar_' + dbo.fnConvierteCamello(tb.NOM_TABLA) + ' ' +
'(modelbuilder);' 
from FC_TABLA tb 

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria3

set @cadena_script = 'base.OnModelCreating(modelBuilder)'
exec spInsertaScript @cadena_script, @sangria3

set @cadena_script = '}'
exec spInsertaScript @cadena_script, @sangria2


declare cur_tabla cursor for SELECT NOM_TABLA FROM FC_TABLA WHERE NOM_TABLA = 'CI_FACTURA'
  
open  cur_tabla

FETCH cur_tabla INTO  @nom_tabla

set @b_declara  =  @k_verdadero

WHILE (@@fetch_status = 0 )
BEGIN

set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = '// Configuración de la tabla ' + @nom_tabla
exec spInsertaScript @cadena_script, @sangria0
set @cadena_script = ' '
exec spInsertaScript @cadena_script, @sangria0

   if  @b_declara  =  @k_verdadero
   begin 
     set @cadena_script = 'private void Configurar_' + dbo.fnConvierteCamello(@nom_tabla) + '(DbModelBuilder modelBuilder)'
     exec spInsertaScript @cadena_script, @sangria2
     set @b_declara  =  @k_falso
   end
   
   set @cadena_script = '{'
   exec spInsertaScript @cadena_script, @sangria2

   select @sinonimo  =  (SELECT SINONIMO FROM FC_TABLA_EX WHERE NOM_TABLA = @nom_tabla) 
 
   set @cadena_script = 'modelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
   exec spInsertaScript @cadena_script, @sangria3

   set @cadena_script = '.ToTable("' + @nom_tabla + '");'
   exec spInsertaScript @cadena_script, @sangria4
                      
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
   NOM_TABLA = @NOM_TABLA
  
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
     set @cadena_script = 'modelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
     exec spInsertaScript @cadena_script, @sangria3
     set @b_declara  =  @k_falso

     set @cadena_script = '.Property' + '(' + @sinonimo + ' => ' +  @sinonimo + '.' + dbo.fnConvierteCamello(@nom_campo) + ')'
     exec spInsertaScript @cadena_script, @sangria4

     set @cadena_script = '.HasColumnName("' + @nom_campo + '")'
     exec spInsertaScript @cadena_script, @sangria4

     set @cadena_script = '.HasColumnType(' + '"' + @tipo_campo + '"' + ')'
     exec spInsertaScript @cadena_script, @sangria4

     if  @tipo_campo  =  @k_numerico 
     begin
       set @cadena_script = '.HasPrecision(' + CONVERT(varchar(2), @enteros) + ',' + CONVERT(varchar(2), @decimales) + ')'
       exec spInsertaScript @cadena_script, @sangria4
     end

     if  @tipo_campo  =  @k_varchar
     begin
       set @cadena_script = '.HasMaxLength(' + CONVERT(varchar(3), @longitud) + ')'
       exec spInsertaScript @cadena_script, @sangria4
       set @cadena_script = '.IsUnicode(false)'
       exec spInsertaScript @cadena_script, @sangria4
     end

     if  @b_nulo  =  @k_falso
     begin
       set @cadena_script = '.IsRequired()'
       exec spInsertaScript @cadena_script, @sangria4
     end
     else
     begin
       set @cadena_script = '.IsOptional()'
       exec spInsertaScript @cadena_script, @sangria4
     end

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

   set @cadena_script = ' '
   exec spInsertaScript @cadena_script, @sangria3

   set @cadena_script = 'modelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
   exec spInsertaScript @cadena_script, @sangria3

   
   set @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'PK'))
   set @cadena_script = '.HasKey(' + @campos_llave + ');'
   exec spInsertaScript @cadena_script, @sangria4

   set @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'UQ'))
   if  @campos_llave  <> ' ' 
   begin
     set @cadena_script = 'modelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
     exec spInsertaScript @cadena_script, @sangria3
     set @cadena_script = '.HasAlternateKey(' + @campos_llave + ');'
     exec spInsertaScript @cadena_script, @sangria4
   end

   set @campos_llave  = RTRIM(dbo.fnCamposLlave(@nom_tabla,@sinonimo,'IX'))
   if  @campos_llave  <> ' ' 
   begin
     set @cadena_script = 'modelBuilder.Entity<' + dbo.fnConvierteCamello(@nom_tabla) + '>()'
     exec spInsertaScript @cadena_script, @sangria3
     set @cadena_script = '.HasIndex(' + @campos_llave + ');'
     exec spInsertaScript @cadena_script, @sangria4
   end
    
   set @cadena_script = ' '
   exec spInsertaScript @cadena_script, @sangria3

-- Crear llaves Foraneas

   exec spModelaFK @nom_tabla

   set @cadena_script = '}'
   exec spInsertaScript @cadena_script, @sangria2


FETCH cur_tabla INTO  @nom_tabla

END

close cur_tabla 
deallocate cur_tabla 

set @cadena_script = '}'
exec spInsertaScript @cadena_script, @sangria0

SELECT * FROM #LINEAMODEL