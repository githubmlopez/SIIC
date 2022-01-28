USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdObtDatos')
BEGIN
  DROP  PROCEDURE spCfdObtDatos
END
GO
--EXEC spCfdiBaseDatos 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdObtDatos
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@phdoc            int,
@pUuid            varchar(36) OUT,
@pCveTipo         varchar(4) OUT,
@pBError          bit OUT,
@pError           varchar(80) OUT, 
@pMsgError        varchar(400) OUT

)
AS
BEGIN
  DECLARE @uuid           varchar(36),
		  @cve_tipo_comp  varchar(1),
		  @rfc_emite      varchar(13)

  SELECT @uuid = UUID, @cve_tipo_comp = CVE_TIPO_COMPROB
  FROM OPENXML(@phDoc, 'cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital',2)
  WITH 
 (
  UUID varchar(36) '@UUID',
  CVE_TIPO_COMPROB varchar(1) '../../@TipoDeComprobante'        
 )

  SELECT @rfc_emite = RFC_EM
  FROM OPENXML(@phDoc, 'cfdi:Comprobante/cfdi:Emisor',2)
  WITH 
 (
  RFC_EM            varchar(13) '@Rfc'
 )
  
 END