USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spValFactXml')
BEGIN
  DROP  PROCEDURE spValFactXml
END
GO

--EXEC spValFactXml'CU','MARIO','201906',104,1,' ',' '
CREATE PROCEDURE [dbo].[spValFactXml]
(
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE @cve_empresa       varchar(4),
	      @ano_mes           varchar(6),
	      @cve_tipo          varchar(4),
		  @uuid              varchar(36),
	      @sello             varchar(400),
	      @certificado       varchar(max),
	      @folio             varchar(40),
	      @ft_factura        datetime,
	      @forma_pago        varchar(2),
	      @condiciones_pago  varchar(30),
	      @imp_sub_total     numeric(18,6),
	      @imp_descuento     numeric(18,6),
	      @cve_moneda_s      varchar(3),
	      @tipo_cambio       numeric(12,6),
	      @imp_total         numeric(18,6),
	      @cve_tipo_comprob  varchar(1),
	      @cve_metodo_pago   varchar(3),
	      @lugar_expedicón   varchar(5),
	      @nombre_archivo    varchar(250),
	      @serie             varchar(25),
	      @rfc_rec           varchar(15),
   	      @rfc_emi           varchar(15),
	      @uso_cfdi_rec      varchar(4),
	      @reg_fiscal_emi    varchar(3)

  Declare
	      @id_concepto       int,
	      @cve_prod_serv     varchar(8), 
	      @cantidad          numeric(18,6),
	      @cve_unidad        varchar(3),
	      @descripcion       varchar(max),
	      @valor_unitario    numeric(18,6),
		  @imp_concepto      numeric(18,2),
		  @no_identificacion varchar(100),
		  @cve_operacion     varchar(4)
		  
  DECLARE @NunRegistros  int = 0, 
		  @RowCount      int = 0,
		  @NunRegistros1 int = 0, 
		  @RowCount1     int = 0,
		  @id_cliente    int = 0,
		  @folio_vta     int = 0,
		  @folio_fact    int = 0,
		  @cve_moneda    varchar(1),
		  @cve_subprod   varchar(8),
		  @imp_iva       numeric(16,2) = 0,
		  @imp_isr       numeric(16,2) = 0,
		  @imp_ieps      numeric(16,2) = 0,
		  @conta_item	 int           = 0,
		  @b_fact_ok     bit
 
  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_cerrado     varchar(1) = 'C',
		  @k_factura     varchar(4) = 'FACT',
		  @k_cxp         varchar(4) = 'CXP',
		  @k_error       varchar(1) = 'E',
		  @k_warning     varchar(1) = 'W',
		  @k_pesos       varchar(1) = 'P',
		  @k_dolar       varchar(1) = 'D',
		  @k_euro        varchar(1) = 'E',
		  @k_pesos_s     varchar(3) = 'MXN',
		  @k_dolar_s     varchar(3) = 'USD',
		  @k_euro_s      varchar(3) = 'EUR',
		  @k_registrado  varchar(2) = 'RE'

   DECLARE @TvpComprobante TABLE
   (
    NUM_REGISTRO      int identity(1,1),
	CVE_EMPRESA       varchar (4),
	ANO_MES           varchar (6),
	CVE_TIPO          varchar (4),
	UUID              varchar (36),
	SELLO             varchar (400),
	CERTIFICADO       varchar (max),
	FOLIO             varchar (40),
	FT_FACTURA        datetime,
	FORMA_PAGO        varchar (2),
	CONDICIONES_PAGO  varchar (30),
	IMP_SUB_TOTAL     numeric (18,6),
	IMP_DESCUENTO     numeric (18,6),
	CVE_MONEDA        varchar (3),
	TIPO_CAMBIO       numeric (12,6),
	IMP_TOTAL         numeric (18,6),
	CVE_TIPO_COMPROB  varchar (1),
	CVE_METODO_PAGO   varchar (3),
	LUGAR_EXPEDICION  varchar (5),
	NOMBRE_ARCHIVO    varchar (250),
	SERIE             varchar (25),
	RFC_REC           varchar(15),
   	RFC_EMI           varchar(15),
	USO_CFDI_REC      varchar(4),
	REG_FISCAL_EMI    varchar(3) 
   )

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT INTO @TvpComprobante 
    SELECT 
	c.CVE_EMPRESA,
	c.ANO_MES,
	c.CVE_TIPO,
	c.UUID,
	c.SELLO,
	CERTIFICADO,
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
	SERIE,
	RFC_REC,
   	RFC_EMI,
	USO_CFDI_REC,
	REG_FISCAL_EMI           
    FROM   CFDI_COMPROBANTE c, CFDI_EMISOR e, CFDI_RECEPTOR r WHERE
	c.CVE_EMPRESA = @pCveEmpresa  AND
	c.ANO_MES     = @pAnoPeriodo  AND
--	c.CVE_TIPO    = @k_factura    AND
	c.CVE_EMPRESA = e.CVE_EMPRESA AND
	c.ANO_MES     = e.ANO_MES     AND
	c.CVE_TIPO    = e.CVE_TIPO    AND
	c.UUID        = e.UUID        AND
	c.CVE_EMPRESA = r.CVE_EMPRESA AND
	c.ANO_MES     = r.ANO_MES     AND
	c.CVE_TIPO    = r.CVE_TIPO    AND
	c.UUID        = r.UUID        AND
	c.SIT_REGISTRO <> @k_registrado       
    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1
--	SELECT * FROM @TvpComprobante
    WHILE @RowCount <= @NunRegistros
    BEGIN
	  SELECT 
	  @cve_empresa      =    CVE_EMPRESA,
	  @ano_mes          =    ANO_MES,
	  @cve_tipo         =    CVE_TIPO,
	  @uuid             =    UUID,
	  @sello            =    SELLO,
	  @certificado      =    CERTIFICADO,
	  @folio            =    FOLIO,
	  @ft_factura       =    FT_FACTURA,
	  @forma_pago       =    FORMA_PAGO,
	  @condiciones_pago =    CONDICIONES_PAGO,
	  @imp_sub_total    =    IMP_SUB_TOTAL,
	  @imp_descuento    =    IMP_DESCUENTO,
	  @cve_moneda_s     =    CVE_MONEDA,
	  @tipo_cambio      =    TIPO_CAMBIO,
	  @imp_total        =    IMP_TOTAL,
	  @cve_tipo_comprob =    CVE_TIPO_COMPROB,
	  @cve_metodo_pago  =    CVE_METODO_PAGO,
	  @lugar_expedicón  =    LUGAR_EXPEDICION,
	  @nombre_archivo   =    NOMBRE_ARCHIVO,
	  @serie            =    SERIE,
	  @rfc_rec          =    RFC_REC,
   	  @rfc_emi          =    RFC_EMI,
	  @uso_cfdi_rec     =    USO_CFDI_REC,
	  @reg_fiscal_emi   =    REG_FISCAL_EMI            
	  FROM   @TvpComprobante WHERE  NUM_REGISTRO = @RowCount

      IF  @cve_tipo  =  @k_factura  
	  BEGIN

	    IF    EXISTS(SELECT 1 FROM CI_CLIENTE WHERE RFC_CLIENTE  =  @rfc_rec)
	    BEGIN
          IF  (SELECT COUNT(*) FROM CI_CLIENTE WHERE RFC_CLIENTE  =  @rfc_rec) > 1
		  BEGIN
            SET  @pError    =  'Existe mas de un Cliente para el RFC ' + ISNULL(@rfc_rec,'NULO')
            SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
            SELECT @pMsgError
--        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
		  END
        END
	    ELSE
	    BEGIN
	      SET  @pError    =  'No existe RFC en Clientes ' + ISNULL(@rfc_rec,'NULO')
          SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
          SELECT @pMsgError
--        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	    END  

        IF  EXISTS (SELECT 1 FROM CI_FACTURA  WHERE CVE_EMPRESA = @pCveEmpresa AND SERIE = @serie AND ID_CXC = @folio)
	    BEGIN
          SET  @pError    =  'El folio de Factura ya Existe ' +  ISNULL(@serie, 'NULO') + ' ' + ISNULL(@folio,'NULO')
          SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
          SELECT @pMsgError
--        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	    END

      END

      IF  @cve_moneda_s NOT IN (@k_dolar_s, @k_pesos_s, @k_euro_s)
      BEGIN
        SET  @pError    =  'Moneda no soportada ' +  ISNULL(@k_euro_s, 'NULO')
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        SELECT @pMsgError
 --        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
 	  END

      DECLARE @TvpProdServ TABLE
	 (
	  NUM_REGISTRO      int identity(1,1),
	  CVE_EMPRESA       varchar (4),
	  ANO_MES           varchar (6),
	  CVE_TIPO          varchar (4),
	  UUID              varchar (36),
	  ID_CONCEPTO       int,
	  CVE_PROD_SERV     varchar (8),
	  CANTIDAD          numeric (18, 6),
	  CVE_UNIDAD        varchar (3),
	  DESCRIPCION       varchar (max),
	  VALOR_UNITARIO    numeric (18, 6),
	  IMP_CONCEPTO      numeric (18, 2),
	  IMP_DESCUENTO     numeric (18, 2),
	  NO_IDENTIFICACION varchar (100)
	 )

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
      DELETE FROM @TvpProdServ
	  INSERT INTO @TvpProdServ
      SELECT
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
	  FROM  CFDI_PROD_SERV  WHERE 
	  CVE_EMPRESA  =  @pCveEmpresa  AND
	  ANO_MES      =  @pAnoPeriodo  AND
	  CVE_TIPO     =  @cve_tipo     AND
	  UUID         =  @uuid
      SET @NunRegistros1 = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
 
      SET @RowCount1 = (SELECT MIN(NUM_REGISTRO) FROM @TvpProdServ)
	  SET @NunRegistros1  =  @NunRegistros1 + @RowCount1 - 1
 
      SET  @conta_item  = 1
      WHILE @RowCount1 <= @NunRegistros1
      BEGIN
        SELECT 
	    @cve_empresa        =  CVE_EMPRESA,
	    @ano_mes            =  ANO_MES,
	    @cve_tipo           =  CVE_TIPO,
	    @uuid               =  UUID,
	    @id_concepto        =  ID_CONCEPTO,
        @cve_prod_serv      =  CVE_PROD_SERV, 
        @cantidad           =  CANTIDAD, 
        @cve_unidad         =  CVE_UNIDAD,
        @descripcion        =  DESCRIPCION,
        @valor_unitario     =  VALOR_UNITARIO,
	    @imp_concepto       =  IMP_CONCEPTO,
        @imp_descuento      =  IMP_DESCUENTO,
	    @no_identificacion  =  NO_IDENTIFICACION
	    FROM  @TvpProdServ
	    WHERE NUM_REGISTRO  = @RowCount1  

        IF  @cve_tipo  =  @k_factura  
	    BEGIN
          IF  NOT EXISTS(SELECT 1 FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO  =  SUBSTRING(@no_identificacion,1,8))
	      BEGIN
 	        SET  @pError    =  'No existe Subproducto ' + ISNULL(SUBSTRING(@no_identificacion,1,8),'NULO')
            SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
            SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	      END  
        END 

        IF  @cve_tipo  =  @k_cxp  
	    BEGIN
          SET  @cve_operacion = dbo.fnObtCveOper(@pCveEmpresa, @pAnoPeriodo, @cve_tipo, @uuid, @cve_prod_serv)

          IF  ISNULL(@cve_operacion, ' ') = ' '
	      BEGIN
 	        SET  @pError    =  'No existe Mapeo Producto ' + ISNULL(@cve_prod_serv,'NULO')
            SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
            SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	      END  
          ELSE
		  BEGIN
            IF  EXISTS (SELECT 1 FROM CI_OPERACION_CXP WHERE CVE_OPERACION = @cve_operacion)
			BEGIN
		      UPDATE CFDI_PROD_SERV  SET  CVE_OPERACION  =  @cve_operacion  WHERE
			  CVE_EMPRESA  =  @cve_empresa  AND
	          ANO_MES      =  @ano_mes      AND
	          CVE_TIPO     =  @cve_tipo     AND
	          UUID         =  @uuid         AND
	          ID_CONCEPTO  =  @id_concepto
            END
            ELSE
			BEGIN
              SET  @pError    =  'No existe Cve de Operacion ' + ISNULL(@cve_operacion,'NULO')
              SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
              SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
			END
		  END
	    END 

        SET @RowCount1 = @RowCount1 + 1
      END

      IF  @imp_sub_total  <>  (SELECT SUM(IMP_CONCEPTO) FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoPeriodo AND
	                                                                              CVE_TIPO = @k_factura AND UUID = @uuid)
	  BEGIN
 	   SET  @pError    =  'No Cuadra total  ' + ISNULL(CONVERT(INT,@folio),'NULO') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
       SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
       SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	  END               
	  SELECT @RowCount  =  @RowCount  +  1 
    END

    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros

END

