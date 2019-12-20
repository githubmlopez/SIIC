USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCargaFactXml]    Script Date: 11/09/2019 04:04:03 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spCargaFactXml'CU','MARIO','201906',145,8137,' ',' '
ALTER PROCEDURE [dbo].[spCargaFactXml]
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

  DECLARE @TvpError  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  TIPO_ERROR      VARCHAR(1),
  ERROR           VARCHAR(80),
  MSG_ERROR       varchar (400)
 )
  
  DECLARE @cve_empresa       varchar(4),
	      @ano_mes           varchar(6),
	      @cve_tipo          varchar(4),
		  @uuid              varchar(36),
	      @sello             varchar(400),
	      @certificado       varchar(max),
	      @serie             varchar(25),
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
	      @lugar_expedicion  varchar(5),
	      @nombre_archivo    varchar(250),

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
		  @no_identificacion varchar(100)
		  
  DECLARE @NunRegistros  int = 0, 
		  @RowCount      int = 0,
		  @NunRegistros1 int = 0, 
		  @RowCount1     int = 0,
		  @NunRegistros2 int = 0, 
		  @RowCount2     int = 0,
		  @id_cliente    int = 0,
		  @folio_vta     int = 0,
		  @folio_fact    int = 0,
		  @cve_moneda    varchar(1),
		  @cve_subprod   varchar(8),
		  @imp_iva       numeric(16,2) = 0,
		  @imp_isr       numeric(16,2) = 0,
		  @imp_ieps      numeric(16,2) = 0,
		  @conta_item	 int           = 0,
		  @b_fact_ok     bit,
		  @tipo_error    varchar(1)
 
  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_cerrado     varchar(1) = 'C',
		  @k_factura     varchar(4) = 'FACT',
		  @k_error       varchar(1) = 'E',
		  @k_warning     varchar(1) = 'W',
		  @k_folio_venta varchar(4) = 'VTAF',
		  @k_fact_parc   varchar(4) = 'FPAR',
		  @k_id_uniq_fac varchar(4) = 'FACT',
		  @k_pesos       varchar(1) = 'P',
		  @k_dolar       varchar(1) = 'D',
		  @k_euro        varchar(1) = 'E',
		  @k_pesos_s     varchar(3) = 'MXN',
		  @k_dolar_s     varchar(3) = 'USD',
		  @k_euros_s     varchar(3) = 'EUR',
		  @k_no_concilia varchar(2) = 'NC',
		  @k_activa      varchar(2) = 'A',
		  @k_normal      varchar(1) = 'N',
		  @k_no_ident    varchar(4) = 'NOID',
		  @k_registrado  varchar(2) = 'RE',
		  @k_c_x_c       varchar(3) = 'CXC'


  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado

  BEGIN
  BEGIN TRY
    DECLARE @TvpComprobante TABLE
   (
    NUM_REGISTRO      int identity(1,1),
	CVE_EMPRESA       varchar (4),
	ANO_MES           varchar (6),
	CVE_TIPO          varchar (4),
	UUID              varchar (36),
	SELLO             varchar (400),
	CERTIFICADO       varchar (max),
	SERIE             varchar (6),
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
	RFC_REC,
   	RFC_EMI,
	USO_CFDI_REC,
	REG_FISCAL_EMI           
    FROM   CFDI_COMPROBANTE c, CFDI_EMISOR e, CFDI_RECEPTOR r WHERE
	c.CVE_EMPRESA   = @pCveEmpresa  AND
	c.ANO_MES       = @pAnoPeriodo  AND
	c.CVE_TIPO      = @k_factura    AND
	c.CVE_EMPRESA   = e.CVE_EMPRESA AND
	c.ANO_MES       = e.ANO_MES     AND
	c.CVE_TIPO      = e.CVE_TIPO    AND
	c.UUID          = e.UUID        AND
	c.CVE_EMPRESA   = r.CVE_EMPRESA AND
	c.ANO_MES       = r.ANO_MES     AND
	c.CVE_TIPO      = r.CVE_TIPO    AND
	c.UUID          = r.UUID        AND
	c.SIT_REGISTRO <> @k_registrado

    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

----------------------------------
--  INICIA TRANSACCION
----------------------------------
    BEGIN TRAN

    WHILE @RowCount <= @NunRegistros
    BEGIN
 
	  SELECT 
	  @cve_empresa      =    CVE_EMPRESA,
	  @ano_mes          =    ANO_MES,
	  @cve_tipo         =    CVE_TIPO,
	  @uuid             =    UUID,
	  @serie            =    SERIE,
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
	  @lugar_expedicion =    LUGAR_EXPEDICION,
	  @nombre_archivo   =    NOMBRE_ARCHIVO,
	  @rfc_rec          =    RFC_REC,
   	  @rfc_emi          =    RFC_EMI,
	  @uso_cfdi_rec     =    USO_CFDI_REC,
	  @reg_fiscal_emi   =    REG_FISCAL_EMI            
	  FROM   @TvpComprobante WHERE  NUM_REGISTRO = @RowCount

      IF  EXISTS(SELECT 1 FROM CI_CLIENTE WHERE RFC_CLIENTE  =  @rfc_rec)
	  BEGIN
	    SET @id_cliente = (SELECT TOP(1) ID_CLIENTE FROM CI_CLIENTE WHERE RFC_CLIENTE  =  @rfc_rec)
      END
	  ELSE
	  BEGIN
        SET  @id_cliente = 9999
		SET  @pError    =  'No existe RFC en Clientes ' + @rfc_rec
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--        SELECT @pMsgError
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END  

	  SET @cve_moneda  =
	  CASE
	  WHEN  @cve_moneda_s  =  @k_dolar_s
	  THEN  @k_dolar
	  WHEN  @cve_moneda_s  =  @k_pesos_s
	  THEN  @k_pesos
	  WHEN  @cve_moneda_s  =  @k_euros_s
	  THEN  @k_euro
	  END;

      SET  @imp_iva  =  0
	  SET  @imp_ieps =  0
	  SET  @imp_isr  =  0
	  
	  EXEC spCFDICalImpto @pCveEmpresa, @pCodigoUsuario, @pAnoPeriodo , @pIdProceso, @pIdTarea, @cve_tipo, @uuid, 
	       @imp_iva OUT, @imp_ieps OUT, @imp_isr OUT, @pError OUT, @pMsgError OUT 

	  SET @folio_vta = (select  NUM_FOLIO FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_folio_venta)
	  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1  WHERE CVE_FOLIO  =  @k_folio_venta

	  SET @folio_fact = (select  NUM_FOLIO FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_id_uniq_fac)
	  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1  WHERE CVE_FOLIO  =  @k_id_uniq_fac

--  Creación de Facturas

      SET @b_fact_ok  =  @k_falso
      IF  NOT EXISTS (SELECT 1 FROM CI_FACTURA  WHERE CVE_EMPRESA = @pCveEmpresa AND SERIE = @serie AND ID_CXC = CONVERT(INT,@folio))
	  BEGIN


--  Creación de Venta

        INSERT  CI_VENTA
	   (
	    ID_VENTA,
	    ID_CLIENTE,
	    ID_CLIENTE_R
	   )
	    VALUES
	   (
        @folio_vta,
	    @id_cliente,
	    @id_cliente
	   ) 

--  SELECT 'Creación de Venta Factura'

        INSERT  CI_VENTA_FACTURA 
	   (ID_VENTA,
	    ID_FACT_PARCIAL,
	    F_EST_EMISION,
	    F_COMPROMISO,
	    IMP_A_BRUTO,
	    IMP_A_IVA,
	    IMP_A_NETO,
	    CVE_A_MONEDA
	   )
	    VALUES
	   (
	    @folio_vta,
	    1,
	    CONVERT(DATE,@ft_factura),
	    NULL,
        @imp_sub_total,
	    @imp_iva,
	    @imp_total,
	    @cve_moneda
	   )

        INSERT  CI_FACTURA 
	   (
        CVE_EMPRESA,
	    SERIE,
	    ID_CXC,
	    F_OPERACION,
	    F_CAPTURA,
	    F_REAL_PAGO,
	    TIPO_CAMBIO,
	    CVE_CHEQUERA,
	    ID_VENTA,
	    ID_FACT_PARCIAL,
	    CVE_TIPO_CONTRATO,
	    CVE_F_MONEDA,
	    IMP_F_BRUTO,
	    IMP_F_IVA,
	    IMP_F_NETO,
	    CVE_R_MONEDA,
	    IMP_R_NETO_COM,
	    IMP_R_NETO,
	    TIPO_CAMBIO_LIQ,
	    TX_NOTA,
	    NOMBRE_DOCTO_PDF,
	    NOMBRE_DOCTO_XML,
	    FIRMA,
	    B_FACTURA_PAGADA,
	    ID_CONCILIA_CXC,
	    SIT_CONCILIA_CXC,
	    SIT_TRANSACCION,
	    F_COMPROMISO_PAGO,
	    TX_NOTA_COBRANZA,
	    F_CANCELACION,
	    B_FACTURA
       )
	    VALUES
	   (
	    @pCveEmpresa,
	    SUBSTRING(@serie,1,6),
	    CONVERT(INT,@folio),
	    CONVERT(DATE,@ft_factura),
	    CONVERT(DATE,@ft_factura),
	    NULL,
	    @tipo_cambio,
	    dbo.fnObtParAlfa(@cve_moneda_s),
	    @folio_vta,
	    1,
	    @k_normal,
	    @cve_moneda,
	    @imp_sub_total,
	    @imp_iva,
	    @imp_total,
	    @cve_moneda,
	    0,
	    0,
	    0,
	    ' ',
	    @k_c_x_c + @pAnoPeriodo + REPLICATE ('0',(05 - len(@folio_fact))) + CONVERT(varchar, @folio_fact) + '.PDF',
	    @k_c_x_c + @pAnoPeriodo + REPLICATE ('0',(05 - len(@folio_fact))) + CONVERT(varchar, @folio_fact) + '.XML',
        NULL,
	    @k_falso,
	    @folio_fact,
	    @k_no_concilia,
	    @k_activa,
	    NULL,
	    ' ',
	    NULL,
	    @k_falso
	   )
        SET @b_fact_ok  =  @k_verdadero
      END
      ELSE
	  BEGIN
        SET  @pError    =  'La Factura ya Existe ' +  @serie + ' ' + @folio
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        SELECT @pMsgError
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END

      IF  @b_fact_ok  =  @k_verdadero
	  BEGIN

--  Creación de ITEMS

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

          IF  EXISTS(SELECT 1 FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO  =  SUBSTRING(@no_identificacion,1,8))
	      BEGIN
	        SET @cve_subprod = (SELECT TOP(1) CVE_SUBPRODUCTO FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO  =  SUBSTRING(@no_identificacion,1,8))
          END
	      ELSE
	      BEGIN
            SET  @cve_subprod = @k_no_ident
 		    SET  @pError    =  'No existe Subproducto ' + SUBSTRING(@no_identificacion,1,8)
            SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
            SELECT @pMsgError
            INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	      END  
--		 SELECT 'ITEM'
	      INSERT INTO CI_ITEM_C_X_C 
         (
          CVE_EMPRESA,
	      SERIE ,
	      ID_CXC,
	      ID_ITEM,
	      CVE_SUBPRODUCTO ,
	      IMP_BRUTO_ITEM,
	      F_INICIO,
	      F_FIN,
	      IMP_EST_CXP,
	      IMP_REAL_CXP,
	      CVE_PROCESO1 ,
	      CVE_VENDEDOR1 ,
	      CVE_ESPECIAL1 ,
	      IMP_DESC_COMIS1,
	      IMP_COM_DIR1,
	      CVE_PROCESO2,
	      CVE_VENDEDOR2,
	      CVE_ESPECIAL2,
	      IMP_DESC_COMIS2,
	      IMP_COM_DIR2,
	      SIT_ITEM_CXC ,
	      TX_NOTA ,
	      F_FIN_INSTALACION,
	      CVE_RENOVACION,
	      CVE_EMPRESA_RENO ,
	      SERIE_RENO ,
	      ID_CXC_RENO,
	      ID_ITEM_RENO
	     ) VALUES
	     (
	      @cve_empresa,
	      SUBSTRING(@serie,1,4),
	      @folio,
	      @conta_item,
	      @cve_subprod,
          CONVERT(NUMERIC(18,2),@imp_concepto) - CONVERT(NUMERIC(18,2), @imp_descuento),
	      NULL,
	      NULL,
	      0,
	      0,
	      NULL,
	     'NOID',
	      NULL,
	      0,
	      0,
	      NULL,
	      NULL,
	      NULL,
	      0,
	      0,
	      @k_activa,
	      ' ',
	      NULL,
	      1,
	      NULL,
	      NULL,
	      NULL,
	      NULL
         )
          SET @conta_item  =   @conta_item  +  1
	      SET @RowCount1 = @RowCount1 + 1


--      SELECT * FROM @TvpError
      END

      UPDATE CFDI_COMPROBANTE  SET  SIT_REGISTRO = @k_registrado, F_REGISTRO  =  GETDATE() WHERE 
	  CVE_EMPRESA   = @pCveEmpresa  AND
	  ANO_MES       = @pAnoPeriodo  AND
	  CVE_TIPO      = @cve_tipo     AND
	  UUID          = @uuid          
    END

	IF @b_fact_ok  =  @k_verdadero
	BEGIN
      IF  @imp_sub_total  <>  (SELECT SUM(IMP_BRUTO_ITEM) FROM CI_ITEM_C_X_C WHERE CVE_EMPRESA = @pCveEmpresa AND ID_CXC = CONVERT(INT,@folio))
	  BEGIN
 	   SET  @pError    =  'No Cuadra total  ' + ISNULL(CONVERT(INT,@folio),'NULO') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
       SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
       SELECT @pMsgError
       INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END                                                                                 
	END

	SELECT @RowCount  =  @RowCount  +  1 
	END

----------------------------------
--  TERMINA TRANSACCION
----------------------------------
    COMMIT TRAN

    SET @NunRegistros2 = (SELECT COUNT(*)  FROM @TvpError)

    SET @RowCount2 =  1

    WHILE @RowCount2 <= @NunRegistros2
    BEGIN
      SELECT  @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR FROM @TvpError WHERE  RowID = @RowCount2
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @tipo_error, @pError, @pMsgError
      SET @RowCount2 =  @RowCount2  +  1
    END

    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros
--	SELECT * FROM @TvpError

  END TRY

  BEGIN CATCH

  IF  @@TRANCOUNT > 1
  BEGIN
    ROLLBACK TRAN
  END
  SET  @pError    =  'Error en genreacion de Facturas ' + ISNULL(ERROR_PROCEDURE(), ' ') 
  SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
  SELECT @pMsgError
  INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
  SET @NunRegistros2 = (SELECT COUNT(*)  FROM @TvpError)

  SET @RowCount2 =  1

  WHILE @RowCount2 <= @NunRegistros2
  BEGIN
    SELECT  @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR FROM @TvpError WHERE  RowID = @RowCount2
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @tipo_error, @pError, @pMsgError
    SET @RowCount2 =  @RowCount2  +  1
  END
--  SELECT * FROM @TvpError
  END CATCH

  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado ' + CONVERT(VARCHAR(6), @folio) + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

