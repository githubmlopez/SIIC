USE CARGADOR
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spObtCampoTxt')
BEGIN
  DROP  PROCEDURE spObtCampoTxt
END
GO
-- exec spCargaBloqCsv 1,1,'MARIO', 1, 'CU',1,'201804', ' ', ' '
CREATE PROCEDURE [dbo].[spObtCampoTxt]
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pIdFormato     int,
@pRowFile       varchar(max),
@pTipoCampo     varchar(1), 
@pPosIni        int,
@pPosFin        int,
@pCampo         varchar(max) OUT, 
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE  @k_falso          bit          = 0,
           @k_verdadero      bit          = 1,
		   @k_numero         varchar(1)   = 'N',
		   @k_caracter       varchar(1)   = 'C'

  SET @pCampo  = SUBSTRING(@pRowFile,@pPosIni,@pPosFin)
  
  IF  @pTipoCampo  =  @k_numero
  BEGIN 
    SET @pCampo  =  isnull(@pCampo,0)
    SET @pCampo  =  REPLACE(@pCampo,' ','0')
	SET @pCampo  =  REPLACE(@pCampo,',','')
	SET @pCampo  =  REPLACE(@pCampo,'$','')
  END

END
