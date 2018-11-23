USE DICCIONARIO
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[spModelaRelacion]  @pnomtabla varchar(30)
AS

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
		   @sinonimo         varchar(1),
		   @pref_tab_recur   varchar(1)

-- CURSOR Tabla Constraints - Campo

  DECLARE   @k_foreign_key   varchar(2)

  DECLARE  @nom_tabla_c      varchar(30),
           @nom_constraint_c varchar(30),
           @nom_campo        varchar(30),
           @nom_campo_ref    varchar(20)

  DECLARE  @cont_rep         int  =  0

  SET @k_foreign_key  =  'FK'

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
  SINONIMO,
  PREF_TAB_RECUR
  FROM FC_CONSTRAINT WHERE
  NOM_TABLA = @pnomtabla and TIPO_LLAVE =  @k_foreign_key

  OPEN  cur_constraint

  FETCH cur_constraint INTO 
  @nom_tabla,
  @nom_constraint,
  @nom_tabla_ref,
  @tipo_llave,
  @sinonimo,
  @pref_tab_recur

  WHILE (@@fetch_status = 0 )
  BEGIN

     SET @cadena_script = 'public ' + LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref)) + '  ' +
                           REPLACE(LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref) + @sinonimo  + @pref_tab_recur),' ','')  +
						   ' {get; set;}'

  --   IF  EXISTS (SELECT 1 FROM #LINEAMODEL WHERE LINEA LIKE ('%' + @cadena_script + '%'))
	 --BEGIN
  --     SET @cont_rep = @cont_rep + 1
  --     SET @cadena_script = 'public' + ' ICollection<' + LTRIM(dbo.fnConvierteCamello(@nom_tabla)) + '> ' +
  --                           LTRIM(dbo.fnConvierteCamello(@nom_tabla)) + CONVERT(VARCHAR(1),@cont_rep) + '_s ' + ' {get; set;}'

	 --END
	     
     EXEC spInsertaScript @cadena_script, @sangria1

     FETCH cur_constraint INTO 
     @nom_tabla,
     @nom_constraint,
     @nom_tabla_ref,
     @tipo_llave,
     @sinonimo,
	 @pref_tab_recur

  END

  CLOSE cur_constraint 
  DEALLOCATE cur_constraint 

-- SELECT * FROM #LINEAMODEL 

END