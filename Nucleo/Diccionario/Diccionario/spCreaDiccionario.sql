USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--DELETE FROM DICCIONARIO.dbo.FC_TABLA_EX
--EXEC spCreaDiccionario DICCIONARIO
ALTER PROCEDURE  [dbo].[spCreaDiccionario]  
@pBaseDatos varCHAR(15)
AS
BEGIN
  DECLARE  @SQL     varCHAR(MAX),
           @version int

  DECLARE  @k_llave_unica      varCHAR(2)  = 'UQ',
           @k_llave_primaria   varCHAR(2)  = 'PK',
	  	   @k_indice           varCHAR(2)  = 'IX',
		   @k_llave_foranea    varCHAR(2)  = 'FK',
		   @k_llave_unica_sql  varCHAR(6)  = 'UNIQUE',
		   @k_verdadero_sql    varCHAR(3)  = 'YES',
		   @k_espacio          varCHAR(1)  = ' ',
		   @k_tabla_sistema    varCHAR(11) = 'sysdiagrams',
		   @k_falso            bit         = 0

  SELECT   @version = MAX(ULT_VERSION) FROM FC_BASE_DATOS  WHERE  B_PROTEGIDA = @k_falso

  SET @version = isnull(@version,0)

  IF  @version  <>  0
  BEGIN

  SET @SQL =  
  'DELETE FROM DICCIONARIO.dbo.FC_CONSTR_CAMPO WHERE BASE_DATOS = ' + CHAR(39) + @pBaseDatos + CHAR(39) +
  ' AND VERSION =  ' + CONVERT(varchar(3), @version) 
  EXEC (@SQL)

  SET @SQL =  
  'DELETE FROM DICCIONARIO.dbo.FC_CONSTRAINT WHERE BASE_DATOS = ' + CHAR(39) + @pBaseDatos + CHAR(39) +
  ' AND VERSION =  ' + CONVERT(varchar(3), @version) 
  EXEC (@SQL)

  SET @SQL =  
  'DELETE FROM DICCIONARIO.dbo.FC_TABLA_COLUMNA WHERE BASE_DATOS = ' + CHAR(39) + @pBaseDatos + CHAR(39) +
  ' AND VERSION =  ' + CONVERT(varchar(3), @version) 
  EXEC (@SQL)

  SET @SQL =  
  'DELETE FROM DICCIONARIO.dbo.FC_TABLA WHERE BASE_DATOS = ' + CHAR(39) + @pBaseDatos + CHAR(39) +
  ' AND VERSION =  ' + CONVERT(varchar(3), @version) 
  EXEC (@SQL)

-- INSERTA INFORMACION DE TABLAS

  SET  @SQL = 
  'INSERT INTO DICCIONARIO.dbo.FC_TABLA ' +
  'SELECT ' +   CHAR(39) + @pBaseDatos  + CHAR(39) + ', ' + CONVERT(varchar(3), @version) + ', TABLE_NAME ' + ' FROM ' +
  @pBaseDatos + '.INFORMATION_SCHEMA.TABLES ' + 
  'WHERE TABLE_NAME <> ' +  CHAR(39) + @k_tabla_sistema + CHAR(39)

  EXEC (@SQL)

-- INSERTA INFORMACION DE COLUMNAS EN LAS TABLAS

  SET @SQL = 
  'INSERT INTO DICCIONARIO.dbo.FC_TABLA_COLUMNA ' +
  'SELECT ' + CHAR(39) +   @pBaseDatos + CHAR(39) + ', ' + CONVERT(varchar(3), @version) + ', ' +
  'c.TABLE_NAME,' +
  'c.COLUMN_NAME,' +
  'DATA_TYPE,' +
  'ISNULL(c.CHARACTER_MAXIMUM_LENGTH,0),' +
  'ISNULL(c.NUMERIC_PRECISION,0),' +
  'ISNULL(c.NUMERIC_SCALE,0),' +
  'ISNULL(c.ORDINAL_POSITION,0),' +
  'CASE ' +
  'WHEN  c.IS_NULLABLE = ' + CHAR(39) + @k_verdadero_sql + CHAR(39) +
  'THEN  1 ' +
  'ELSE  0 ' +
  'END, ' +
  '0 ' +
  'FROM ' + @pBaseDatos + '.INFORMATION_SCHEMA.COLUMNS c  WHERE c.TABLE_NAME <> ' + CHAR(39) +  @k_tabla_sistema + CHAR(39) 

  EXEC (@SQL)

