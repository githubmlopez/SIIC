USE [ADMON01]
GO

-- EXEC spVerDocDig 'C:\"Administracion Cerouno"\"Facturas Digitales"\', 'CXP'
-- EXEC spVerDocDig 'C:\"TEMP2017"\', 'CXC'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spVerDocDig]  @pPathName VARCHAR(256), @pPrefDocto VARCHAR(3)
AS
BEGIN
  DECLARE  @CMD          varchar(512)
  
  DECLARE  @k_activa     varchar(1)  =  'A',
           @k_cta_pagar  varchar(3)  =  'CXP',
		   @k_cta_cobrar varchar(3)  =  'CXC'
 
  IF OBJECT_ID('tempdb..#CommandShell') IS NOT NULL
      DROP TABLE #CommandShell

  CREATE TABLE #CommandShell ( Line VARCHAR(512)) 
 
     SET @CMD = 'DIR ' + @pPathName 
-- Almacenar resultado del comando 
     INSERT INTO #CommandShell 
     EXEC MASTER..xp_cmdshell   @CMD 

--  Depuración de archivo 
     DELETE 
     FROM   #CommandShell 
     WHERE  Line NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %' 
   OR Line LIKE '%<DIR>%' 
   OR Line NOT LIKE '%pdf%' 
   OR Line NOT LIKE '%' + @pPrefDocto + '%' 
   OR Line is null
-- Validación de registros
  SELECT * FROM #CommandShell
   select 'Docto. Invalido ==> ' + Rtrim(LTRIM(substring(Line,CHARINDEX(@pPrefDocto,Line) + 7,5))) FROM  #CommandShell
   WHERE ISNUMERIC(Rtrim(LTRIM(substring(Line,CHARINDEX(@pPrefDocto,Line) + 7,5)))) <> 1
 
 DELETE 
     FROM   #CommandShell 
     WHERE  ISNUMERIC(Rtrim(LTRIM(substring(Line,CHARINDEX(@pPrefDocto,Line) + 7,5)))) <> 1
   
  IF  @pPrefDocto  =  @k_cta_cobrar
  BEGIN
	(SELECT f.ID_CONCILIA_CXC id FROM CI_FACTURA f  WHERE f.SIT_TRANSACCION = @k_activa
    EXCEPT
    SELECT f.ID_CONCILIA_CXC id  FROM CI_FACTURA f, #CommandShell s
    WHERE  f.ID_CONCILIA_CXC  =  CONVERT(INT,Rtrim(LTRIM(substring(s.Line,CHARINDEX(@pPrefDocto,Line) + 7,5)))))
	ORDER  BY id
  END
  ELSE
  IF  @pPrefDocto  =  @k_cta_pagar
  BEGIN
    SELECT '** ENTRO A SELECT ** '
   (SELECT cp.ID_CXP id  FROM CI_CUENTA_X_PAGAR cp WHERE cp.SIT_C_X_P = @k_activa
    EXCEPT
    SELECT cp.ID_CXP id  FROM CI_CUENTA_X_PAGAR cp, #CommandShell s
    WHERE  cp.ID_CXP     =  CONVERT(INT,Rtrim(LTRIM(substring(s.Line,CHARINDEX(@pPrefDocto,Line) + 7,5)))))
	ORDER  BY id
  END

END