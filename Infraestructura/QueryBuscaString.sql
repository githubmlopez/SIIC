USE ADMON01
GO

-- obtiene programas de la BD que contengan la cadena indicado
SELECT  obj.object_id,
        obj.name,
        obj.type,
        obj.type_desc,
        mod.definition  AS src
  FROM sys.sql_modules  AS  mod
  JOIN sys.objects      AS  obj ON mod.object_id = obj.object_id
WHERE mod.definition LIKE '%CI_BMX_ACUM_REF%';

