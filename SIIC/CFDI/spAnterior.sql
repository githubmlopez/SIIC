USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdiTraslado')
BEGIN
  DROP  PROCEDURE spCfdiTraslado
END
GO
--EXEC spCfdiBaseDatos 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdiTraslado
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pNomArchivo      varchar(250),
@pPathArch        varchar(250),
@pBError          bit OUT,
@pError           varchar(80) OUT, 
@pMsgError        varchar(400) OUT

)
AS
BEGIN
--   SELECT 'Procesando ' + @pPathArch

--  SET  @pPathArch   = 'C:\TEMP2018\CFDIRECIBO.xml'
--  SET  @pNomArchivo = 'CFDIRECIBO.xml'

  DECLARE  @TXmi          TABLE
          (XML            xml)

  DECLARE
  @id_concepto       int

  DECLARE @NunRegistros   int,
          @RowCount       int,
		  @NunRegistros2  int,
          @RowCount2      int,
		  @NunRegistros3  int,
          @RowCount3      int,
		  @NunRegistros4  int,
          @RowCount4      int,
		  @NunRegIni      int,
		  @id_padre       int,
		  @id_nodo        int,
		  @id_nodo_t      int,
		  @id_nodo_r      int,
          @xml            xml,
          @hDoc           int, 
		  @sql            nvarchar(MAX),
		  @num_folio      int,
		  @ft_timbrado     datetime,
		  @uuid           varchar(36),
		  @cve_tipo_comp  varchar(1),
		  @seccion        varchar(20),
		  @id_prod_serv   int

  DECLARE @k_verdadero   bit         = 1,
          @k_error       varchar(1)  = 'E',
		  @k_fol_cpto    varchar(4)  = 'CPCD',
		  @k_factura     varchar(1)  = 'I',
          @k_pago        varchar(1)  = 'P',
		  @k_pendiente   varchar(2)  = 'PE',
		  @k_cve_factura varchar(4)  = 'FACT',
		  @k_cve_CXP     varchar(4)  = 'CXP'

   DECLARE @TProdServ TABLE
  (
   RowID             int  identity(1,1),
   ID_CONCEPTO       int
  )

   DECLARE @TImpuesto TABLE
  (
   RowID             int  identity(1,1),
   ID_PADRE          int,   
   ID_NODO           int
  )

   DECLARE @TTrasladados TABLE
  (
   RowID             int  identity(1,1),
   ID_PADRE          int,   
   ID_NODO           int
  )

   DECLARE @TRetenidos TABLE
  (
   RowID             int  identity(1,1),
   ID_PADRE          int,   
   ID_NODO           int
  )

   DECLARE @TTrasladado TABLE
   (
    RowID        int  identity(1,1),
    CVE_EMPRESA  varchar(4),
    ANO_MES      varchar(6),
    CVE_TIPO     varchar(4),
    UUID         varchar(36),
    ID_CONCEPTO  int,
    ID_PADRE     int,
    ID_ORDEN     int,
    CVE_IMPUESTO varchar(3),
    BASE         numeric(18,6),
    TIPO_FACTOR  varchar(10),
    TASA_CUOTA   numeric(8,6),
    IMP_IMPUESTO numeric(18,6)
   )

   DECLARE @TRetenido TABLE
   (
    RowID        int  identity(1,1),
    CVE_EMPRESA  varchar(4),
    ANO_MES      varchar(6),
    CVE_TIPO     varchar(4),
    UUID         varchar(36),
    ID_CONCEPTO  int,
    ID_PADRE     int,
    ID_ORDEN     int,
    CVE_IMPUESTO varchar(3),
    BASE         numeric(18,6),
    TIPO_FACTOR  varchar(10),
    TASA_CUOTA   numeric(8,6),
    IMP_IMPUESTO numeric(18,6)
   )

  BEGIN TRY
  
  SET @sql = 'SELECT CONVERT(XML, BulkColumn) FROM OPENROWSET(BULK ' +
              CHAR(39) + @pPathArch + CHAR(39) + ' ,SINGLE_BLOB) AS axml;'

  INSERT into @TXmi (XML)
  EXEC(@sql)

  SET @xml = (SELECT XML FROM @TXmi)  

  EXEC sp_xml_preparedocument @hDoc OUTPUT, @xml,
  '<Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" 
    xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital"
	xmlns:implocal="http://www.sat.gob.mx/implocal"
	xmlns:pago10="http://www.sat.gob.mx/Pagos"/>'
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

  --SELECT 'VOY PRUEBA'
  --EXEC spPruebaXML @hDoc
  --RETURN

  UPDATE CFDI_XML_CTE_PERIODO  SET CVE_TIPO_COMP = @cve_tipo_comp  WHERE 
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ANO_MES      =  @pAnoPeriodo  AND
  CVE_TIPO     =  @pCveTipo     AND
  NOM_ARCHIVO  =  @pNomArchivo

  IF  @cve_tipo_comp  IN  (@k_factura, @k_pago)
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

  --DELETE  CFDI_IMP_LOCAL  WHERE
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

