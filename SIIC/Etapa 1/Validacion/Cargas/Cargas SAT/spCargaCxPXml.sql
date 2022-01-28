USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaCxPXml')
BEGIN
  DROP  PROCEDURE spCargaCxPXml
END
GO

--EXEC spCargaCxPXml 1,'CU','MARIO','SIIC', '202002',24,46,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCargaCxPXml]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pBError        bit OUT,
@pError         varchar(80) OUT, 
@pMsgError      varchar(400) OUT

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
 		  @id_nodo           int,
	      @sello             varchar(400),
	      @certificado       varchar(max),
	      @folio             varchar(40),
	      @ft_factura        datetime,
	      @ft_timbrado       datetime,
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
	      @serie             varchar(20),
	      @rfc_rec           varchar(15),
   	      @rfc_emi           varchar(15),
	      @uso_cfdi_rec      varchar(4),
	      @reg_fiscal_emi    varchar(3)

  DECLARE
	      @id_concepto       int,
		  @id_orden          int,
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
		  @id_proveedor  int = 0,
		  @cve_moneda    varchar(1),
		  @cve_subprod   varchar(8),
		  @forma_pago_s  varchar(1),
		  @imp_iva       numeric(16,2) = 0,
		  @imp_isr       numeric(16,2) = 0,
		  @imp_iva_r     numeric(16,2) = 0,
		  @imp_isr_r     numeric(16,2) = 0,
		  @imp_ieps      numeric(16,2) = 0,
		  @imp_local     numeric(16,2) = 0,
		  @folio_cxp     int  =  0,
		  @folio_cxp_u   int  =  0,
		  @conta_item	 int  = 0,
		  @b_cxp_ok      bit,
		  @tipo_error    varchar(1),
		  @cve_operacion varchar(4),
		  @tabla_ins     varchar(3)
 
  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_cerrado     varchar(1) = 'C',
		  @k_error       varchar(1) = 'E',
		  @k_warning     varchar(1) = 'W',
		  @k_id_uniq_cxc varchar(4) = 'CXPU',
		  @k_pesos       varchar(1) = 'P',
		  @k_dolar       varchar(1) = 'D',
		  @k_euro        varchar(1) = 'E',
		  @k_pesos_s     varchar(3) = 'MXN',
		  @k_dolar_s     varchar(3) = 'USD',
		  @k_euros_s     varchar(3) = 'EUR',
		  @k_no_concilia varchar(2) = 'NC',
		  @k_activa      varchar(2) = 'A',
		  @k_normal      varchar(1) = 'N',
		  @k_no_identif  varchar(1) = 'N',
		  @k_no_ident    varchar(4) = 'NOID',
          @K_registrado  varchar(2) = 'RE',
		  @k_c_x_p       varchar(3) = 'CXP',
          @k_item        varchar(3) = 'ITM',
		  @k_efectivo    varchar(2) = '01',
		  @k_cheque      varchar(2) = '02',
		  @k_transfer    varchar(2) = '03',
		  @k_tarj_cred   varchar(2) = '04',
		  @k_monedero    varchar(2) = '05',
		  @k_efectivo_s  varchar(1) = 'E',
		  @k_cheque_s    varchar(1) = 'C',
		  @k_transfer_s  varchar(1) = 'T',
		  @k_ingreso     varchar(1) = 'I'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado

  BEGIN

    DECLARE @TvpComprobante TABLE
   (
    NUM_REGISTRO      int identity(1,1),
	CVE_EMPRESA       varchar (4),
	ANO_MES           varchar (6),
	CVE_TIPO          varchar (4),
	UUID              varchar (36),
	SELLO             varchar (400),
	CERTIFICADO       varchar (max),
	SERIE             varchar (25),
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
	FT_TIMBRADO       datetime,
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
	c.CERTIFICADO,
	c.SERIE,
	c.FOLIO,
	c.FT_FACTURA,
	c.FORMA_PAGO,
	c.CONDICIONES_PAGO,
	c.IMP_SUB_TOTAL,
	c.IMP_DESCUENTO,
	c.CVE_MONEDA,
	c.TIPO_CAMBIO,
	c.IMP_TOTAL,
	c.CVE_TIPO_COMPROB,
	c.CVE_METODO_PAGO,
	c.LUGAR_EXPEDICION,
	c.NOMBRE_ARCHIVO,
    c.FT_TIMBRADO,
	r.RFC_REC,
   	e.RFC_EMI,
	r.USO_CFDI_REC,
	e.REG_FISCAL_EMI           
    FROM   CFDI_COMPROBANTE c, CFDI_EMISOR e, CFDI_RECEPTOR r WHERE
	c.CVE_EMPRESA   = @pCveEmpresa  AND
	c.ANO_MES       = @pAnoPeriodo  AND
	c.CVE_TIPO      = @k_c_x_p      AND
	c.CVE_EMPRESA   = e.CVE_EMPRESA AND
	c.ANO_MES       = e.ANO_MES     AND
	c.CVE_TIPO      = e.CVE_TIPO    AND
	c.UUID          = e.UUID        AND
	c.CVE_EMPRESA   = r.CVE_EMPRESA AND
	c.ANO_MES       = r.ANO_MES     AND
	c.CVE_TIPO      = r.CVE_TIPO    AND
	c.UUID          = r.UUID        AND
	c.SIT_REGISTRO <> @k_registrado AND
	c.CVE_TIPO_COMPROB = @k_ingreso

    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SELECT * FROM @TvpComprobante
    SET @RowCount     = 1
----------------------------------
--  INICIA TRANSACCION
----------------------------------
    BEGIN TRAN

    WHILE @RowCount <= @NunRegistros
    BEGIN
      BEGIN TRY
 
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
	  @ft_timbrado      =    FT_TIMBRADO,
	  @rfc_rec          =    RFC_REC,
   	  @rfc_emi          =    RFC_EMI,
	  @uso_cfdi_rec     =    USO_CFDI_REC,
	  @reg_fiscal_emi   =    REG_FISCAL_EMI            
	  FROM   @TvpComprobante WHERE  NUM_REGISTRO = @RowCount

      IF  EXISTS(SELECT 1 FROM CI_PROVEEDOR  WHERE  CVE_EMPRESA = @pCveEmpresa  AND  RFC  =  @rfc_emi)
	  BEGIN
	    SET @id_proveedor = (SELECT TOP(1) ID_PROVEEDOR FROM CI_PROVEEDOR WHERE CVE_EMPRESA  =  @PcVEeMPRESA  AND RFC  =  @rfc_emi)
      END
	  ELSE
	  BEGIN
        SET  @id_proveedor = 9999
		SET  @pError    =  '(W) No Existe RFC Prov ' + ISNULL(@rfc_emi,'NULO')
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
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

      IF  ISNULL(@cve_moneda,' ') NOT IN (@k_dolar,@k_pesos,@k_euro)
	  BEGIN
        SET  @cve_moneda = @k_no_identif
		SET  @pError     =  '(W) Moneda no soportada ' + ISNULL(@cve_moneda_s,'NULO') + ' ' + @uuid 
        SET  @pMsgError  =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END
	  
	  SET @forma_pago_s  =
	  CASE
	  WHEN  @forma_pago  =  @k_efectivo
	  THEN  @k_efectivo_s
	  WHEN  @forma_pago  =  @k_cheque
	  THEN  @k_cheque_s
	  WHEN  @forma_pago  =  @k_transfer
	  THEN  @k_transfer_s
	  END;
      IF  ISNULL(@forma_pago_s,' ') NOT IN (@k_efectivo_s,@k_cheque_s,@k_transfer_s, @k_tarj_cred, @k_monedero)
	  BEGIN
		SET  @forma_pago_s  =  @k_no_identif
		SET  @pError    =  '(W) Forma Pago Invalida ' + ISNULL(@forma_pago,'NULO') + ' ' + @uuid 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END

      IF  @forma_pago_s  =  @k_cheque  AND  
         (SELECT B_CHEQUE FROM CI_CHEQUERA WHERE CVE_CHEQUERA = dbo.fnObtParAlfa(@pCveEmpresa, @cve_moneda_s)) = @k_falso 
      BEGIN
		SET  @pError    =  '(W) Chequera no acepta CH ' + ISNULL(dbo.fnObtParAlfa(@pCveEmpresa, @cve_moneda_s),'NULO') + ' ' + @uuid
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
      END 
      SET  @tabla_ins  =  'I2'

      SET  @imp_iva       =  0
	  SET  @imp_ieps      =  0
	  SET  @imp_isr       =  0
	  SET  @imp_local     =  0
	  SET  @imp_descuento =  0
	  SET  @imp_iva       =  0
	  SET  @imp_isr_r     =  0

	  EXEC spCFDICalImpto @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo,
	                      @pIdProceso, @pFolioExe, @pIdTarea, @cve_tipo, @uuid, @imp_iva OUT, @imp_iva_r OUT, @imp_ieps OUT,
						  @imp_isr OUT, @imp_isr_r OUT, @imp_local OUT, @pBError, @pError OUT, @pMsgError OUT 

      SET  @folio_cxp_u  = NEXT VALUE FOR SEQ_CXC_ID_CONC_CXP

--  Creación de Cuenta por pagar 

  --    SET @b_cxc_ok  =  @k_falso
--	  SELECT @uuid
	 -- IF  @uuid = '04b48929-8695-47f4-8033-a369efcec8f5'
	 -- BEGIN
	 --   SELECT 'IB ' + CONVERT(VARCHAR(20), @imp_sub_total)
		--SELECT 'IV ' + CONVERT(VARCHAR(20), @imp_iva)
		--SELECT 'IN ' + CONVERT(VARCHAR(20), @imp_total)
	 -- END

	  SET  @tabla_ins  =  @k_c_x_p
      INSERT  CI_CUENTA_X_PAGAR 
     (
      CVE_EMPRESA,
	  UUID,
	  ID_PROVEEDOR,
	  CVE_CHEQUERA,
	  CVE_TIPO_FACTURA,
	  F_OPERACION,
	  F_CAPTURA,
	  F_CANCELACION,
	  F_PAGO,
	  IMP_BRUTO,
	  IMP_IVA,
	  IMP_NETO,
	  CVE_MONEDA,
	  TIPO_CAMBIO,
	  CVE_FORMA_PAGO,
	  NUM_CHEQUE,
	  NUM_DOCTO_REF,
	  REFER_PAGO,
	  TX_NOTA,
	  NOMBRE_DOCTO_PDF,
	  NOMBRE_DOCTO_XML,
	  ID_CONCILIA_CXP,
	  SIT_CONCILIA_CXP,
	  SIT_C_X_P,
	  CVE_MOT_CONCIL,
	  SERIE_PROV,
	  FOLIO_PROV,
	  ANOMES_CONT,
	  ANO_MES_PAGO,
	  ANO_MES,
	  IMP_ISR_RET,
	  IMP_IVA_RET,
	  IMP_IEPS,
	  IMP_LOCAL
     )
	  VALUES
	(
	  @pCveEmpresa,
	  @uuid,
	  @id_proveedor,
	  ISNULL(SUBSTRING(dbo.fnObtParAlfa(@pCveEmpresa, @cve_moneda_s),1,6),@k_no_identif),
      @k_c_x_p,
	  CONVERT(DATE,@ft_timbrado),
	  CONVERT(DATE,@ft_timbrado),
      NULL,
	  NULL,
	  @imp_sub_total,
	  @imp_iva,
	  @imp_total,
	  @cve_moneda,
	  @tipo_cambio,
      @forma_pago_s,
	  null,
	  null,
	  null,
	  null,
	  @k_c_x_p + REPLICATE ('0',(05 - len(@folio_cxp_u))) + CONVERT(varchar, @folio_cxp_u) + '.PDF',
	  @k_c_x_p + REPLICATE ('0',(05 - len(@folio_cxp_u))) + CONVERT(varchar, @folio_cxp_u) + '.XML',
	  @folio_cxp_u,
	  @k_no_concilia,
	  @k_activa,
	  NULL,
	  @serie,
	  @folio,
      NULL,
	  NULL,
	  @pAnoPeriodo,
	  @imp_isr_r,
	  @imp_iva_r,
	  @imp_ieps,
	  @imp_local
     )

--  Creación de ITEMS

     DECLARE @TvpProdServ TABLE
    (
	 NUM_REGISTRO      int identity(1,1),
	 CVE_EMPRESA       varchar (4),
	 ANO_MES           varchar (6),
	 CVE_TIPO          varchar (4),
	 UUID              varchar (36),
	 ID_NODO           int,
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
	  ID_NODO,
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
 
      SET  @conta_item  =   NEXT VALUE FOR SEQ_ITEM_CXP 
      WHILE @RowCount1 <= @NunRegistros1
      BEGIN
        SELECT 
        @cve_empresa        =  CVE_EMPRESA,
	    @ano_mes            =  ANO_MES,
	    @cve_tipo           =  CVE_TIPO,
	    @uuid               =  UUID,
	    @id_nodo            =  ID_NODO,
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

	    SET  @imp_descuento = 0

 	    EXEC spCFDICalImptoI @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo , @pIdProceso, @pFolioExe, 
		                     @pIdTarea, @cve_tipo, @uuid, @id_nodo, @imp_descuento OUT, @pError OUT, @pMsgError OUT 

	    SET  @cve_operacion = ISNULL(dbo.fnObtCveOper(@pCveEmpresa, @pAnoPeriodo, @uuid, @cve_prod_serv),' ')

		IF  @cve_operacion  =  ' ' 
		BEGIN
		  SET @cve_operacion  =  @k_no_ident 
		END

		SET  @tabla_ins  =  @k_item

 	    INSERT INTO CI_ITEM_C_X_P
       (
        CVE_EMPRESA,
		UUID,
	    ID_CXP_DET,
	    CVE_OPERACION,
	    IMP_BRUTO,
	    TX_NOTA,
		IMP_DESCUENTO,
		IMP_DEDUCIBLE,
		IMP_DEDUC_CAL,
		CVE_OPER_ASIG
	   ) VALUES
	   (
	    @cve_empresa,
	    @uuid,
	    @conta_item,
	    @cve_operacion,
	    @imp_concepto,
	    ' ',
		@imp_descuento,
        0,
		0,
		@cve_operacion
       )

        SET @conta_item  =   NEXT VALUE FOR SEQ_ITEM_CXP 
	    SET @RowCount1 = @RowCount1 + 1
--    SELECT * FROM @TvpError

      END


      UPDATE CFDI_COMPROBANTE  SET  SIT_REGISTRO = @k_registrado, F_REGISTRO  =  GETDATE() WHERE 
	  CVE_EMPRESA   = @pCveEmpresa  AND
	  ANO_MES       = @pAnoPeriodo  AND
	  CVE_TIPO      = @cve_tipo     AND
	  UUID          = @uuid          

      IF  @imp_sub_total  <>  (SELECT SUM(IMP_BRUTO_ITEM) FROM CI_ITEM_C_X_C WHERE CVE_EMPRESA = @pCveEmpresa AND UUID = @uuid)
      BEGIN
 	    SET  @pError    =  '(E) No Cuadra total  ' + ISNULL(@uuid,'NULO')  
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	  END                                                                                 

	  END TRY

      BEGIN CATCH
      IF  @@TRANCOUNT <> 0  OR  XACT_STATE() = -1
      BEGIN
        ROLLBACK TRAN 
      END

      SET  @pBError    =  @k_verdadero

      SET  @pError    =  '(E) Genreacion de  ' + @tabla_ins
      SET  @pMsgError =  @pError +  ' ' + ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
 
      END CATCH

      SELECT @RowCount  =  @RowCount  +  1 
    
    END

----------------------------------
--  TERMINA TRANSACCION
----------------------------------
    IF  @@TRANCOUNT >= 1
    BEGIN
      IF  @pBError  =  1
	  BEGIN
	    ROLLBACK TRAN
	  END
	  ELSE
	  BEGIN
        COMMIT TRAN
      END
    END

    SET @NunRegistros2 = (SELECT COUNT(*)  FROM @TvpError)

	IF  @NunRegistros2 >  0
	BEGIN
	  SET  @pBError  =  @k_verdadero
	END

    SET @RowCount2 =  1

    WHILE @RowCount2 <= @NunRegistros2
    BEGIN
      SELECT  @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR FROM @TvpError WHERE  RowID = @RowCount2
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @tipo_error, @pError, @pMsgError
      SET @RowCount2 =  @RowCount2  +  1
    END

--    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros
--	SELECT * FROM @TvpError
  END
  ELSE
  BEGIN
    SET  @pBError  =  @k_verdadero
    SET  @pError    =  '(E) Periodo esta cerrado ' + ISNULL(@pAnoPeriodo, 'NULO')
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

