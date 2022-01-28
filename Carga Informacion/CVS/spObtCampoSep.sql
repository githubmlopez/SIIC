USE ADMON01
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtCampoSep')
BEGIN
  DROP  PROCEDURE spObtCampoSep
END
GO
-- exec spspObtCampoSep 1,1,'MARIO', 1, 'CU',1,'201804', ' ', ' '
CREATE PROCEDURE [dbo].[spObtCampoSep]
(
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pCodigoUsuario  varchar(20),
@pCveAplicacion  varchar(10),
@pAnoPeriodo     varchar(8),
@pIdProceso      numeric(9),
@pFolioExe       int,
@pIdTarea        numeric(9),
@pRowFile       varchar(max),
@pTipoCampo     varchar(1),
@pSeparador     varchar(1), 
@pCampo         varchar(max) OUT,
@pPosicion      int OUT,
@pRowFileo      varchar(max) OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE  @b_despliega  bit
  
  DECLARE  @k_delimitador    varchar(1),
           @k_falso          bit          = 0,
           @k_verdadero      bit          = 1,
		   @k_numero         varchar(1)   = 'N',
		   @k_caracter       varchar(1)   = 'C'

  SET @b_despliega = 1  

  SET @pPosicion = 0
  IF  SUBSTRING(@pRowFile,1,1) = char(34)
  BEGIN
 	SET @k_delimitador = char(34)
	SET @pRowFile  = SUBSTRING(@pRowFile,2,LEN(@pRowFile))
	SET @pPosicion    = CHARINDEX(@k_delimitador, @pRowFile)
    SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowFile,1,@pPosicion - 1)))
	SET @pRowFileo  = SUBSTRING(@pRowFile,@pPosicion + 2,LEN(@pRowFile))
  END
  ELSE
  BEGIN
 	SET @pPosicion    = CHARINDEX(@pSeparador, @pRowFile)
	IF  @pPosicion <> 0
	BEGIN
	  SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowFile,1,@pPosicion - 1)))
	  SET @pRowFileo  = SUBSTRING(@pRowFile,@pPosicion + 1,LEN(@pRowFile))
	END
    ELSE
    BEGIN
	  SET @pCampo = ' '
	END
  END
  
  IF  @pTipoCampo  =  @k_numero
  BEGIN 
    SET @pCampo  =  isnull(@pCampo,0)
    SET @pCampo  =  REPLACE(@pCampo,' ','0')
	SET @pCampo  =  REPLACE(@pCampo,',','')
	SET @pCampo  =  REPLACE(@pCampo,'$','')
  END

END