----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Comprobante                                                                          --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Comprobante'
  SELECT 'COMPROBANTE'

  INSERT intO CFDI_COMPROBANTE
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
  GETdate(),
  @k_pendiente,
  FT_TIMBRADO
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital',2)
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

----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Emisor                                                                               --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Emisor'
  SELECT 'EMISOR'
  INSERT intO CFDI_EMISOR
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
  RFC_EM            varchar(13) '@Rfc',
  NOMBRE_EM         varchar(150) '@Nombre',
  REGIMEN_FISCAL_EM varchar(3) '@RegimenFiscal'
 )

----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Receptor                                                                             --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Receptor'
  SELECT 'RECEPTOR'
   
  INSERT intO CFDI_RECEPTOR
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
  RFC_RC       varchar(20) '@Rfc',
  NOMBRE_RC    varchar(100) '@Nombre',
  USO_CFDI_REC varchar(100) '@UsoCFDI'
 )

----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Productos y Servicios                                                                --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Productos'
  SELECT 'PRODUCTOS'
	
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
  ID_CONCEPTO,
  ISNULL(CVE_PROD_SERV, ' '),
  ISNULL(CANTIDAD,0),
  ISNULL(CVE_UNIDAD, ' '),
  ISNULL(DESCRIPCION, ' '), 
  ISNULL(VALOR_UNITARIO,0),
  ISNULL(IMPORTE_C,0),
  ISNULL(IMP_DESCUENTO,0),
  ISNULL(NO_IDENTIFICACION,' ')
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto',2)
  WITH 
(
  ID_CONCEPTO INT '@mp:id',
  CVE_PROD_SERV [varchar](8) '@ClaveProdServ',
  CANTIDAD [NUMERIC](18,6) '@Cantidad',
  CVE_UNIDAD [varchar](3) '@ClaveUnidad',
  DESCRIPCION [varchar](max) '@Descripcion',
  VALOR_UNITARIO [NUMERIC](18,6) '@ValorUnitario',
  IMPORTE_C [NUMERIC](18,6) '@Importe',
  IMP_DESCUENTO [NUMERIC](18,6) '@Descuento',
  NO_IDENTIFICACION [varchar](100) '@NoIdentificacion'
 )

  INSERT @TProdServ
  (ID_CONCEPTO)
  SELECT ID_CONCEPTO
  FROM CFDI_PROD_SERV

  SET @NunRegistros  =  (SELECT COUNT(*) FROM @TProdServ)

  SELECT * FROM @TProdServ
  SELECT 'NUM ', CONVERT(VARCHAR(4),@NunRegistros)

  SET @RowCount     = 1

----------------------------------------------------------------------------------------------------------------------
-- Los productos y servicios se guardan en una tabla porque se procesarán uno por uno para crear los registros de   --
-- sus tablas hijos. Será necesario que herede a sus tablas hijo el campo ID_CONCEPTO que representa el numero de   --
-- NODO                                                                                                             --
----------------------------------------------------------------------------------------------------------------------
-- La ruta que se correra para registrar los impuestos trasladados y retenidos es la siguiente                      --
-- cfdi:Concepto => cfdi:Impuestos => cfdi:Trasladados => cfdi:Trasladado                                           --
-- cfdi:Concepto => cfdi:Impuestos => cfdi:Retenidos => cfdi:Retenido                                               --
----------------------------------------------------------------------------------------------------------------------
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT  
    @id_concepto = ID_CONCEPTO
	FROM @TProdServ
    WHERE  RowID  =  @RowCount
    SELECT 'PROD ', CONVERT(varchar(4), @id_concepto)

	-- Procesando Nodo Impuesto

    SET @seccion  =  'Impuesto'

