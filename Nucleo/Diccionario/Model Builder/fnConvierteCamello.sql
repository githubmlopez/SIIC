ALTER FUNCTION fnConvierteCamello(@pStrParam  varchar(30))
RETURNS varchar(30)
-- WITH EXECUTE AS CALLER
AS
BEGIN

-- DECLARE @pStrParam  varchar(30)

-- SET @pStrParam = 'TABLA_TABLA1_TABLA2'

DECLARE  @nom_objeto    varchar(30),
         @k_delimitador varchar(1),
         @posicion      int,
         @sub_string    varchar(30),
         @pStrCamel     varchar(30)

SET  @k_delimitador  =  '_'
SET  @pStrCamel      =  ' '

SELECT @pStrParam  = LOWER ( @pStrParam + '_' )

WHILE ((len(@pStrParam) > 0) and (@pStrParam <> ''))
BEGIN
--  SELECT ' Entre a WHILE' + @pStrParam 
  SET @posicion  = charindex(@k_delimitador, @pStrParam)
--  SELECT ' Calculo de primera posición ' + CONVERT(varchar(4),@posicion) 
  IF  @posicion  >  0
  BEGIN
--    SELECT 'La posición es distinta de cero'
    SET @sub_string  = substring(@pStrParam, 1, @Posicion - 1)
    SET @sub_string  = upper(substring(@sub_string,1,1)) + substring(@sub_string,2,30)
--    SELECT 'Primer substing ' + @sub_string
    SET @pStrCamel   = @pStrCamel + @sub_string  
--    SELECT ' Camel Parcial' + @pStrCamel 
    SET @pStrParam   = ltrim(substring(@pStrParam,charindex(@k_delimitador, @pStrParam)+1, 200))
--    SELECT ' Nuevo STR' + @pStrParam 

  END

END

return LTRIM(@pStrCamel)

-- SELECT @pStrCamel


END 
