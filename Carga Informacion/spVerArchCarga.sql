USE [CARGADOR]
GO
/****** Object:  StoredProcedure [dbo].[spVerArchCarga]    Script Date: 29/12/2018 04:53:38 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spVerArchCarga')
BEGIN
  DROP  PROCEDURE spVerArchCarga
END
GO
--EXEC spVerArchCarga 1,1,'MARIO',1,'CU',20,'29122018',0,' ',' ',' ',' '
CREATE PROCEDURE [dbo].[spVerArchCarga] 
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pCliente       int,
@pCveEmpresa    varchar(4),
@pIdFormato     int,
@pPeriodo       varchar(8),
@pBCorrecto     bit OUT,
@pPathCalc      varchar(50) OUT,
@pCveTipoArch   varchar(3) OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN

  DECLARE  @TPath  TABLE(Directory varchar(200))

  DECLARE  @id_cliente       varchar(6),
           @cve_empresa      varchar(4),
           @id_formato       varchar(6),
		   @periodo          varchar(6)

  DECLARE  @comando          varchar(200),
           @nom_archivo      varchar(100),
           @cve_tipo_archivo varchar(3),
           @existe           int = 0,
		   @path             nvarchar(200)

  DECLARE  @k_verdadero      bit = 1

  IF EXISTS(SELECT 1 FROM FC_FORMATO WHERE 
  ID_CLIENTE  = @pCliente     AND
  CVE_EMPRESA = @pCveEmpresa  AND
  ID_FORMATO  = @pIdFormato)
  BEGIN
    SELECT 'SI EXISTE'
    SET @id_cliente = replicate ('0',(06 - len(@pCliente))) + CONVERT(VARCHAR, @pCliente)
    SET @id_formato = replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato)
    SET @cve_empresa = @pCveEmpresa

    SELECT @nom_archivo = NOM_ARCHIVO, @cve_tipo_archivo = CVE_TIPO_ARCHIVO,
	       @path = PATHS
    FROM FC_FORMATO WHERE 
    ID_CLIENTE  = @pCliente    AND
    CVE_EMPRESA = @pCveEmpresa AND
    ID_FORMATO  = @pIdFormato

    --INSERT INTO @TPath 
    --EXEC master.dbo.xp_subdirs  @path

    --IF (SELECT COUNT(*) FROM @TPath where Directory = @id_cliente) = 0
    --BEGIN
    --  SET @comando = 'MD ' + @path + @id_cliente
    --  EXEC xp_cmdshell @comando
    --END

    --DELETE FROM @TPath

    SET @path = @path + @id_cliente

    --INSERT INTO @TPath 
    --EXEC master.dbo.xp_subdirs  @path
   
    --IF (SELECT COUNT(*) FROM @TPath where Directory = @cve_empresa) = 0
    --BEGIN
    --  SET @comando = 'MD ' + @path + '\' + @cve_empresa
    --  EXEC xp_cmdshell @comando
    --END

    --DELETE FROM @TPath

    SET @path = @path + '\' + @cve_empresa
    --INSERT INTO @TPath 
    --EXEC master.dbo.xp_subdirs  @path

    --IF (SELECT COUNT(*) FROM @TPath where Directory = @id_formato) = 0
    --BEGIN
    --  SET @comando = 'MD ' + @path + '\' + @id_formato
    --  EXEC xp_cmdshell @comando
    --END

    SET  @nom_archivo = LTRIM(@nom_archivo + @pPeriodo + '.' + @cve_tipo_archivo)
    SET  @pPathCalc = @path + '\' + @id_formato + '\' + @nom_archivo
    SELECT @pPathCalc

    --EXEC master.dbo.xp_fileexist @pPathCalc, 
    --@existe OUTPUT
    --IF  @existe  =  1
    --BEGIN
    --  SET @comando = 'DEL ' + @pPathCalc
    --  SELECT @comando
    --  EXEC xp_cmdshell @comando
    --END
    SET @pBCorrecto    = @k_verdadero
	SET @pCveTipoArch  = @cve_tipo_archivo
  END
END