----------------------------------------------------------------------------------------------------------------------
-- Se prcesaran los nodos del tag <Impuesto> debido a que es la forma de poder heredar el numero de nodo  '@mp:id'  --
-- del degistro de CFDI_PROD_SERV. Todo esto se hizo debido a que el comando OPENXML solo permite saber el          --
-- identificador del nodo padre, pero no mas "arriba". Notese la clausula where WHERE ID_PADRE = @id_concepto       --
-- donde seleccionan los NODOS de impuesto que pertenecen al producto servicio que se esta procesando.              --
----------------------------------------------------------------------------------------------------------------------

    SET @NunRegIni  =  (SELECT COUNT(*) FROM @TImpuesto)

    INSERT INTO @TImpuesto
   (ID_PADRE, ID_NODO)
    SELECT ID_PADRE, ID_NODO
    FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos',2)
    WITH 
   (
    ID_PADRE int '@mp:parentid',
	ID_NODO   int '@mp:id'
   )
    WHERE ID_PADRE = @id_concepto

--	SELECT * FROM @TImpuesto
    SET @NunRegistros2  =  (SELECT COUNT(*) FROM  @TImpuesto) 
    SET @RowCount2     = @NunRegIni + 1

    WHILE @RowCount2 <= @NunRegistros2
    BEGIN
      SELECT  
      @id_padre = ID_PADRE, @id_nodo = ID_NODO
      FROM @TImpuesto
      WHERE  RowID  =  @RowCount2

      SELECT 'IMP ', CONVERT(varchar(4), @id_nodo)

--	  SELECT CONVERT(VARCHAR(4), @id_padre) + ' ' + CONVERT(VARCHAR(4), @id_nodo)

      SET @NunRegIni  =  (SELECT COUNT(*) FROM @TTrasladados)

      INSERT INTO @TTrasladados
     (ID_PADRE, ID_NODO)
      SELECT ID_PADRE, ID_NODO
      FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados',2)
      WITH 
     (
      ID_PADRE int '@mp:parentid',
	  ID_NODO  int '@mp:id'
     )
      WHERE ID_PADRE = @id_nodo
SELECT 'T', * FROM @TTrasladados
----------------------------------------------------------------------------------------------------------------------
-- Principia proceso de Trasladados                                                                                 --
----------------------------------------------------------------------------------------------------------------------

     SET @NunRegistros3  =  (SELECT COUNT(*) FROM  @TTrasladados) 
     SET @RowCount3     = @NunRegIni + 1

     WHILE @RowCount3 <= @NunRegistros3
     BEGIN
       SELECT '**ENTRO A TRASLADADOS'
       SELECT  
       @id_padre = ID_PADRE, @id_nodo_t = ID_NODO
       FROM @TTrasladados
       WHERE  RowID  =  @RowCount3

----------------------------------------------------------------------------------------------------------------------
-- Se crea el registro del impuesto trasladado, notese que este hereda Numero de NODO del registro del producto     --
-- CFDI_PROD_SERV que se esta procesando. Todo esto se hizo debido a que el comando OPENXML solo permite saber el   --
-- identificador del nodo padre, pero no mas "arriba"                                                               --
----------------------------------------------------------------------------------------------------------------------

       SET @seccion  =  'Trasladado'


       DELETE @TTrasladado
       INSERT INTO @TTrasladado
      (
       CVE_EMPRESA,
       ANO_MES,
       CVE_TIPO,
       UUID,
       ID_CONCEPTO,
       ID_PADRE,
       ID_ORDEN,
       CVE_IMPUESTO,
       BASE,
       TIPO_FACTOR,
       TASA_CUOTA,
       IMP_IMPUESTO
      )
       SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid, @id_concepto,
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
       ID_PADRE     int '@mp:parentid',
       ID_ORDEN     int '@mp:id',
       CVE_IMPUESTO varchar(3) '@Impuesto',
       BASE         numeric(18,6) '@Base',
       TIPO_FACTOR  varchar(10) '@TipoFactor',
       TASA_CUOTA   numeric(8,6) '@TasaOCuota',
       IMP_IMPUESTO numeric(18,6) '@Importe'
      )
       WHERE ID_PADRE  =  @id_nodo_t

       SELECT 'TT', * FROM @TTrasladado
       SELECT 'VOY A INSERTAR TRASLADO'
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
	   SELECT 
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
       FROM @TTrasladado

	   SELECT 'INSERTTO TRASLADADO'
	   SET @RowCount3     = @RowCount3 + 1
     END

