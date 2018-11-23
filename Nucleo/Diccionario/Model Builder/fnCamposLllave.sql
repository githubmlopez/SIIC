ALTER FUNCTION fnCamposLlave(@ptabla  varchar(30), @psinonimo varchar(4), @tipo_llave varchar(2))
RETURNS varchar(500)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  --DECLARE @ptabla  varchar(30),
  --        @psinonimo varchar(4)
  --SET @ptabla = 'CI_FACTURA'
  --SET @psinonimo = 'ad01'
  
  DECLARE  -- @k_primaria   varchar(1),
           @nom_campo    varchar(30),
           @campos_key   varchar(500),
           @num_campos   int,
           @cont_campos  int,
           @delimitador  varchar(1)
           

--  SET @k_primaria  =  'PK'

  SET @campos_key  =  ' '
  SET @cont_campos =  ' '
  SET @delimitador =  ','
  
  SET @num_campos  =
  (SELECT 
  COUNT(*) FROM FC_CONSTRAINT c, FC_CONSTR_CAMPO cp, FC_TABLA_COLUMNA tc
  WHERE c.NOM_TABLA = @ptabla and
  c.TIPO_LLAVE      = @tipo_llave              and
  c.NOM_TABLA       = cp.NOM_TABLA      and
  c.NOM_CONSTRAINT  = cp.NOM_CONSTRAINT and
  cp.NOM_TABLA      = tc.NOM_TABLA      and
  cp.NOM_CAMPO      = tc.NOM_CAMPO)  
  
  DECLARE cur_pk cursor for SELECT 
  cp.NOM_CAMPO FROM FC_CONSTRAINT c, FC_CONSTR_CAMPO cp, FC_TABLA_COLUMNA tc
  WHERE c.NOM_TABLA = @ptabla and
  c.TIPO_LLAVE      = @tipo_llave              and
  c.NOM_TABLA       = cp.NOM_TABLA      and
  c.NOM_CONSTRAINT  = cp.NOM_CONSTRAINT and
  cp.NOM_TABLA      = tc.NOM_TABLA      and
  cp.NOM_CAMPO      = tc.NOM_CAMPO  ORDER BY tc.POSICION  
  
  OPEN  cur_pk
  
  FETCH cur_pk INTO @nom_campo
  
  WHILE (@@fetch_status = 0 )
  BEGIN
    SET  @cont_campos = @cont_campos + 1
    if   @cont_campos  =  @num_campos
    BEGIN
      SET @delimitador =  ' '        
    END
    SET  @campos_key =
	LTRIM(@campos_key + rtrim(@psinonimo) + '.' + ltrim(dbo.fnConvierteCamello(@nom_campo)) + @delimitador) 
    FETCH cur_pk INTO @nom_campo
  END

  IF  @num_campos > 1
  BEGIN
    SET @campos_key = @psinonimo +  ' => new { ' + @campos_key + '}'
  END

  CLOSE cur_pk 
  DEALLOCATE cur_pk 
--  select  @campos_key

  RETURN @campos_key
END