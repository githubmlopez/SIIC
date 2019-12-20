USE [ADMON01]
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdiBaseDatos')
BEGIN
  DROP  PROCEDURE spCfdiBaseDatos
END
GO
--EXEC spCfdiBaseDatos'CU','MARIO','201906',106,1,'FACT',' ',' ',' ',' '
CREATE PROCEDURE [dbo].[spCfdiBaseDatos]
(
--@pIdProceso       numeric(9),
--@pIdTarea         numeric(9),
--@pCodigoUsuario   varchar(20),
--@pIdCliente       int,
--@pCveEmpresa      varchar(4),
--@pCveAplicacion   varchar(10),
--@pIdFormato       int,
--@pIdBloque        int,
--@pAnoPeriodo      varchar(6),
--@pError           varchar(80) OUT,
--@pMsgError        varchar(400) OUT
--)
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pNomArchivo      varchar(250),
@pPathArch        varchar(250),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
--   SELECT 'Procesando ' + @pPathArch

  --SET  @pPathArch   = 'C:\TEMP2018\validado.xml'
  --SET  @pNomArchivo = 'validado.xml'
  DECLARE  @TXmi          TABLE
          (XML            xml)

  DECLARE @NunRegistros   int,
          @RowCount       int,
          @xml            xml,
          @hDoc           int, 
		  @sql            nvarchar(MAX),
		  @num_folio      int,
		  @f_timbrado     datetime,
		  @uuid           varchar(36),
		  @cve_tipo_comp  varchar(1),
		  @seccion        varchar(20)

  DECLARE @k_verdadero   bit         = 1,
          @k_error       varchar(1)  = 'E',
		  @k_fol_cpto    varchar(4)  = 'CPCD',
		  @k_factura     varchar(1)  = 'I',
		  @k_pendiente   varchar(2)  = 'PE',
		  @k_cve_factura varchar(4)  = 'FACT',
		  @k_cve_CXP     varchar(4)  = 'CXP'

  BEGIN TRY

  SET @sql = 'SELECT CONVERT(XML, BulkColumn) FROM OPENROWSET(BULK ' +
              CHAR(39) + @pPathArch + CHAR(39) + ' ,SINGLE_BLOB) AS axml;'

  INSERT INTO @TXmi (XML)
  EXEC(@sql)

  SET @xml = (SELECT XML FROM @TXmi)  

  EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML,
  '<Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" 
    xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital"
	xmlns:implocal="http://www.sat.gob.mx/implocal"/>'
---- Obtiene sello del documento

  SELECT @uuid = UUID, @cve_tipo_comp = CVE_TIPO_COMPROB
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital',2)
  WITH 
 (
  UUID varchar(36) '@UUID',
  CVE_TIPO_COMPROB varchar(1) '../../@TipoDeComprobante'        
 )
  --SELECT 'SELLO ' + @sello 
  --SELECT 'TIPO ' + @cve_tipo_comp

  UPDATE CFDI_XML_CTE_PERIODO  SET CVE_TIPO_COMP = @cve_tipo_comp  WHERE 
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ANO_MES      =  @pAnoPeriodo  AND
  CVE_TIPO     =  @pCveTipo     AND
  NOM_ARCHIVO  =  @pNomArchivo

  IF  @cve_tipo_comp  =  @k_factura
  BEGIN