----------------------------------------------------------------------------------------------------------------------
-- Principia proceso de Retenidos                                                                                 --
----------------------------------------------------------------------------------------------------------------------
     SET @NunRegIni  =  (SELECT COUNT(*) FROM @TRetenidos)

     INSERT INTO @TRetenidos
    (ID_PADRE, ID_NODO)
     SELECT ID_PADRE, ID_NODO
     FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones',2)
     WITH 
    (
     ID_PADRE int '@mp:parentid',
     ID_NODO   int '@mp:id'
   )
     WHERE ID_PADRE = @id_nodo

     SELECT 'RS', * FROM @TRetenidos	

     SET @seccion  =  'Retenido'

     SET @NunRegistros4  =  (SELECT COUNT(*) FROM  @TRetenidos) 
     SET @RowCount4     = @NunRegIni + 1

     WHILE @RowCount4 <= @NunRegistros4
     BEGIN
       SELECT  
       @id_padre = ID_PADRE, @id_nodo_r = ID_NODO
       FROM @TRetenidos
       WHERE  RowID  =  @RowCount4

----------------------------------------------------------------------------------------------------------------------
-- Se crea el registro del impuesto retenido, notese que este hereda Numero de NODO del registro del producto       --
-- CFDI_PROD_SERV que se esta procesando. Todo esto se hizo debido a que el comando OPENXML solo permite saber el   --
-- identificador del nodo padre, pero no mas "arriba"                                                               --
----------------------------------------------------------------------------------------------------------------------

       SET @seccion  =  'Retenido'
	   DELETE @TRetenido
       INSERT INTO @TRetenido
      (
       CVE_EMPRESA,
       ANO_MES,
       CVE_TIPO,
       UUID,
       ID_CONCEPTO,
       ID_PADRE,
       ID_ORDEN,
       CVE_IMPUESTO,
       BASE,
       TIPO_FACTOR,
       TASA_CUOTA,
       IMP_IMPUESTO
      )
       SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid, @id_concepto,
       ID_PADRE,
       ID_ORDEN,
       ISNULL(CVE_IMPUESTO, ' '),
       ISNULL(BASE, 0),
       ISNULL(TIPO_FACTOR, ' '),
       ISNULL(TASA_CUOTA, 0),
       ISNULL(IMP_IMPUESTO, 0)
       FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',2)
       WITH 
      (
       ID_PADRE     int '@mp:parentid',
       ID_ORDEN     int '@mp:id',
       CVE_IMPUESTO varchar(3) '@Impuesto',
       BASE         numeric(18,6) '@Base',
       TIPO_FACTOR  varchar(10) '@TipoFactor',
       TASA_CUOTA   numeric(8,6) '@TasaOCuota',
       IMP_IMPUESTO numeric(18,6) '@Importe'
      )
       WHERE ID_PADRE  =  @id_nodo_r

       SELECT 'RS', * FROM @TRetenido	

       INSERT INTO CFDI_RETENIDO
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
	   SELECT 
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
       FROM @TRetenido
	   SELECT 'INSERTO RETENIDO'
       SET @RowCount4     = @RowCount4 + 1
     END

---- Termina while de impuestos

      SET @RowCount2 = @RowCount2 + 1
    END

    SET @RowCount = @RowCount + 1
    SELECT 'CP ' + CONVERT(VARCHAR(4), @RowCount)
	SELECT 'PRODF ', CONVERT(varchar(4), @id_concepto)

  END

