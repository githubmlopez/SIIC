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
@pTipoInfo      int,
@pIdBloque      int,
@pIdFormato     int,
@pCveCorrecto   int OUT,
@pPathCalc      varchar(100) OUT,
@pCveTipoArch   varchar(3) OUT,
@pBSeparador    bit OUT,
@pCarSepara     varchar(1) OUT,
@pNum_campos    int OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE  @TDummy  TABLE(dummy varchar(200))

  DECLARE  @periodo          varchar(6),
		   @resultado        int

  DECLARE  @comando          varchar(200),
           @nom_archivo      varchar(100),
           @existe           int = 0,
		   @path             nvarchar(100)

  DECLARE  @k_verdadero      bit =        1,
           @k_directorio     varchar(3) = 'DIR',
		   @k_correcto       int        = 1,
		   @k_no_formato     int        = 2,
		   @k_no_archivo     int        = 3
  
  IF  
 (
  SELECT COUNT(*)
  FROM FC_TIPO_INFORMACION i, FC_CARGA_RENG_ENCA e, FC_FORMATO f WHERE 
  i.ID_CLIENTE       = @pIdCliente        AND
  i.CVE_EMPRESA      = @pCveEmpresa       AND
  i.TIPO_INFORMACION = @pTipoInfo         AND
  i.ID_CLIENTE       = e.ID_CLIENTE       AND
  i.CVE_EMPRESA      = e.CVE_EMPRESA      AND
  i.TIPO_INFORMACION = e.TIPO_INFORMACION AND
  e.ID_BLOQUE        = @pIdBloque         AND
  e.ID_CLIENTE       = f.ID_CLIENTE       AND
  e.CVE_EMPRESA      = f.CVE_EMPRESA      AND
  e.TIPO_INFORMACION = f.TIPO_INFORMACION AND
  e.ID_BLOQUE        = f.ID_BLOQUE        AND
  f.ID_FORMATO       = @pIdFormato
 ) > 0
  BEGIN
    SELECT @nom_archivo = NOM_ARCHIVO, @pCveTipoArch = CVE_TIPO_ARCHIVO, @pNum_campos = NUM_CAMPOS,
	       @path = PATHS, @pBSeparador = B_SEPARADOR, @pCarSepara = CAR_SEPARA
    FROM FC_TIPO_INFORMACION i, FC_CARGA_RENG_ENCA e, FC_FORMATO f WHERE 
    i.ID_CLIENTE       = @pIdCliente        AND
    i.CVE_EMPRESA      = @pCveEmpresa       AND
    i.TIPO_INFORMACION = @pTipoInfo         AND
    i.ID_CLIENTE       = e.ID_CLIENTE       AND
    i.CVE_EMPRESA      = e.CVE_EMPRESA      AND
    i.TIPO_INFORMACION = e.TIPO_INFORMACION AND
    e.ID_BLOQUE        = @pIdBloque         AND
    e.ID_CLIENTE       = f.ID_CLIENTE       AND
    e.CVE_EMPRESA      = f.CVE_EMPRESA      AND
    e.TIPO_INFORMACION = f.TIPO_INFORMACION AND
    e.ID_BLOQUE        = f.ID_BLOQUE        AND
    f.ID_FORMATO       = @pIdFormato

    IF  @pCveTipoArch <> @k_directorio 
    BEGIN
      SET @path =  @path + 
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdCliente))) + CONVERT(VARCHAR, @pIdCliente))) + '\' +
	  @pCveEmpresa + '\' +
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pTipoInfo))) + CONVERT(VARCHAR, @pTipoInfo)))   + '\' +
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdBloque))) + CONVERT(VARCHAR, @pIdBloque)))   + '\' +
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato))) 
	  SET @nom_archivo = LTRIM(@nom_archivo + @pPeriodo + '.' + @pCveTipoArch)
      SET @pPathCalc = @path + '\' + @nom_archivo
      SELECT @pPathCalc
      EXEC master.dbo.xp_fileexist @pPathCalc, @resultado OUTPUT

    END
    ELSE
	BEGIN
      SET @path =  @path + 
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdCliente))) + CONVERT(VARCHAR, @pIdCliente))) + '\' +
	  @pCveEmpresa + '\' +
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pTipoInfo))) + CONVERT(VARCHAR, @pTipoInfo)))  + '\' + 
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato))) 
      SET @pPathCalc  = @path + '\' + @pPeriodo
      SELECT @pPathCalc
      BEGIN TRY 
        SET @resultado = 1
	    INSERT into @TDummy
		EXEC master..xp_subdirs @pPathCalc
      END TRY
      BEGIN CATCH
	    SET @resultado = 0
	  END CATCH
    END
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

