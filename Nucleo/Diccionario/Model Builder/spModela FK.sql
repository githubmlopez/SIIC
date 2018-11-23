SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
-- DROP PROCEDURE spModelaFK
ALTER PROCEDURE [dbo].[spModelaFK]  @pnomtabla varchar(30)
AS

  BEGIN

  DECLARE @sinonimo      varchar(6),
          @sinonimo_ref  varchar(4),
		  @prefijo       varchar(1)

  DECLARE @num_campos    int,
          @cont_campos   int,
          @delimitador   varchar(2),
          @cadena_script varchar(500),
          @campos_fk     varchar(500),
          @sangria0      int,
          @sangria1      int,
          @sangria2      int,
          @sangria3      int,
          @sangria4      int


-- Cursor Tabla Constraints

  DECLARE  @nom_tabla        varchar(30),
           @nom_constraint   varchar(50),
           @nom_tabla_ref    varchar(30),
           @tipo_llave       varchar(20)

-- Cursor Tabla Constraints - Campo

  DECLARE   @k_foreign_key   varchar(2),
            @k_verdadero     bit

  DECLARE  @nom_tabla_c      varchar(30),
           @nom_constraint_c varchar(30),
           @nom_campo        varchar(30),
           @nom_campo_ref    varchar(20)

  SET @k_foreign_key  =  'FK'
  SET @k_verdadero    =  1

  SET @sangria0  =  0
  SET @sangria1  =  4
  SET @sangria2  =  8
  SET @sangria3  =  12
  SET @sangria4  =  24

  DECLARE cur_constraint cursor for SELECT
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
  @prefijo

  WHILE (@@fetch_status = 0 )
  BEGIN
     SELECT @sinonimo      =  (SELECT SINONIMO FROM FC_TABLA_EX WHERE NOM_TABLA = @nom_tabla) 
     SELECT @sinonimo_ref  =  (SELECT SINONIMO FROM FC_TABLA_EX WHERE NOM_TABLA = @nom_tabla_ref) 

     SET @cadena_script = 'ModelBuilder.Entity<' + LTRIM(dbo.fnConvierteCamello(@nom_tabla)) + '>()'
     EXEC spInsertaScript @cadena_script, @sangria3

--   INSERT INTO #LINEAMODEL VALUES
--   ('modelBuilder.Entity<' + @nom_tabla + '>()') 

     SET @num_campos  =
     (SELECT COUNT(*) 
     FROM FC_CONSTR_CAMPO coca, FC_TABLA_COLUMNA taco where
     coca.NOM_TABLA      = @nom_tabla       and
     coca.NOM_CONSTRAINT = @nom_constraint  and
     coca.NOM_TABLA      = taco.NOM_TABLA   and
     coca.NOM_CAMPO      = taco.NOM_CAMPO   and
     taco.B_NULO         = @k_verdadero)

     IF @num_campos = 0
     BEGIN
       SET @cadena_script = '.HasRequired<' + LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref)) + '>' +
	   + '(' + @sinonimo + ' => ' + @sinonimo + '.' + 
	   REPLACE(LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref) + @prefijo),' ','') + ')'
     END
     ELSE
     BEGIN
       SET @cadena_script = '.HasOptional<' + LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref)) + '>' +
	   + '(' + @sinonimo + ' => ' + @sinonimo + '.' + 
	   REPLACE(LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref) + @prefijo),' ','') + ')'
     END
   
     EXEC spInsertaScript @cadena_script, @sangria4

     SET @cadena_script = '.WithMany(' + @sinonimo_ref + ' => ' + @sinonimo_ref + '.' + 
	 (LTRIM(dbo.fnConvierteCamello(@nom_tabla))) + '_s' + ')'
     EXEC spInsertaScript @cadena_script, @sangria4
   --INSERT INTO #LINEAMODEL VALUES
   --('.HasRequired(' + @sinonimo + ' => ' + @sinonimo + '.' + @nom_tabla_ref + ')')
   --INSERT INTO #LINEAMODEL VALUES
   --('.WithMany(' + @sinonimo_ref + ' => ' + @sinonimo_ref + '.' + LTRIM(dbo.fnConvierteCamello(@nom_tabla_ref)) + ')')

     SET @num_campos  =
     (SELECT COUNT(*) 
     FROM FC_CONSTR_CAMPO coca, FC_TABLA_COLUMNA taco where
     coca.NOM_TABLA      = @nom_tabla       and
     coca.NOM_CONSTRAINT = @nom_constraint  and
     coca.NOM_TABLA      = taco.NOM_TABLA   and
     coca.NOM_CAMPO      = taco.NOM_CAMPO)

     DECLARE cur_const_campo cursor for SELECT 
     coca.NOM_TABLA,
     coca.NOM_CONSTRAINT,
     coca.NOM_CAMPO,
     coca.NOM_CAMPO_REF
     FROM FC_CONSTR_CAMPO coca, FC_TABLA_COLUMNA taco where
     coca.NOM_TABLA      = @nom_tabla       and
     coca.NOM_CONSTRAINT = @nom_constraint  and
     coca.NOM_TABLA      = taco.NOM_TABLA   and
     coca.NOM_CAMPO      = taco.NOM_CAMPO   ORDER BY taco.POSICION

     OPEN  cur_const_campo

     FETCH cur_const_campo INTO
     @nom_tabla_c,
     @nom_constraint_c,
     @nom_campo,
     @nom_campo_ref

     SET @num_campos = (SELECT count(*)  
     FROM FC_CONSTR_CAMPO where
     NOM_TABLA      = @nom_tabla and
     NOM_CONSTRAINT = @nom_constraint)

     SET  @cont_campos  =  0
     SET  @campos_fk    =  ' '
     SET  @delimitador  =  ', '

     WHILE (@@fetch_status = 0 )
     BEGIN

       SET  @cont_campos = @cont_campos + 1
       IF   @cont_campos  =  @num_campos
       BEGIN
         SET @delimitador =  ' '        
       END
       SET  @campos_fk = LTRIM(@campos_fk + @sinonimo + '.' + LTRIM(dbo.fnConvierteCamello(@nom_campo)) + @delimitador)  

       FETCH cur_const_campo INTO
       @nom_tabla_c,
       @nom_constraint_c,
       @nom_campo,
       @nom_campo_ref
     END

     CLOSE cur_const_campo
     DEALLOCATE cur_const_campo
 
     IF  @num_campos > 1
     BEGIN
       SET @cadena_script = '.HasForeignKey(' + @sinonimo + ' => ' + 'new {' + RTRIM(@campos_fk) + '}' + ');'
     END
     ELSE
     BEGIN
       SET @cadena_script = '.HasForeignKey(' + @sinonimo + ' => ' + RTRIM(@campos_fk) + ');'
     END
     EXEC spInsertaScript @cadena_script, @sangria4

 --  INSERT INTO #LINEAMODEL VALUES
 --  ('.HasForeignKey(' + @sinonimo + ' => ' + '(' + RTRIM(@campos_fk) + ');')

     FETCH cur_constraint INTO 
     @nom_tabla,
     @nom_constraint,
     @nom_tabla_ref,
     @tipo_llave,
     @sinonimo,
	 @prefijo

  END

  CLOSE cur_constraint 
  DEALLOCATE cur_constraint 

-- SELECT * FROM #LINEAMODEL 

END