---- Carga información de impuestos locales

  SET @seccion  =  'Locales'
  SELECT 'LOCALES'
  INSERT intO CFDI_IMP_LOCAL
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
  ISNULL(TASA_IMP_LOCAL,0),        
  ISNULL(IMP_IMPUESTO,0)
  FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/implocal:ImpuestosLocales/implocal:TrasladosLocales',2)
  WITH 
 (
  CVE_IMP_LOCAL  varchar(10)   '@ImpLocTrasladado',
  TASA_IMP_LOCAL numeric(18,2) '@TasadeTraslado',        
  IMP_IMPUESTO   numeric(18,2) '@Importe'
 )

-- Carga información de Pagos

  SET @seccion  =  'Pagos'
  SELECT 'PAGOS'
  IF  @cve_tipo_comp  =  @k_pago
  BEGIN
    INSERT INTO CFDI_PAGO
   (
    CVE_EMPRESA,
    ANO_MES,
    CVE_TIPO,
    UUID,
    SEC_PAGO,
    IMP_PAGO,
    CVE_MONEDA,
	FORMA_PAGO,
	F_PAGO
   )
    SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
    SEC_PAGO,
    ISNULL(IMP_PAGO,0),        
    ISNULL(CVE_MONEDA,' '),
	ISNULL(FORMA_PAGO,' '),
	F_PAGO 
    FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/pago10:Pagos/pago10:Pago',2)
    WITH 
   (
    SEC_PAGO   int '@mp:id',
    IMP_PAGO   numeric(18,2)  '@Monto',
    CVE_MONEDA varchar(3) '@MonedaP',  
	FORMA_PAGO varchar(2) '@FormaDePagoP',      
    F_PAGO     date '@FechaPago'
   )

    SET @seccion  =  'Pagos Relacionados'
	SELECT 'RELACIONADOS'
    INSERT intO CFDI_PAGO_RELAC
   (
    CVE_EMPRESA,
    ANO_MES,
    CVE_TIPO,
    UUID,
    SEC_PAGO,
    UUID_REL,
    NUM_PARCIALIDAD,
	SERIE,
	IMP_SDO_INSOLUTO,
	IMP_PAGADO,
	IMP_SDO_ANT,
	CVE_METODO_PAGO,
	CVE_MONEDA,
	FOLIO
   )
    SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @uuid,
    SEC_PAGO,
    UUID_REL,
    ISNULL(NUM_PARCIALIDAD,0),
	ISNULL(SERIE,' '),
	ISNULL(IMP_SDO_INSOLUTO,0),
	ISNULL(IMP_PAGADO,0),
	ISNULL(IMP_SDO_ANT,0),
	ISNULL(CVE_METODO_PAGO,' '),
	ISNULL(CVE_MONEDA,' '),
	ISNULL(FOLIO,' ')
    FROM OPENXML(@hDoc, 'cfdi:Comprobante/cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado',2)
    WITH 
   (
    SEC_PAGO         int '@mp:parentid',
    UUID_REL         varchar(36) '@IdDocumento',
    NUM_PARCIALIDAD  int '@NumParcialidad',
	SERIE            varchar(25) '@Serie',
	IMP_SDO_INSOLUTO numeric(18,6) '@ImpSaldoInsoluto',
	IMP_PAGADO       numeric(18,6) '@ImpPagado',
	IMP_SDO_ANT      numeric(18,6) '@ImpSaldoAnt',
	CVE_METODO_PAGO  varchar(3) '@MetodoDePagoDR',
	CVE_MONEDA       varchar(3) '@MonedaDR',
	FOLIO            varchar(40)  '@Folio'
   )
    
  END 
    
  EXEC sp_xml_removedocument @hDoc

  END

  END

  END TRY

  BEGIN CATCH
--    SET  @pError    =  '(E) Carga CFDI ' + @pPathArch + ' ' + isnull(@seccion, 'nulo') 
    SET  @pError    =  '(E) Carga CFDI ' + ' ' + isnull(@seccion, 'nulo') 

    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END

