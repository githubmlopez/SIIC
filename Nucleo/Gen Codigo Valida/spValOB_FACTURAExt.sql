USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
ALTER PROCEDURE [dbo].[spValOB_FACTURAExt] @pBaseDatos varchar(20), @pTipoMovto varchar(1),
                       @pCveForma varchar(20), @pTVP OB_FACTURA READONLY, @pIdioma varchar(4)
AS
BEGIN
--  SELECT * FROM @pTVP OB_FACTURA
  DECLARE 
  @idioma                   varchar(5)  =  @pIdioma
 
  DECLARE 
  @k_alta                   varchar(1)  =  'C',
  @k_modificacion           varchar(1)  =  'M',
  @k_baja                   varchar(1)  =  'D',
  @k_activa                 varchar(1)  =  'A',
  @k_tabla                  varchar(5)  =  'T',
  @k_forma                  varchar(1)  =  'F',
  @k_falso                  bit  =  0,
  @k_verdadero              bit  =  1,
  @k_no_dato                varchar(1)  =  ' '
 
  IF object_id('tempdb..#TError') IS  NULL
  BEGIN
    CREATE TABLE #TError (DESC_ERROR varchar(80))
  END

 
  DECLARE 
  @b_factura                varchar(1),
  @b_factura_pagada         bit,
  @cve_chequera             varchar(6),
  @cve_empresa              varchar(4),
  @cve_f_moneda             varchar(1),
  @cve_r_moneda             varchar(1),
  @cve_tipo_contrato        varchar(1),
  @f_cancelacion            date,
  @f_captura                date,
  @f_compromiso_pago        date,
  @f_operacion              date,
  @f_real_pago              date,
  @firma                    varchar(10),
  @id_concilia_cxc          int,
  @id_cxc                   int,
  @id_fact_parcial          int,
  @id_venta                 int,
  @imp_f_bruto              numeric(12,2),
  @imp_f_iva                numeric(12,2),
  @imp_f_neto               numeric(12,2),
  @imp_r_neto               numeric(12,2),
  @imp_r_neto_com           numeric(12,2),
  @nombre_docto_pdf         varchar(25),
  @nombre_docto_xml         varchar(25),
  @serie                    varchar(6),
  @sit_concilia_cxc         varchar(2),
  @sit_transaccion          varchar(2),
  @tipo_cambio              numeric(8,4),
  @tipo_cambio_liq          numeric(8,4),
  @tx_nota                  varchar(400),
  @tx_nota_cobranza         varchar(200)
 
  SELECT  TOP(1)
  @b_factura                 = B_FACTURA,
  @b_factura_pagada          = B_FACTURA_PAGADA,
  @cve_chequera              = CVE_CHEQUERA,
  @cve_empresa               = CVE_EMPRESA,
  @cve_f_moneda              = CVE_F_MONEDA,
  @cve_r_moneda              = CVE_R_MONEDA,
  @cve_tipo_contrato         = CVE_TIPO_CONTRATO,
  @f_cancelacion             = F_CANCELACION,
  @f_captura                 = F_CAPTURA,
  @f_compromiso_pago         = F_COMPROMISO_PAGO,
  @f_operacion               = F_OPERACION,
  @f_real_pago               = F_REAL_PAGO,
  @firma                     = FIRMA,
  @id_concilia_cxc           = ID_CONCILIA_CXC,
  @id_cxc                    = ID_CXC,
  @id_fact_parcial           = ID_FACT_PARCIAL,
  @id_venta                  = ID_VENTA,
  @imp_f_bruto               = IMP_F_BRUTO,
  @imp_f_iva                 = IMP_F_IVA,
  @imp_f_neto                = IMP_F_NETO,
  @imp_r_neto                = IMP_R_NETO,
  @imp_r_neto_com            = IMP_R_NETO_COM,
  @nombre_docto_pdf          = NOMBRE_DOCTO_PDF,
  @nombre_docto_xml          = NOMBRE_DOCTO_XML,
  @serie                     = SERIE,
  @sit_concilia_cxc          = SIT_CONCILIA_CXC,
  @sit_transaccion           = SIT_TRANSACCION,
  @tipo_cambio               = TIPO_CAMBIO,
  @tipo_cambio_liq           = TIPO_CAMBIO_LIQ,
  @tx_nota                   = TX_NOTA,
  @tx_nota_cobranza          = TX_NOTA_COBRANZA
  FROM  @pTVP

  BEGIN
  DECLARE @nom_tabla    varchar(20),
          @nom_campo    varchar(20),
		  @cve_etiqueta varchar(30),
		  @tx_etiqueta  varchar(50),
		  @etiqueta     varchar(30)

  IF  @pTipoMovto  =  @k_alta
  BEGIN
	IF   @f_real_pago  IS NOT NULL 
	BEGIN
	  SET    @nom_campo    =  'F_REAL_PAGO'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato
	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo
