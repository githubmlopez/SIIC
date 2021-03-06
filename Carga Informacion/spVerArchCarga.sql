USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spVerArchCarga]    Script Date: 29/12/2018 04:53:38 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spVerArchCarga')
BEGIN
  DROP  PROCEDURE spVerArchCarga
END
GO
--EXEC spVerArchCarga 1,1,'MARIO',1,'CU','CARGAINF','201811',0,0,' ',' ',' ',' ',' ',' '
CREATE PROCEDURE [dbo].[spVerArchCarga] 
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pTipoInfo      int,
@pIdBloque      int,
@pIdFormato     int,
@pCveCorrecto   int OUT,
@pPathCalc      varchar(100) OUT,
@pCveTipoArch   varchar(3) OUT,
@pExtension     varchar(10) OUT,
@pBSeparador    bit OUT,
@pCarSepara     varchar(1) OUT,
@pNum_campos    int OUT,
@pBError         bit OUT,
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
  FROM FC_TIPO_INFORMACION i, FC_CARGA_RENG_ENCA e, FC_FORMATO f, FC_ARCHIVO a, FC_ARCHIVO_EXEC x WHERE 
  i.CVE_EMPRESA      = @pCveEmpresa       AND
  i.TIPO_INFORMACION = @pTipoInfo         AND
  i.CVE_EMPRESA      = e.CVE_EMPRESA      AND
  i.TIPO_INFORMACION = e.TIPO_INFORMACION AND
  e.ID_BLOQUE        = @pIdBloque         AND
  e.CVE_EMPRESA      = f.CVE_EMPRESA      AND
  e.TIPO_INFORMACION = f.TIPO_INFORMACION AND
  e.ID_BLOQUE        = f.ID_BLOQUE        AND
  f.CVE_EMPRESA      = i.CVE_EMPRESA      AND
  f.ID_FORMATO       = @pIdFormato        AND
  a.CVE_EMPRESA      = f.CVE_EMPRESA      AND
  a.CVE_ARCHIVO      = f.CVE_ARCHIVO      AND
  x.CVE_EMPRESA      = a.CVE_EMPRESA      AND
  x.CVE_ARCHIVO      = a.CVE_ARCHIVO      AND
  x.ANO_MES          = @pAnoPeriodo
  ) > 0
  BEGIN 

	SET  @pCveCorrecto  =  @k_verdadero
    SELECT @nom_archivo = a.NOM_ARCHIVO, @pCveTipoArch = i.CVE_TIPO_ARCHIVO, @pNum_campos = e.NUM_CAMPOS,
	       @pExtension = i.EXTENSION, @path = x.RUTA_RDS, @pBSeparador = i.B_SEPARADOR, @pCarSepara = i.CAR_SEPARA
    FROM FC_TIPO_INFORMACION i, FC_CARGA_RENG_ENCA e, FC_FORMATO f, FC_ARCHIVO a, FC_ARCHIVO_EXEC x WHERE 
    i.CVE_EMPRESA      = @pCveEmpresa       AND
    i.TIPO_INFORMACION = @pTipoInfo         AND
    i.CVE_EMPRESA      = e.CVE_EMPRESA      AND
    i.TIPO_INFORMACION = e.TIPO_INFORMACION AND
    e.ID_BLOQUE        = @pIdBloque         AND
    e.CVE_EMPRESA      = f.CVE_EMPRESA      AND
    e.TIPO_INFORMACION = f.TIPO_INFORMACION AND
    e.ID_BLOQUE        = f.ID_BLOQUE        AND
    f.CVE_EMPRESA      = i.CVE_EMPRESA      AND
    f.ID_FORMATO       = @pIdFormato        AND
    a.CVE_EMPRESA      = f.CVE_EMPRESA      AND
    a.CVE_ARCHIVO      = f.CVE_ARCHIVO      AND
    x.CVE_EMPRESA      = a.CVE_EMPRESA      AND
    x.CVE_ARCHIVO      = a.CVE_ARCHIVO      AND
    x.ANO_MES          = @pAnoPeriodo

	SET  @pPathCalc = @path

    IF  @pCveTipoArch = @k_directorio 
    BEGIN 
      SET @path =  @path + 
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdCliente))) + CONVERT(VARCHAR, @pIdCliente))) + '\' +
	  @pCveEmpresa + '\' +
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pTipoInfo))) + CONVERT(VARCHAR, @pTipoInfo)))  + '\' + 
      CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato))) 
      SET @pPathCalc  = @path + '\' + @pAnoPeriodo
    END
END

END