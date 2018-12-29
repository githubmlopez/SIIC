USE CARGAINF
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGAINF.sys.procedures WHERE Name =  'spObtCampoCsv')
BEGIN
  DROP  PROCEDURE spObtCampoCsv
END
GO
-- exec spCargaBloqCsv 1,1,'MARIO', 1, 'CU',1,'201804', ' ', ' '
CREATE PROCEDURE [dbo].[spObtCampoCsv]
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pIdFormato     int,
@pRowFile       varchar(max),
@pTipoCampo     varchar(1), 
@pCampo         varchar(max) OUT, 
@pRowFileo      varchar(max) OUT,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE  @b_despliega  bit
  
  DECLARE  @posicion         int
          
  DECLARE  @k_delimitador    varchar(1),
           @k_falso          bit          = 0,
           @k_verdadero      bit          = 1,
		   @k_numero         varchar(1)   = 'N',
		   @k_caracter       varchar(1)   = 'C'

  SET  @posicion       =  0
 
  SET @b_despliega = 1  

  IF  SUBSTRING(@pRowFile,1,1) = char(34)
  BEGIN
	SET @k_delimitador = char(34)
	SET @pRowFile  = SUBSTRING(@pRowFile,2,LEN(@pRowFile))
	SET @posicion    = charindex(char(34), @pRowFile)
	SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowFile,1,@posicion - 1)))
	SET @pRowFileo  = SUBSTRING(@pRowFile,@posicion + 2,LEN(@pRowFile))
  END
  ELSE
  BEGIN
	SET @k_delimitador = ','
	SET @posicion    = charindex(@k_delimitador, @pRowFile)
	SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowFile,1,@posicion- 1)))
	SET @pRowFileo  = SUBSTRING(@pRowFile,@posicion + 1,LEN(@pRowFile))
  END
  
  IF  @pTipoCampo  =  @k_numero
  BEGIN 
    SET @pCampo  =  isnull(@pCampo,0)
    SET @pCampo  =  REPLACE(@pCampo,' ','0')
	SET @pCampo  =  REPLACE(@pCampo,',','')
	SET @pCampo  =  REPLACE(@pCampo,'$','')
  END

END
