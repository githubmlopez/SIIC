USE [ADMON01]
GO

-- EXEC spVerDocumentos 1,1,'MARIO',1,'CU','DOCTOS',1,'XXXXXX',5,
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spVerDocumentos')
BEGIN
  DROP  PROCEDURE spVerDocumentos
END
GO

CREATE PROCEDURE [dbo].[spVerDocumentos]
(
@pIdProceso       numeric (9),
@pIdTarea         numeric (9),
@pCodigoUsuario   varchar (20),
@pIdCliente       int,
@pCveEmpresa      varchar (4),
@pCveAplicacion   varchar (10),
@pIdFormato       int,
@pPathName        varchar (256),
@pNumCampos       int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
  DECLARE  @CMD          varchar(512),
           @NunRegistros  int          = 0, 
		   @posicion      int          = 0,
           @RowCount      int          = 0,
		   @car_separador varchar(1)   = ' ',  
	       @row_file      varchar(max) = ' ',
	       @row_fileo     varchar(max) = ' ',
		   @num_columna   int          = 0,
		   @tipo_campo    varchar(1)   = ' ', 
           @campo         varchar(max) = ' '

  DECLARE  @k_separador   varchar(1)  =  '/'
  
  IF OBJECT_ID('tempdb..#CommandShell') IS NOT NULL
      DROP TABLE #CommandShell

  CREATE TABLE #CommandShell
 (RowId       int identity,
  Rowfile     varchar(max))
 
  SET @CMD = 'DIR ' + @pPathName 
-- Almacenar resultado del comando 
  INSERT INTO #CommandShell 
  EXEC MASTER..xp_cmdshell   @CMD 
  SELECT * FROM #CommandShell
--  Depuración de archivo 
  DELETE 
  FROM   #CommandShell 
  WHERE  Rowfile NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %' 
  OR Rowfile LIKE '%<DIR>%' 
  OR Rowfile NOT LIKE '%pdf%' 
  OR Rowfile NOT LIKE '%' + @pCveEmpresa + '%' 
  OR Rowfile is null
-- Validación de registros

  SELECT * FROM #CommandShell
   SELECT 'Docto. Invalido ==> ' + Rtrim(LTRIM(substring(Rowfile,CHARINDEX(@pCveEmpresa,Rowfile) + 7,5))) FROM  #CommandShell
   WHERE ISNUMERIC(Rtrim(LTRIM(substring(Rowfile,CHARINDEX(@pCveEmpresa,Rowfile) + 7,5)))) <> 1
 
 DELETE 
 FROM   #CommandShell 
 WHERE  ISNUMERIC(Rtrim(LTRIM(substring(Rowfile,CHARINDEX(@pCveEmpresa,Rowfile) + 7,5)))) <> 1

 SET @NunRegistros = (SELECT COUNT(*) FROM #CommandShell)

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @row_file = Rowfile
	FROM   #CommandShell
	WHERE  RowID  =		@RowCount

	IF SUBSTRING(@row_file,LEN(@row_file),LEN(@row_file)) <> @car_separador
	BEGIN
	  SET  @row_file = LTRIM(@row_file) + @car_separador
	END

    SET  @num_columna  =  1

	WHILE @pNumCampos >=  @num_columna 
	BEGIN
      IF  @num_columna  >  1
	  BEGIN
	    SET  @row_file  =  @row_fileo 
	  END

      SELECT @tipo_campo = CVE_TIPO_CAMPO
	  FROM  CARGADOR.dbo.FC_CARGA_POSIC  WHERE 
	  ID_CLIENTE  = @pIdCliente  AND
      CVE_EMPRESA = @pCveEmpresa AND
      ID_FORMATO  = @pIdFormato  AND
      ID_BLOQUE   = 1            AND
	  NUM_COLUMNA = @num_columna   

      EXEC spObtCampoSep
           @pIdProceso,
           @pIdTarea,
           @pCodigoUsuario,
           @pIdCliente,
           @pCveEmpresa,
           @pIdFormato,
           @row_file,
           @tipo_campo,
		   @k_separador, 
           @campo OUT,
		   @posicion OUT, 
           @row_fileo OUT,
           @pError OUT,
           @pMsgError OUT
      SET  @num_columna  =  @num_columna + 1
    END 
	SET @RowCount = @RowCount + 1
  END


END

