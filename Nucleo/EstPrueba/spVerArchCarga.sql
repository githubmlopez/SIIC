USE CARGAINF
GO
/****** Valida existencia de archivo a cargar ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGAINF.sys.procedures WHERE Name =  'spVerArchCarga')
BEGIN
  DROP  PROCEDURE spVerArchCarga
END
GO
--EXEC spVerArchCarga 1,'CU',1,'20181226'
CREATE PROCEDURE [dbo].[spVerArchCarga] 
(
@pCliente     int,
@pCveEmpresa  varchar(4),
@pIdFormato   int,
@pPeriodo     varchar(8)
)

AS
BEGIN

  DECLARE  @TPath  TABLE(Directory varchar(200))

  DECLARE  @id_cliente       varchar(6),
           @cve_empresa      varchar(4),
           @id_formato       varchar(6),
		   @periodo          varchar(6)

  SET @id_cliente = replicate ('0',(06 - len(@pCliente))) + CONVERT(VARCHAR, @pCliente)
  SET @id_formato = replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato)
  SET @cve_empresa = @pCveEmpresa

  DECLARE  @k_formatos       varchar(200) = N'c:\fmt\'

  DECLARE  @comando          varchar(200),
           @nom_archivo      varchar(100),
           @cve_tipo_archivo varchar(3),
           @existe           int = 0,
		   @path             nvarchar(200)

  SET @path = @k_formatos 

  INSERT INTO @TPath 
  EXEC master.dbo.xp_subdirs  @path

  SELECT * FROM @TPath where Directory = @id_cliente
  IF @@ROWCOUNT = 0
  BEGIN
    SET @comando = 'MD ' + @path + @id_cliente
    EXEC xp_cmdshell @comando
  END

  DELETE FROM @TPath

  SET @path = @path + @id_cliente

  INSERT INTO @TPath 
  EXEC master.dbo.xp_subdirs  @path

  SELECT * FROM @TPath where Directory = @cve_empresa
  IF @@ROWCOUNT = 0
  BEGIN
    SET @comando = 'MD ' + @path + '\' + @cve_empresa
    EXEC xp_cmdshell @comando
  END

  DELETE FROM @TPath

  SET @path = @path + '\' + @cve_empresa
  INSERT INTO @TPath 
  EXEC master.dbo.xp_subdirs  @path

  SELECT * FROM @TPath where Directory = @id_formato
  IF @@ROWCOUNT = 0
  BEGIN
    SET @comando = 'MD ' + @path + '\' + @id_formato
    EXEC xp_cmdshell @comando
  END

  IF EXISTS(SELECT 1 FROM FC_FORMATO WHERE 
  ID_CLIENTE  = @pCliente     AND
  CVE_EMPRESA = @pCveEmpresa  AND
  ID_FORMATO  = @pIdFormato)
  BEGIN
    SELECT @nom_archivo = NOM_ARCHIVO, @cve_tipo_archivo = CVE_TIPO_ARCHIVO
    FROM FC_FORMATO WHERE 
    ID_CLIENTE  = @pCliente    AND
    CVE_EMPRESA = @pCveEmpresa AND
    ID_FORMATO  = @pIdFormato
    SET  @nom_archivo = LTRIM(@nom_archivo + @pPeriodo + '.' + @cve_tipo_archivo)
    SET  @path = @path + '\' + @id_formato + '\' + @nom_archivo
--  SELECT @path
  END

  EXEC master.dbo.xp_fileexist @path, 
  @existe OUTPUT
  IF  @existe  =  1
  BEGIN
    SET @comando = @path
    EXEC xp_cmdshell @comando
  END

END