USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdiComprobante')
BEGIN
  DROP  PROCEDURE spCfdInCfdiComprobante
END
GO
--EXEC spCfdInCfdiComprobante 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdiComprobante
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
@pNomArchivo      varchar(250),
@pBError          bit          OUT,
@pError           varchar(80)  OUT, 
@pMsgError        varchar(400) OUT

)
AS
BEGIN

  DECLARE @seccion      varchar(20)

  DECLARE @k_verdadero  varchar(1)  = '1',
          @k_pendiente  varchar(2)  = 'PE',
          @k_error      varchar(1)  = 'E'

  BEGIN TRY

  SET  @seccion  =  'Comprobante'
  INSERT INTO CFDI_COMPROBANTE
 (CVE_EMPRESA, 
  ANO_MES,
  CVE_TIPO,
  UUID,
  SELLO,
  CERTIFICADO, 
  SERIE,       
  FOLIO,        
  FT_FACTURA,          
  FORMA_PAGO,         
  CONDICIONES_PAGO,        
  IMP_SUB_TOTAL,       
  IMP_DESCUENTO,      
  CVE_MONEDA,           
  TIPO_CAMBIO,        
  IMP_TOTAL,      
  CVE_TIPO_COMPROB,          
  CVE_METODO_PAGO,          
  LUGAR_EXPEDICION,
  NOMBRE_ARCHIVO,
  F_REGISTRO,
  SIT_REGISTRO,
  FT_TIMBRADO   
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  SELLO,
  CERTIFICADO, 
  ISNULL(SERIE,' '),
  ISNULL(FOLIO,' '),        
  FT_FACTURA,          
  ISNULL(FORMA_PAGO,' '),         
  ISNULL(CONDICIONES_PAGO,' '),        
  ISNULL(IMP_SUB_TOTAL,0),       
  ISNULL(IMP_DESCUENTO,0),      
  ISNULL(CVE_MONEDA,' '),          
  ISNULL(TIPO_CAMBIO,0),        
  ISNULL(IMP_TOTAL,0),      
  ISNULL(CVE_TIPO_COMPROB,' '),          
  ISNULL(CVE_METODO_PAGO,' '),          
  ISNULL(LUGAR_EXPEDICION,' '),
  @pNomArchivo, 
  GETdate(),
  @k_pendiente,
  FT_TIMBRADO
  FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital',2)
  WITH 
 (
  SELLO            varchar(400) '../../@Sello',
  CERTIFICADO      varchar(max) '../../@Certificado',        
  SERIE            varchar(25) '../../@Serie',
  FOLIO            varchar(40) '../../@Folio',        
  FT_FACTURA       datetime  '../../@Fecha',          
  FORMA_PAGO       varchar(2)  '../../@FormaPago',         
  CONDICIONES_PAGO varchar(30) '../../@CondicionesDePago',        
  IMP_SUB_TOTAL    numeric(18,6) '../../@SubTotal',       
  IMP_DESCUENTO    numeric(18,6) '../../@Descuento',      
  CVE_MONEDA       varchar(3) '../../@Moneda',               
  TIPO_CAMBIO      numeric(12,6) '../../@TipoCambio',        
  IMP_TOTAL        numeric(18,6) '../../@Total',      
  CVE_TIPO_COMPROB varchar(1) '../../@TipoDeComprobante',          
  CVE_METODO_PAGO  varchar(3) '../../@MetodoPago',          
  LUGAR_EXPEDICION varchar(5) '../../@LugarExpedicion',
  FT_TIMBRADO      date '@FechaTimbrado'         
 )
  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH


END