USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
ALTER PROCEDURE [dbo].[spValOB_FACTURA] @pBaseDatos varchar(20), @pTipoMovto varchar(1), @pTVP OB_FACTURA READONLY, @pIdioma varchar(4)
AS
BEGIN
 
  DECLARE 
  @cve_cat_key              varchar(10),
  @cve_etiqueta             varchar(20),
  @etiqueta                 varchar(50),
  @idioma                   varchar(5)  =  @pIdioma,
  @b_existe_ref             bit,
  @num_foraneas             int = 0,
  @nom_tabla                varchar(30),
  @cve_tipo_entidad         varchar(5)
 
  DECLARE 
  @k_alta                   varchar(1)  =  'C',
  @k_modificacion           varchar(1)  =  'U',
  @k_baja                   varchar(1)  =  'D',
  @k_falso                  bit  =  0,
  @k_verdadero              bit  =  1,
  @k_tabla                  varchar(5)  =  'T',
  @k_forma                  varchar(5)  =  'F',
  @k_no_dato                varchar(1)  =  ' '
 
  IF object_id('tempdb..#TError') IS  NULL
  BEGIN
    CREATE TABLE #TError (DESC_ERROR varchar(80))
  END
  ELSE
  BEGIN
    DELETE #TError
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
--------------------------------------------------------------------------
--  Validación de Llave Unica (UQ)                                       --
--------------------------------------------------------------------------
  IF  @pTipoMovto  in  (@k_Alta)
  BEGIN
  IF EXISTS(SELECT 1 FROM CI_FACTURA WHERE 
  ID_CONCILIA_CXC          =  @id_concilia_cxc)
  BEGIN
    SET  @nom_tabla = 'CI_FACTURA'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,19,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
  END
 
  END
 
--------------------------------------------------------------------------
--  Validación de Llave Unica (PK)                                       --
--------------------------------------------------------------------------
  IF EXISTS(SELECT 1 FROM CI_FACTURA WHERE 
  CVE_EMPRESA              =  @cve_empresa  AND
  ID_CXC                   =  @id_cxc  AND
  SERIE                    =  @serie)
  BEGIN
    IF  @pTipoMovto  =  @k_alta
    BEGIN
      SET  @nom_tabla = 'CI_FACTURA'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,19,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
  ELSE
  BEGIN
    IF  @pTipoMovto  IN (@k_modificacion)
    BEGIN
      SET  @nom_tabla = 'CI_FACTURA'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,20,@idioma, @k_tabla, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
 
--------------------------------------------------------------------------
--  Validación de Llave Unica Llaves Foraneas                           --
--------------------------------------------------------------------------
 
  SET  @num_foraneas  =  3
 
-- Validación Referencia (FK) de CI_FACTURA a CI_CHEQUERA
  
  IF 
  @cve_chequera               IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_CHEQUERA WHERE 
    CVE_CHEQUERA             =  @cve_chequera)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_CHEQUERA'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
-- Validación Referencia (FK) de CI_FACTURA a CI_EMPRESA
 
  IF NOT EXISTS(SELECT 1 FROM CI_EMPRESA WHERE 
  CVE_EMPRESA              =  @cve_empresa)
  BEGIN
    SET @num_foraneas  =  @num_foraneas - 1
    IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
    BEGIN
      SET  @nom_tabla = 'CI_EMPRESA'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
 
-- Validación Referencia (FK) de CI_FACTURA a CI_VENTA_FACTURA
  
  IF 
  @id_fact_parcial            IS NOT NULL  AND
  @id_venta                   IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_VENTA_FACTURA WHERE 
    ID_FACT_PARCIAL          =  @id_fact_parcial  AND
    ID_VENTA                 =  @id_venta)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_VENTA_FACTURA'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
--------------------------------------------------------------------------
--  Validación de Campos relacionados a Catálogos                       --
--------------------------------------------------------------------------
  IF  @pTipoMovto  in  (@k_Alta, @k_modificacion)
  BEGIN
 
 
--  Validación contra catálogo campo CVE_F_MONEDA
 
  SET  @cve_cat_key  = 'MONEDA'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_f_moneda)
  BEGIN
    SET @cve_etiqueta = 'IbcveFMoneda'
    SET @etiqueta = 'Cve. Moneda'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
--  Validación contra catálogo campo CVE_TIPO_CONTRATO
 
  SET  @cve_cat_key  = 'CONTRATO'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_tipo_contrato)
  BEGIN
    SET @cve_etiqueta = 'IbTipoContrato'
    SET @etiqueta = 'Tipo Contrato'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
  END 
 
  IF  @pTipoMovto  =  @k_baja AND  @num_foraneas <> 0
  BEGIN
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos, 23, @idioma, @k_no_dato, @k_no_dato, @k_no_dato, @k_no_dato))
  END
  SET  @nom_tabla  =  'CI_FACTURA'
  EXEC spValOB_FACTURAExt @pBaseDatos, @pTipoMovto, @nom_tabla, @pTVP, @pIdioma
  SELECT DESC_ERROR FROM #TError
END