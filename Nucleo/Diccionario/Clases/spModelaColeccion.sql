USE DICCIONARIO
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[spModelaColeccion]  @pnomtabla varchar(30)
as

BEGIN

  DECLARE @cadena_script varchar(500),
          @sangria0      int,
          @sangria1      int,
          @sangria2      int,
          @sangria3      int,
          @sangria4      int


-- CURSOR Tabla Constraints

  DECLARE  @nom_tabla        varchar(30),
           @nom_constraint   varchar(30),
           @nom_tabla_ref    varchar(30),
           @tipo_llave       varchar(20),
		   @sinonimo         varchar(1)

-- CURSOR Tabla Constraints - Campo

  DECLARE   @k_FOReign_key   varchar(2)

  DECLARE  @nom_tabla_c      varchar(30),
           @nom_constraint_c varchar(30),
           @nom_campo        varchar(30),
           @nom_campo_ref    varchar(20)

  DECLARE  @cont_rep         int  =  0

  SET @k_FOReign_key  =  'FK'

  SET @sangria0  =  0
  SET @sangria1  =  4
  SET @sangria2  =  8
  SET @sangria3  =  12
  SET @sangria4  =  24

  DECLARE cur_constraint CURSOR FOR SELECT
  NOM_TABLA,
  NOM_CONSTRAINT,
  NOM_TABLA_REF,
  TIPO_LLAVE,
  SINONIMO
  FROM FC_CONSTRAINT WHERE
  NOM_TABLA_REF = @pnomtabla and TIPO_LLAVE =  @k_FOReign_key

  OPEN  cur_constraint

  FETCH cur_constraint INTO 
  @nom_tabla,
  @nom_constraint,
  @nom_tabla_ref,
  @tipo_llave,
  @sinonimo

  WHILE (@@fetch_status = 0 )
  BEGIN

     SET @cadena_script = 'public virtual' + ' ICollection<' + LTRIM(dbo.fnConvierteCamello(@nom_tabla)) + '> ' +
                           REPLACE(LTRIM(dbo.fnConvierteCamello(@nom_tabla) + @sinonimo),' ','') +
						    '_s ' + ' {get; set;}'

     EXEC spInsertaScript @cadena_script, @sangria1

     FETCH cur_constraint INTO 
     @nom_tabla,
     @nom_constraint,
     @nom_tabla_ref,
     @tipo_llave,
	 @sinonimo

  END

  CLOSE cur_constraint 
  DEALLOCATE cur_constraint 

-- SELECT * FROM #LINEAMODEL 

END