--  SELECT 'Procesando Factura' + @pPathArch
  --DELETE  CFDI_TRASLADADO  WHERE
  --CVE_EMPRESA  =  @pCveEmpresa  AND
  --ANO_MES      =  @pAnoPeriodo  AND
  --CVE_TIPO     =  @pCveTipo     AND
  --UUID         =  @uuid

  --DELETE  CFDI_EMISOR  WHERE
  --CVE_EMPRESA  =  @pCveEmpresa  AND
  --ANO_MES      =  @pAnoPeriodo  AND
  --CVE_TIPO     =  @pCveTipo     AND
  --UUID         =  @uuid

  --DELETE  CFDI_RECEPTOR  WHERE
  --CVE_EMPRESA  =  @pCveEmpresa  AND
  --ANO_MES      =  @pAnoPeriodo  AND
  --CVE_TIPO     =  @pCveTipo     AND
  --UUID         =  @uuid

  --DELETE  CFDI_PROD_SERV  WHERE
  --CVE_EMPRESA  =  @pCveEmpresa  AND
  --ANO_MES      =  @pAnoPeriodo  AND
  --CVE_TIPO     =  @pCveTipo     AND
  --UUID         =  @uuid

  --DELETE  CFDI_COMPROBANTE  WHERE
  --CVE_EMPRESA  =  @pCveEmpresa  AND
  --ANO_MES      =  @pAnoPeriodo  AND
  --CVE_TIPO     =  @pCveTipo     AND
  --UUID         =  @uuid

-- Carga de infromacion de comprobante

  IF  NOT EXISTS (SELECT 1 FROM  CFDI_COMPROBANTE  WHERE
                                 CVE_EMPRESA  =  @pCveEmpresa  AND
                                 ANO_MES      =  @pAnoPeriodo  AND
                                 CVE_TIPO     =  @pCveTipo     AND
                                 UUID         =  @uuid)
  BEGIN

  SET @seccion  =  'Comprobante'
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
  SIT_REGISTRO   
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
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
  NULL,
  @k_pendiente
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital',2)
  WITH 
 (
  SELLO varchar(400) '../../@Sello',
  CERTIFICADO varchar(max) '../../@Certificado',        
  SERIE varchar(25) '../../@Serie',
  FOLIO varchar(40) '../../@Folio',        
  FT_FACTURA datetime  '../../@Fecha',          
  FORMA_PAGO varchar(2)  '../../@FormaPago',         
  CONDICIONES_PAGO varchar(30) '../../@CondicionesDePago',        
  IMP_SUB_TOTAL numeric(18,6) '../../@SubTotal',       
  IMP_DESCUENTO numeric(18,6) '../../@Descuento',      
  CVE_MONEDA varchar(3) '../../@Moneda',           
  TIPO_CAMBIO numeric(12,6) '../../@TipoCambio',        
  IMP_TOTAL numeric(18,6) '../../@Total',      
  CVE_TIPO_COMPROB varchar(1) '../../@TipoDeComprobante',          
  CVE_METODO_PAGO varchar(3) '../../@MetodoPago',          
  LUGAR_EXPEDICION varchar(5) '../../@LugarExpedicion'         
 )