-- Inserta Constrains llaves unicAS, llaves primariAS, llaves foraneAS e Indices

  SET @SQL  = 

  'INSERT INTO DICCIONARIO.dbo.FC_CONSTRAINT ' +
  'SELECT DISTINCT ' + CHAR(39) +   @pBaseDatos + CHAR(39) + ', ' + CONVERT(varchar(3), @version) +
  ', s2.name AS TABLA, s3.name AS CONTR, so.name REFERENCIA, ' + CHAR(39) +  @k_llave_foranea + CHAR(39) + ' AS TIPO_LLAVE,' +
  CHAR(39) + @k_espacio + CHAR(39) + ',' +  CHAR(39) + @k_espacio + CHAR(39) +
  ' FROM ' + @pBaseDatos + '.sys.foreign_key_columns AS fk, ' +
  @pBaseDatos + '.sys.objects so, ' + @pBaseDatos + '.sys.objects s2, ' + @pBaseDatos + '.sys.objects s3' +   
  ' WHERE  fk.referenced_object_id  =  so.object_id  AND ' +
  'fk.parent_object_id      =  s2.object_id  AND ' +
  'fk.constraint_object_id  =  s3.object_id AND s2.name <> ' + CHAR(39) + @k_tabla_sistema + CHAR(39) +
  ' UNION ' +
  'SELECT ' + CHAR(39) + @pBaseDatos + CHAR(39) + ', ' + CONVERT(varchar(3), @version) + 
  ' ,so.name AS TABLA, fk.name AS CONTR,' + CHAR(39) + @k_espacio + CHAR(39) + ', ' +
  'CASE ' + 
  'WHEN SUBSTRING(fk.name,1,2) = ' + CHAR(39) + @k_indice + CHAR(39) + ' AND SUBSTRING(fk.type_desc,1,6) = ' + CHAR(39) + @k_llave_unica_sql + CHAR(39) +
  ' THEN ' + CHAR(39) + @k_llave_unica + CHAR(39) + 
  ' WHEN SUBSTRING(fk.name,1,2) = ' + CHAR(39) + @k_indice + CHAR(39) + ' AND SUBSTRING(fk.type_desc,1,6) <> ' + CHAR(39) + @k_llave_unica_sql + CHAR(39) +
  ' THEN ' + CHAR(39) + @k_indice + CHAR(39) + 
  ' ELSE ' + CHAR(39) + @k_llave_primaria + CHAR(39) + 
  ' END AS TIPO_LLAVE,' + CHAR(39) + @k_espacio + CHAR(39) + ',' + CHAR(39) + @k_espacio + CHAR(39) +
  ' FROM ' + @pBaseDatos + '.sys.key_constraints AS fk, ' +
  @pBaseDatos + '.sys.objects so' +
  ' WHERE  fk.parent_object_id =  so.object_id  AND  so.name <> ' + CHAR(39) + @k_tabla_sistema + CHAR(39)

  EXEC (@SQL)

-- Inserta Campos de Constrains llaves unicAS, llaves primariAS, e Indices

  SET  @SQL  =
  'INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO ' +
  ' SELECT ' + CHAR(39) + @pBaseDatos + CHAR(39) + ', ' + CONVERT(varchar(3), @version) +
  ',' + 'kc.TABLE_NAME, kc.CONSTRAINT_NAME, kc.COLUMN_NAME, ' + CHAR(39) + @k_espacio + CHAR(39) +
  ', ORDINAL_POSITION '  +
  ' FROM ' + @pBaseDatos + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE kc, DICCIONARIO.dbo.FC_CONSTRAINT c' +
  ' WHERE' + 
  ' kc.CONSTRAINT_NAME = c.NOM_CONSTRAINT AND c.TIPO_LLAVE IN (' +
  CHAR(39) + @k_llave_primaria + CHAR(39) + ',' + 
  CHAR(39) + @k_llave_unica + CHAR(39) + ',' +
  CHAR(39) + @k_indice + CHAR(39) + ') AND kc.TABLE_NAME <> ' + CHAR(39) + @k_tabla_sistema + CHAR(39) + 
  ' ORDER BY ' + 
  'CONSTRAINT_NAME, TABLE_NAME, ORDINAL_POSITION'

  EXEC (@SQL)

