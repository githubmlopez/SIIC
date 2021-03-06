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

--DELETE FROM DICCIONARIO.dbo.FC_TABLA_COL_EX

--DELETE FROM DICCIONARIO.dbo.FC_TABLA_EX

CREATE PROCEDURE  [dbo].[spCreaDiccionario]  
AS
BEGIN

  DECLARE  @k_llave_unica      varchar(2) = 'UQ',
           @k_llave_primaria   varchar(2) = 'PK',
	  	   @k_indice           varchar(2) = 'IX',
		   @k_llave_foranea    varchar(2) = 'FK',
		   @k_llave_unica_sql  varchar(6) = 'UNIQUE',
		   @k_verdadero_sql    varchar(3) = 'YES'

-- INSERTA INFORMACION DE TABLAS

  INSERT INTO DICCIONARIO.dbo.FC_TABLA  SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 

-- INSERTA INFORMACION DE COLUMNAS EN LAS TABLAS

  INSERT INTO DICCIONARIO.dbo.FC_TABLA_COLUMNA
  SELECT c.TABLE_NAME, c.COLUMN_NAME,DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.NUMERIC_PRECISION, c.NUMERIC_SCALE, c.ORDINAL_POSITION,
  CASE
  WHEN  c.IS_NULLABLE = @k_verdadero_sql
  THEN  1
  ELSE  0
  END 
  FROM INFORMATION_SCHEMA.COLUMNS c

-- Inserta Constrains llaves unicas, llaves primarias, llaves foraneas e Indices

  INSERT INTO DICCIONARIO.dbo.FC_CONSTRAINT
  select distinct s2.name as TABLA, s3.name AS CONTR, so.name REFERENCIA, @k_llave_foranea as TIPO_LLAVE
  from sys.foreign_key_columns as fk,
  sys.objects so, sys.objects s2, sys.objects s3   
  where  fk.referenced_object_id  =  so.object_id  and
       fk.parent_object_id      =  s2.object_id  and
       fk.constraint_object_id  =  s3.object_id 
  UNION
  select so.name as TABLA, fk.name AS CONTR, null ,
  CASE 
  WHEN substring(fk.name,1,2) = @k_indice and SUBSTRING(fk.type_desc,1,6) = @k_llave_unica_sql
  THEN @k_llave_unica 
  WHEN substring(fk.name,1,2) = @k_indice and SUBSTRING(fk.type_desc,1,6) <> @k_llave_unica_sql
  THEN @k_indice 
  ELSE @k_llave_primaria 
  END as TIPO_LLAVE
  from SYS.key_constraints as fk,
  sys.objects so
  where  fk.parent_object_id      =  so.object_id

-- Inserta Campos de Constrains llaves unicas, llaves primarias, e Indices

  INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO
  SELECT c.NOM_TABLA, c.NOM_CONSTRAINT, kc.COLUMN_NAME, null
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kc, DICCIONARIO.dbo.FC_CONSTRAINT c
  WHERE 
  kc.CONSTRAINT_NAME = c.NOM_CONSTRAINT and c.TIPO_LLAVE IN (@k_llave_primaria, @k_llave_unica,@k_indice) ORDER BY 
  CONSTRAINT_NAME, TABLE_NAME, ORDINAL_POSITION

-- Inserta Campos de Constrains llaves Foraneas

  INSERT INTO DICCIONARIO.dbo.FC_CONSTR_CAMPO
  select s2.name as TABLA, s3.name AS CONTR, ci.COLUMN_NAME, ci2.COLUMN_NAME 
  from sys.foreign_key_columns as fk,
  sys.objects so, sys.objects s2, sys.objects s3, INFORMATION_SCHEMA.COLUMNS ci, INFORMATION_SCHEMA.COLUMNS ci2  
  where  fk.referenced_object_id  =  so.object_id  and
         fk.parent_object_id      =  s2.object_id  and
         fk.constraint_object_id  =  s3.object_id  and
         ci.TABLE_NAME            =  s2.name       and
         ci.ORDINAL_POSITION      =  fk.parent_column_id and
         ci2.TABLE_NAME           =  so.name       and
         ci2.ORDINAL_POSITION     =  fk.referenced_column_id 

-- Incorpora Informaci?n a tablas de Metadaros tablas

  MERGE DICCIONARIO.dbo.FC_TABLA_EX AS tx
  USING DICCIONARIO.dbo.FC_TABLA AS t
  ON (t.NOM_TABLA = tx.NOM_TABLA) 
  WHEN NOT MATCHED BY TARGET  
       THEN INSERT(NOM_TABLA, DESC_TABLA, SINONIMO)
       VALUES(t.NOM_TABLA, NULL, NULL);

-- Incorpora Informaci?n a tablas de Metadaros columnas
       
  MERGE DICCIONARIO.dbo.FC_TABLA_COL_EX AS tx
  USING DICCIONARIO.dbo.FC_TABLA_COLUMNA AS t
  ON (t.NOM_TABLA = tx.NOM_TABLA AND t.NOM_CAMPO = tx.NOM_CAMPO) 
  WHEN NOT MATCHED BY TARGET  
      THEN INSERT(NOM_TABLA, NOM_CAMPO, DESC_CAMPO, ETIQUETA, B_CAPTURA, B_BUSCADOR)
      VALUES(t.NOM_TABLA, t.NOM_CAMPO, NULL, NULL,0,0);
END