-- Carga de la infromación del emisor

  SET @seccion  =  'Emisor'
  INSERT INTO CFDI_EMISOR
 (CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  RFC_EMI,
  NOMBRE_EMI,
  REG_FISCAL_EMI
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
  ISNULL(RFC_EM, ' '),
  ISNULL(NOMBRE_EM, ' '),
  ISNULL(REGIMEN_FISCAL_EM, ' ')
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Emisor',2)
  WITH 
 (
  RFC_EM [varchar](13) '@Rfc',
  NOMBRE_EM [varchar](150) '@Nombre',
  REGIMEN_FISCAL_EM [varchar](3) '@RegimenFiscal'
 )

-- Carga de la información del Receptor

  SET @seccion  =  'Receptor' 
  INSERT INTO CFDI_RECEPTOR
 (CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  RFC_REC,
  NOMBRE_REC,
  USO_CFDI_REC
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
  ISNULL(RFC_RC,' '),
  ISNULL(NOMBRE_RC,' '),
  ISNULL(USO_CFDI_REC, ' ')
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Receptor',2)
  WITH 
 (
  RFC_RC [varchar](20) '@Rfc',
  NOMBRE_RC [varchar](100) '@Nombre',
  USO_CFDI_REC [varchar](100) '@UsoCFDI'
 )

---- Carga información de Productos y Servicios

  SET @seccion  =  'Productos'
  INSERT INTO CFDI_PROD_SERV
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  ID_CONCEPTO,
  CVE_PROD_SERV,
  CANTIDAD,
  CVE_UNIDAD,
  DESCRIPCION,
  VALOR_UNITARIO,
  IMP_CONCEPTO,
  IMP_DESCUENTO,
  NO_IDENTIFICACION
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
  ID_PADRE,
  ISNULL(CVE_PROD_SERV, ' '),
  ISNULL(CANTIDAD,0),
  ISNULL(CVE_UNIDAD, ' '),
  ISNULL(DESCRIPCION, ' '), 
  ISNULL(VALOR_UNITARIO,0),
  ISNULL(IMPORTE_C,0),
  ISNULL(IMP_DESCUENTO,0),
  ISNULL(NO_IDENTIFICACION,' ')
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',2)
  WITH 
(
  ID_PADRE INT '@mp:parentid',
  ID_CONCEPTO INT '@mp:id',
  CVE_PROD_SERV [varchar](8) '../../../@ClaveProdServ',
  CANTIDAD [NUMERIC](18,6) '../../../@Cantidad',
  CVE_UNIDAD [varchar](3) '../../../@ClaveUnidad',
  DESCRIPCION [varchar](max) '../../../@Descripcion',
  VALOR_UNITARIO [NUMERIC](18,6) '../../../@ValorUnitario',
  IMPORTE_C [NUMERIC](18,6) '../../../@Importe',
  IMP_DESCUENTO [NUMERIC](18,6) '../../../@Descuento',
  NO_IDENTIFICACION [varchar](100) '../../../@NoIdentificacion',
  IMP_TRAS [NUMERIC](18,6) '@Importe'
 )    GROUP BY ID_PADRE, CVE_PROD_SERV, CANTIDAD, CVE_UNIDAD, DESCRIPCION, 
            VALOR_UNITARIO, IMPORTE_C, IMP_DESCUENTO, NO_IDENTIFICACION

---- Carga información de impuestos trasladados

  SET @seccion  =  'Trasladado'
  INSERT INTO CFDI_TRASLADADO
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  ID_CONCEPTO,
  ID_ORDEN,
  CVE_IMPUESTO,
  BASE,
  TIPO_FACTOR,
  TASA_CUOTA,
  IMP_IMPUESTO
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
  ID_PADRE,
  ID_ORDEN,
  ISNULL(CVE_IMPUESTO, ' '),
  ISNULL(BASE, 0),
  ISNULL(TIPO_FACTOR, ' '),
  ISNULL(TASA_CUOTA, 0),
  ISNULL(IMP_IMPUESTO, 0)
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',2)
  WITH 
 (
  ID_PADRE INT '@mp:parentid',
  ID_ORDEN INT '@mp:id',
  CVE_IMPUESTO [varchar](3) '@Impuesto',
  BASE [NUMERIC](18,6) '@Base',
  TIPO_FACTOR [varchar](10) '@TipoFactor',
  TASA_CUOTA [NUMERIC](8,6) '@TasaOCuota',
  IMP_IMPUESTO [NUMERIC](18,6) '@Importe'
)
---- Carga información de impuestos locales

  SET @seccion  =  'Locales'

  INSERT INTO CFDI_IMP_LOCAL
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  CVE_IMP_LOCAL,
  TASA_IMP_LOCAL,
  IMP_IMPUESTO
 )
 
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
  CVE_IMP_LOCAL,
  TASA_IMP_LOCAL,        
  IMP_IMPUESTO
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/implocal:ImpuestosLocales/implocal:TrasladosLocales',2)
  WITH 
 (
  CVE_IMP_LOCAL  varchar(10)   '@ImpLocTrasladado',
  TASA_IMP_LOCAL numeric(18,2) '@TasadeTraslado',        
  IMP_IMPUESTO   numeric(18,2) '@Importe'
 )
 
  EXEC sp_xml_removedocument @hDoc

  END

  END

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Carga de CFDI ' + @pPathArch + ' ' + isnull(@seccion, 'nulo')
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