-- Inserta Campos de Constrains llaves ForaneAS

  SET @SQL  =
  'INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO ' +
  'SELECT ' + CHAR(39) + @pBaseDatos + CHAR(39) + ', ' + CONVERT(varchar(3), @version) +
  ', s2.name AS TABLA, s3.name AS CONTR, ci.COLUMN_NAME, ci2.COLUMN_NAME, ci.ORDINAL_POSITION ' +
  'FROM ADMON01.sys.foreign_key_columns AS fk, ' +
  @pBaseDatos + '.sys.objects so,' +
  @pBaseDatos + '.sys.objects s2,' +
  @pBaseDatos + '.sys.objects s3,' +
  @pBaseDatos + '.INFORMATION_SCHEMA.COLUMNS ci,' +
  @pBaseDatos + '.INFORMATION_SCHEMA.COLUMNS ci2 ' +  
  'WHERE  fk.referenced_object_id  =  so.object_id  AND ' +
  'fk.parent_object_id      =  s2.object_id  AND ' +
  'fk.constraint_object_id  =  s3.object_id  AND ' +
  'ci.TABLE_NAME            =  s2.name       AND ' +
  'ci.ORDINAL_POSITION      =  fk.parent_column_id AND ' +
  'ci2.TABLE_NAME           =  so.name       AND ' +
  'ci2.ORDINAL_POSITION     =  fk.referenced_column_id AND ' +
  's2.name                 <>  ' + CHAR(39) + @k_tabla_sistema + CHAR(39)

  EXEC(@SQL)

-- Incorpora Información a tablAS de Metadatos tablAS

  MERGE DICCIONARIO.dbo.FC_TABLA_EX AS tx
  USING DICCIONARIO.dbo.FC_TABLA AS t
  ON (t.BASE_DATOS = tx.BASE_DATOS AND t.NOM_TABLA = tx.NOM_TABLA) 
  WHEN NOT MATCHED BY TARGET  
       THEN INSERT(BASE_DATOS, NOM_TABLA, DESC_TABLA, SINONIMO)
       VALUES(@pBaseDatos, t.NOM_TABLA, ' ', ' ');

-- Incorpora Información a tablAS de Metadatos columnAS
       
  --MERGE DICCIONARIO.dbo.FC_TABLA_COL_EX AS tx
  --USING DICCIONARIO.dbo.FC_TABLA_COLUMNA AS t
  --ON (t.NOM_TABLA = tx.NOM_TABLA AND t.NOM_CAMPO = tx.NOM_CAMPO) 
  --WHEN NOT MATCHED BY TARGET  
  --    THEN INSERT(NOM_TABLA, NOM_CAMPO, DESC_CAMPO, ETIQUETA, B_CAPTURA, B_BUSCADOR)
  --    VALUES(t.NOM_TABLA, t.NOM_CAMPO, NULL, NULL,0,0);

  EXEC spCreaSinonimo

-- Indica campos identity de la tabla

  SET @SQL  =
  'UPDATE FC_TABLA_COLUMNA SET B_IDENTITY = 1 WHERE EXISTS ' +
  '(SELECT 1 FROM ' + 
  @pBaseDatos + '.sys.objects o,' +
  @pBaseDatos + '.sys.identity_columns i ' +
  'WHERE i.object_id  =  o.object_id  AND ' +
  'o.name  =  FC_TABLA_COLUMNA.NOM_TABLA  AND ' +
  'i.name  =  FC_TABLA_COLUMNA.NOM_CAMPO)'

  EXEC(@SQL)

  END
END

