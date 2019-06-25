USE [DICCIONARIO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--DELETE FROM DICCIONARIO.dbo.FC_CONSTR_CAMPO

--DELETE FROM DICCIONARIO.dbo.FC_CONSTRAINT

--DELETE FROM DICCIONARIO.dbo.FC_TABLA_COLUMNA

--DELETE FROM DICCIONARIO.dbo.FC_TABLA

--GO

--DELETE FROM DICCIONARIO.dbo.FC_TABLA_EX
--EXEC spCreaDiccionario ADMON01
ALTER PROCEDURE  [dbo].[spCreaDiccionario]  
@pBaseDatos varchar(15)
AS
BEGIN
  DECLARE  @k_llave_unica      varchar(2) = 'UQ',
           @k_llave_primaria   varchar(2) = 'PK',
	  	   @k_indice           varchar(2) = 'IX',
		   @k_llave_foranea    varchar(2) = 'FK',
		   @k_llave_unica_sql  varchar(6) = 'UNIQUE',
		   @k_verdadero_sql    varchar(3) = 'YES'

-- INSERTA INFORMACION DE TABLAS

  INSERT INTO DICCIONARIO.dbo.FC_TABLA
  SELECT @pBaseDatos, TABLE_NAME, ' ' FROM ADMON01.INFORMATION_SCHEMA.TABLES 
--  WHERE TABLE_NAME <> 'sysdiagrams'

-- INSERTA INFORMACION DE COLUMNAS EN LAS TABLAS

  INSERT INTO DICCIONARIO.dbo.FC_TABLA_COLUMNA
  SELECT
  @pBaseDatos,
  c.TABLE_NAME,
  c.COLUMN_NAME,
  DATA_TYPE,
  ISNULL(c.CHARACTER_MAXIMUM_LENGTH,0),
  ISNULL(c.NUMERIC_PRECISION,0),
  ISNULL(c.NUMERIC_SCALE,0),
  ISNULL(c.ORDINAL_POSITION,0),
  CASE
  WHEN  c.IS_NULLABLE = @k_verdadero_sql
  THEN  1
  ELSE  0
  END,
  0 
  FROM ADMON01.INFORMATION_SCHEMA.COLUMNS c

-- Inserta Constrains llaves unicas, llaves primarias, llaves foraneas e Indices

  INSERT INTO DICCIONARIO.dbo.FC_CONSTRAINT
  SELECT DISTINCT
  @pBaseDatos, s2.name as TABLA, s3.name AS CONTR, so.name REFERENCIA, @k_llave_foranea as TIPO_LLAVE,
  ' ', ' '
  FROM ADMON01.sys.foreign_key_columns as fk,
  ADMON01.sys.objects so, ADMON01.sys.objects s2, ADMON01.sys.objects s3   
  WHERE  fk.referenced_object_id  =  so.object_id  and
       fk.parent_object_id      =  s2.object_id  and
       fk.constraint_object_id  =  s3.object_id 
  UNION
  SELECT @pBaseDatos, so.name as TABLA, fk.name AS CONTR, ' ',
  CASE 
  WHEN SUBSTRING(fk.name,1,2) = @k_indice and SUBSTRING(fk.type_desc,1,6) = @k_llave_unica_sql
  THEN @k_llave_unica 
  WHEN SUBSTRING(fk.name,1,2) = @k_indice and SUBSTRING(fk.type_desc,1,6) <> @k_llave_unica_sql
  THEN @k_indice 
  ELSE @k_llave_primaria 
  END as TIPO_LLAVE, ' ',' '
  FROM ADMON01.sys.key_constraints as fk,
  ADMON01.sys.objects so
  WHERE  fk.parent_object_id      =  so.object_id  

-- Inserta Campos de Constrains llaves unicas, llaves primarias, e Indices

  INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO
  SELECT @pBaseDatos, c.NOM_TABLA, c.NOM_CONSTRAINT, kc.COLUMN_NAME, ' '
  FROM ADMON01.INFORMATION_SCHEMA.KEY_COLUMN_USAGE kc, DICCIONARIO.dbo.FC_CONSTRAINT c
  WHERE 
  kc.CONSTRAINT_NAME = c.NOM_CONSTRAINT and c.TIPO_LLAVE IN (@k_llave_primaria, @k_llave_unica,@k_indice) ORDER BY 
  CONSTRAINT_NAME, TABLE_NAME, ORDINAL_POSITION

-- Inserta Campos de Constrains llaves Foraneas

  INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO
  SELECT @pBaseDatos, s2.name as TABLA, s3.name AS CONTR, ci.COLUMN_NAME, ci2.COLUMN_NAME 
  FROM ADMON01.sys.foreign_key_columns as fk,
  ADMON01.sys.objects so, ADMON01.sys.objects s2, ADMON01.sys.objects s3, ADMON01.INFORMATION_SCHEMA.COLUMNS ci, ADMON01.INFORMATION_SCHEMA.COLUMNS ci2  
  WHERE  fk.referenced_object_id  =  so.object_id  and
         fk.parent_object_id      =  s2.object_id  and
         fk.constraint_object_id  =  s3.object_id  and
         ci.TABLE_NAME            =  s2.name       and
         ci.ORDINAL_POSITION      =  fk.parent_column_id and
         ci2.TABLE_NAME           =  so.name       and
         ci2.ORDINAL_POSITION     =  fk.referenced_column_id 

-- Incorpora Información a tablas de Metadatos tablas

  MERGE DICCIONARIO.dbo.FC_TABLA_EX AS tx
  USING DICCIONARIO.dbo.FC_TABLA AS t
  ON (t.BASE_DATOS = tx.BASE_DATOS AND t.NOM_TABLA = tx.NOM_TABLA) 
  WHEN NOT MATCHED BY TARGET  
       THEN INSERT(BASE_DATOS, NOM_TABLA, DESC_TABLA, SINONIMO)
       VALUES(@pBaseDatos, t.NOM_TABLA, ' ', ' ');

-- Incorpora Información a tablas de Metadatos columnas
       
  --MERGE DICCIONARIO.dbo.FC_TABLA_COL_EX AS tx
  --USING DICCIONARIO.dbo.FC_TABLA_COLUMNA AS t
  --ON (t.NOM_TABLA = tx.NOM_TABLA AND t.NOM_CAMPO = tx.NOM_CAMPO) 
  --WHEN NOT MATCHED BY TARGET  
  --    THEN INSERT(NOM_TABLA, NOM_CAMPO, DESC_CAMPO, ETIQUETA, B_CAPTURA, B_BUSCADOR)
  --    VALUES(t.NOM_TABLA, t.NOM_CAMPO, NULL, NULL,0,0);

  EXEC spCreaSinonimo

-- Indica campos identity de la tabla

  UPDATE FC_TABLA_COLUMNA SET B_IDENTITY = 1 WHERE EXISTS 
  (SELECT 1 FROM ADMON01.sys.objects o, ADMON01.sys.identity_columns i
  WHERE i.object_id  =  o.object_id  AND
        o.name  =  FC_TABLA_COLUMNA.NOM_TABLA  AND
	    i.name  =  FC_TABLA_COLUMNA.NOM_CAMPO)

END

