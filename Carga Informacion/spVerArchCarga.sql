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
--EXEC spVerArchCarga 1,1,'MARIO',1,'CU','CARGAINF','201811',0,0,' ',' ',' ',' ',' ',' '
CREATE PROCEDURE [dbo].[spVerArchCarga] 
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pPeriodo       varchar(8),
@pCveCorrecto   int OUT,
@pIdFormato     int OUT,
@pPathCalc      varchar(50) OUT,
@pCveTipoArch   varchar(3) OUT,
@pBSeparador    bit OUT,
@pCarSepara     varchar(1) OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN

  DECLARE  @TPath  TABLE(Directory varchar(200))

  DECLARE  @id_cliente       varchar(6),
           @cve_empresa      varchar(4),
           @id_formato       varchar(6),
		   @periodo          varchar(6),
		   @resultado        int

  DECLARE  @comando          varchar(200),
           @nom_archivo      varchar(100),
           @existe           int = 0,
		   @path             nvarchar(200)

  DECLARE  @k_verdadero      bit =        1,
           @k_directorio     varchar(3) = 'DIR',
		   @k_correcto       int        = 1,
		   @k_no_formato     int        = 2,
		   @k_no_archivo     int        = 3
  
  SELECT @pIdFormato  = 
  (SELECT CONVERT(INT,LTRIM(PARAMETRO)) FROM FC_GEN_PROCESO WHERE 
   ID_CLIENTE     =  @pIdCliente   AND
   CVE_EMPRESA    =  @pCveEmpresa  AND
   CVE_APLICACION =  @pCveAplicacion  AND
   ID_PROCESO     =  @pIdProceso)

  IF EXISTS(SELECT 1 FROM FC_FORMATO WHERE 
  ID_CLIENTE  = @pIdCliente     AND
  CVE_EMPRESA = @pCveEmpresa  AND
  ID_FORMATO  = @pIdFormato)
  BEGIN
--    SELECT 'SI EXISTE FORMATO', CONVERT(varchar(5),@pIdFormato) 
    SET @id_cliente = replicate ('0',(06 - len(@pIdCliente))) + CONVERT(VARCHAR, @pIdCliente)
    SET @id_formato = replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato)
    SET @cve_empresa = @pCveEmpresa

    SELECT @nom_archivo = NOM_ARCHIVO, @pCveTipoArch = CVE_TIPO_ARCHIVO,
	       @path = PATHS, @pBSeparador = B_SEPARADOR, @pCarSepara = CAR_SEPARA
    FROM FC_FORMATO WHERE 
    ID_CLIENTE  = @pIdCliente    AND
    CVE_EMPRESA = @pCveEmpresa AND
    ID_FORMATO  = @pIdFormato
 
    SET @path = @path + @id_cliente
    SET @path = @path + '\' + @cve_empresa + '\' + @id_formato

    IF  @pCveTipoArch <> @k_directorio 
    BEGIN
	  SET @nom_archivo = LTRIM(@nom_archivo + @pPeriodo + '.' + @pCveTipoArch)
      SET @pPathCalc = @path + '\' + @nom_archivo
    END
    ELSE
	BEGIN
      SET @pPathCalc  = @path 
	END
    select @pPathCalc
    EXEC master.dbo.xp_fileexist @pPathCalc, @resultado OUTPUT

	IF   @resultado  =  @k_correcto
	BEGIN
      SET @pCveCorrecto  =  @k_correcto
	END
	ELSE
	BEGIN
      SET @pCveCorrecto  =  @k_no_archivo
	END
  END
--  SELECT @pPathCalc
  ELSE
  BEGIN
    SET @pCveCorrecto  =  @k_no_formato
  END

END

   --INSERT INTO @TPath 
    --EXEC master.dbo.xp_subdirs  @path

    --IF (SELECT COUNT(*) FROM @TPath where Directory = @id_cliente) = 0
    --BEGIN
    --  SET @comando = 'MD ' + @path + @id_cliente
    --  EXEC xp_cmdshell @comando
    --END

    --DELETE FROM @TPath