--SELECT @pCveForma
--SELECT @nom_campo
--SELECT @pBaseDatos
--SELECT @idioma
--SELECT @k_forma
--SELECT @cve_etiqueta
--SELECT @tx_etiqueta

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24
	END

    IF  (@imp_f_bruto +  @imp_f_iva) <>   @imp_f_neto
	BEGIN
	  SET   @nom_campo  =  'IMP_F_NETO'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 25, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El  @1 no corresponde al bruto y al IVA 25
	END

	IF   @cve_r_moneda  IS NOT NULL 
	BEGIN
	  SET   @nom_campo  =  'CVE_R_MONEDA'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24
	END

	IF   @imp_r_neto_com  IS NOT NULL 
	BEGIN
	  SET   @nom_campo  =  'IMP_R_NETO_COM'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24
	END

	IF   @imp_r_neto  IS NOT NULL 
	BEGIN
	  SET   @nom_campo  =  'IMP_R_NETO'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24
	END

	IF   @tipo_cambio_liq  IS NOT NULL 
	BEGIN
	  SET   @nom_campo  =  'TIPO_CAMBIO_LIQ'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24
	END

	IF   @f_cancelacion  IS NOT NULL 
	BEGIN
	  SET    @nom_campo     =  'F_CANCELACION'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 24, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 no debe tener informacion en alta 24

	END

    IF   @sit_transaccion  <>  @k_activa  
	BEGIN
	  SET   @nom_campo  =  'SIT_TRANSACCION'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 26, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El campo @1 debe ser A en alta 26
	END
  END

  IF  @pTipoMovto  =  @k_modificacion
  BEGIN
	IF   @f_real_pago  >  @f_operacion 
	BEGIN
	  SET   @nom_campo  =  'F_REAL_PAGO'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 27, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- La @1 es incorrecta  27
	END

    IF  (@imp_f_bruto +  @imp_f_iva) <>   @imp_f_neto
	BEGIN
	  SET   @nom_campo  =  'IMP_F_NETO'
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 25, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- El  @1 no corresponde al bruto y al IVA 25
	END

	IF   @f_cancelacion   >  @f_operacion 
	BEGIN
	  SET   @nom_campo  =  'F_CANCELACION'
	  SELECT @cve_etiqueta =  CVE_ETIQUETA, @tx_etiqueta =  TX_ETIQUETA  FROM INF_FORMA_DET
	         WHERE BASE_DATOS = @pBaseDatos  AND
	               CVE_FORMA  =  @pCveForma  AND NOM_CAMPO_DB = @nom_campo
	  SET    @cve_etiqueta =  @k_no_dato 
	  SET    @tx_etiqueta  =  @k_no_dato

      INSERT #TError (DESC_ERROR) VALUES 
	  (dbo.fnObtDescError(@pBaseDatos, 27, @idioma, @k_forma, @pCveForma, @cve_etiqueta, @tx_etiqueta))
-- La @1 es incorrecta  27
	END
  END

END
-- select * from #TError   
END