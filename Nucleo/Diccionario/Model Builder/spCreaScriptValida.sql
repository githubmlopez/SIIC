USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC spCreaScriptValida 'CI_FACTURA'
ALTER PROCEDURE  [dbo].[spCreaScriptValida] @pTabla varchar(30), @pTipoMovto varchar(1) 
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @var_nom_campo     varchar(20)

  IF object_id('tempdb..#LINEAMODEL') IS  NULL 
  BEGIN
    CREATE TABLE #LINEAMODEL (LINEA varchar(200))
  END
  BEGIN
    DELETE FROM #LINEAMODEL
  END

  DECLARE @TTablaCampo AS TABLE
 (RowId                int  IDENTITY(1,1),
  NOM_TABLA            varchar(30),          
  NOM_CAMPO            varchar(30),          
  TIPO_CAMPO           varchar(20),          
  LONGITUD             int,                  
  ENTEROS              int,                  
  DECIMALES            int,                  
  POSICION             int,                  
  B_NULO               bit,                  
  B_IDENTITY           bit,
  DESC_CAMPO           varchar(200))

  DECLARE 
  @nom_tabla           varchar(30),          
  @nom_campo           varchar(30),          
  @tipo_campo          varchar(20),          
  @longitud            int,                  
  @enteros             int,                  
  @decimales           int,                  
  @posicion            int,                  
  @b_nulo              bit,                  
  @b_identity          bit,
  @desc_campo          varchar(200)

  DECLARE @sangria0     int  =  0,
          @sangria1     int  =  2,
          @sangria2     int  =  4,
          @sangria3     int  =  6,
          @sangria4     int  =  8

  DECLARE @k_verdadero  bit         = 1,
          @k_falso      bit         = 0,
          @k_numerico   varchar(7)  = 'numeric',
          @k_varchar    varchar(7)  = 'varchar',
          @k_entero     varchar(3)  = 'int',
          @k_fecha      varchar(4)  = 'date',
		  @k_fecha_h    varchar(8)  = 'datetime',
		  @k_decimal    varchar(7)  = 'decimal',
		  @k_bit        varchar(3)  = 'bit'

  DECLARE @cadena_script varchar(500)

  SET @cadena_script = 'USE [DICCIONARIO]'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'SET ANSI_NULLS ON'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'SET NOCOUNT ON'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'GO'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'CREATE PROCEDURE [dbo].[spValOB_' +
  LTRIM(SUBSTRING(@pTabla,4,26)) + '] ' +  '@p' + LTRIM(SUBSTRING(@pTabla,4,26)) + ' ' +
  'OB_' + LTRIM(SUBSTRING(@pTabla,4,26)) + ' READONLY'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'AS'
  EXEC spInsertaScript @cadena_script, @sangria0
  
  SET @cadena_script = 'BEGIN'
  EXEC spInsertaScript @cadena_script, @sangria0

  SET @cadena_script = 'DECLARE '
  EXEC spInsertaScript @cadena_script, @sangria1

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TTablaCampo  (NOM_TABLA, NOM_CAMPO, TIPO_CAMPO, LONGITUD, ENTEROS, DECIMALES,                  
                        POSICION, B_NULO, B_IDENTITY, DESC_CAMPO)
  
  SELECT tc.NOM_TABLA, tc.NOM_CAMPO, tc.TIPO_CAMPO, tc.LONGITUD, tc.ENTEROS, tc.DECIMALES,
         tc.POSICION, tc.B_NULO, tc.B_IDENTITY, tce.DESC_CAMPO                  
         FROM FC_TABLA_COLUMNA tc, FC_TABLA_COL_EX tce
         WHERE  tc.NOM_TABLA  =  @pTabla       AND
		        tc.NOM_TABLA  = tce.NOM_TABLA  AND
				tc.NOM_CAMPO  = tce.NOM_CAMPO

  SET @NunRegistros = @@ROWCOUNT

-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT 
    @nom_tabla    =  tc.NOM_TABLA,         
    @nom_campo    =  tc.NOM_CAMPO,          
    @tipo_campo   =  tc.TIPO_CAMPO,          
    @longitud     =  tc.LONGITUD,                  
    @enteros      =  tc.ENTEROS,              
    @decimales    =  tc.DECIMALES,               
    @posicion     =  tc.POSICION,             
    @b_nulo       =  tc.B_NULO,              
    @b_identity   =  tc.B_IDENTITY,
    @desc_campo   =  tc.DESC_CAMPO
	FROM   @TTablaCampo tc
	WHERE  RowID  =  @RowCount

	SET @cadena_script =
	'@' + LOWER(@nom_campo) + REPLICATE(' ', (25 - LEN(@nom_campo))) 

	IF  @tipo_campo in (@k_entero, @k_bit, @k_fecha, @k_fecha_h)
	BEGIN
      SET  @cadena_script =  @cadena_script +
	  LTRIM(@tipo_campo) 
	END
	ELSE
	BEGIN
	  IF  @tipo_campo IN (@k_numerico, @k_decimal)
	  BEGIN
        SET  @cadena_script =  @cadena_script +
	    LTRIM(@tipo_campo) + '(' + LTRIM(@enteros) + ',' +  LTRIM(@decimales) +
		')' 
	  END
      ELSE
	  BEGIN
    	IF  @tipo_campo IN (@k_varchar)
	    BEGIN
          SET  @cadena_script =  @cadena_script +
	      LTRIM(@tipo_campo) + '(' + LTRIM(@longitud) + ')' 
 		END
        ELSE
		BEGIN
		  SET  @cadena_script =  @cadena_script + ' NO IDENTIFICADO'
		END
	  END
	END
    IF  @RowCount < @NunRegistros
	BEGIN
	  SET  @cadena_script =  @cadena_script + ','
	END

    EXEC spInsertaScript @cadena_script, @sangria1
    SET @RowCount =  @RowCount + 1

  END

  SET @cadena_script =  'SELECT  TOP(1)' 
  EXEC spInsertaScript @cadena_script, @sangria1

  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT 
    @nom_tabla    =  tc.NOM_TABLA,         
    @nom_campo    =  tc.NOM_CAMPO,          
    @tipo_campo   =  tc.TIPO_CAMPO,          
    @longitud     =  tc.LONGITUD,                  
    @enteros      =  tc.ENTEROS,              
    @decimales    =  tc.DECIMALES,               
    @posicion     =  tc.POSICION,             
    @b_nulo       =  tc.B_NULO,              
    @b_identity   =  tc.B_IDENTITY,
    @desc_campo   =  tc.DESC_CAMPO
	FROM   @TTablaCampo tc
	WHERE  RowID  =  @RowCount

	SET @cadena_script =
	'@' + LOWER(@nom_campo) + REPLICATE(' ', (25 - LEN(@nom_campo))) +
	' = ' + @nom_campo

    EXEC spInsertaScript @cadena_script, @sangria1
    SET @RowCount =  @RowCount + 1

  END

  SET @cadena_script =  'FROM  ' + '@p' + LTRIM(SUBSTRING(@pTabla,4,26))
  EXEC spInsertaScript @cadena_script, @sangria1

  SELECT * FROM #LINEAMODEL
END
