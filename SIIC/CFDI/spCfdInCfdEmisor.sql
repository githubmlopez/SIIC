USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdEmisor')
BEGIN
  DROP  PROCEDURE spCfdInCfdEmisor
END
GO
--EXEC spCfdInCfdEmisor 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdEmisor
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pHdoc            int,
@pUuid            varchar(36),
@pCveTipo         varchar(4),
@pBError          bit          OUT,
@pError           varchar(80)  OUT, 
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @seccion      varchar(20),
  		  @ruta         varchar(400)

  DECLARE @k_verdadero  varchar(1)  = '1',
          @k_error      varchar(1)  = 'E'

  BEGIN TRY

  SET @ruta = 'cfdi:Comprobante/cfdi:Emisor'

  SET @seccion  =  'Emisor'

  INSERT intO CFDI_EMISOR
 (CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  RFC_EMI,
  NOMBRE_EMI,
  REG_FISCAL_EMI
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  ISNULL(RFC_EM, ' '),
  ISNULL(NOMBRE_EM, ' '),
  ISNULL(REGIMEN_FISCAL_EM, ' ')
  FROM OPENXML(@pHDoc, @ruta,2)
  WITH 
 (
  RFC_EM            varchar(13) '@Rfc',
  NOMBRE_EM         varchar(150) '@Nombre',
  REGIMEN_FISCAL_EM varchar(3) '@RegimenFiscal'
 )

  END TRY

  BEGIN CATCH
	SET  @pError    =  '(E) CFDI  ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH


END