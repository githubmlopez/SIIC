USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
alter PROCEDURE [dbo].[spValOB_ITEM_C_X_C] @pBaseDatos varchar(20), @pTipoMovto varchar(1), @pTVP OB_ITEM_C_X_C READONLY, @pIdioma varchar(5)
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
  @cve_empresa              varchar(4),
  @cve_empresa_reno         varchar(4),
  @cve_especial1            varchar(2),
  @cve_especial2            varchar(2),
  @cve_proceso1             varchar(4),
  @cve_proceso2             varchar(4),
  @cve_renovacion           int,
  @cve_subproducto          varchar(8),
  @cve_vendedor1            varchar(4),
  @cve_vendedor2            varchar(4),
  @f_fin                    date,
  @f_fin_instalacion        date,
  @f_inicio                 date,
  @id_cxc                   int,
  @id_cxc_reno              int,
  @id_item                  int,
  @id_item_reno             int,
  @imp_bruto_item           numeric(12,2),
  @imp_com_dir1             numeric(12,2),
  @imp_com_dir2             numeric(12,2),
  @imp_desc_comis1          numeric(12,2),
  @imp_desc_comis2          numeric(12,2),
  @imp_est_cxp              numeric(12,2),
  @imp_real_cxp             numeric(12,2),
  @serie                    varchar(6),
  @serie_reno               varchar(6),
  @sit_item_cxc             varchar(2),
  @tx_nota                  varchar(80)
 
  SELECT  TOP(1)
  @cve_empresa               = CVE_EMPRESA,
  @cve_empresa_reno          = CVE_EMPRESA_RENO,
  @cve_especial1             = CVE_ESPECIAL1,
  @cve_especial2             = CVE_ESPECIAL2,
  @cve_proceso1              = CVE_PROCESO1,
  @cve_proceso2              = CVE_PROCESO2,
  @cve_renovacion            = CVE_RENOVACION,
  @cve_subproducto           = CVE_SUBPRODUCTO,
  @cve_vendedor1             = CVE_VENDEDOR1,
  @cve_vendedor2             = CVE_VENDEDOR2,
  @f_fin                     = F_FIN,
  @f_fin_instalacion         = F_FIN_INSTALACION,
  @f_inicio                  = F_INICIO,
  @id_cxc                    = ID_CXC,
  @id_cxc_reno               = ID_CXC_RENO,
  @id_item                   = ID_ITEM,
  @id_item_reno              = ID_ITEM_RENO,
  @imp_bruto_item            = IMP_BRUTO_ITEM,
  @imp_com_dir1              = IMP_COM_DIR1,
  @imp_com_dir2              = IMP_COM_DIR2,
  @imp_desc_comis1           = IMP_DESC_COMIS1,
  @imp_desc_comis2           = IMP_DESC_COMIS2,
  @imp_est_cxp               = IMP_EST_CXP,
  @imp_real_cxp              = IMP_REAL_CXP,
  @serie                     = SERIE,
  @serie_reno                = SERIE_RENO,
  @sit_item_cxc              = SIT_ITEM_CXC,
  @tx_nota                   = TX_NOTA
  FROM  @pTVP
--------------------------------------------------------------------------
--  Validación de Llave Unica (PK)                                       --
--------------------------------------------------------------------------
  IF EXISTS(SELECT 1 FROM CI_ITEM_C_X_C WHERE 
  CVE_EMPRESA              =  @cve_empresa  AND
  ID_CXC                   =  @id_cxc  AND
  ID_ITEM                  =  @id_item  AND
  SERIE                    =  @serie)
  BEGIN
    IF  @pTipoMovto  =  @k_alta
    BEGIN
      SET  @nom_tabla = 'CI_ITEM_C_X_C'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,19,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
  ELSE
  BEGIN
    IF  @pTipoMovto  IN (@k_modificacion)
    BEGIN
      SET  @nom_tabla = 'CI_ITEM_C_X_C'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,20,@idioma, @k_tabla, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
 
--------------------------------------------------------------------------
--  Validación de Llave Unica Llaves Foraneas                           --
--------------------------------------------------------------------------
 
  SET  @num_foraneas  =  6
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_VENDEDOR
  
  IF 
  @cve_vendedor1              IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_VENDEDOR WHERE 
    CVE_VENDEDOR             =  @cve_vendedor1)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_VENDEDOR'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_EMPRESA
 
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
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_FACTURA
 
  IF NOT EXISTS(SELECT 1 FROM CI_FACTURA WHERE 
  CVE_EMPRESA              =  @cve_empresa  AND
  ID_CXC                   =  @id_cxc  AND
  SERIE                    =  @serie)
  BEGIN
    SET @num_foraneas  =  @num_foraneas - 1
    IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
    BEGIN
      SET  @nom_tabla = 'CI_FACTURA'
      INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
    END
  END
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_SUBPRODUCTO
  
  IF 
  @cve_subproducto            IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_SUBPRODUCTO WHERE 
    CVE_SUBPRODUCTO          =  @cve_subproducto)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_SUBPRODUCTO'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_VENDEDOR
  
  IF 
  @cve_vendedor2              IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_VENDEDOR WHERE 
    CVE_VENDEDOR             =  @cve_vendedor2)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_VENDEDOR'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
-- Validación Referencia (FK) de CI_ITEM_C_X_C a CI_ITEM_C_X_C
  
  IF 
  @id_cxc_reno                IS NOT NULL  AND
  @id_item_reno               IS NOT NULL  AND
  @serie_reno                 IS NOT NULL 
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM CI_ITEM_C_X_C WHERE 
    SERIE                    =  @id_cxc_reno  AND
    ID_CXC                   =  @id_item_reno  AND
    CVE_EMPRESA              =  @serie_reno)
    BEGIN
      SET @num_foraneas  =  @num_foraneas - 1
      IF  @pTipoMovto  IN (@k_alta, @k_modificacion)
      BEGIN
        SET  @nom_tabla = 'CI_ITEM_C_X_C'
        INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,21,@idioma, @k_forma, @nom_tabla,'nom_tabla', @k_no_dato))
      END
    END
  END
 
--------------------------------------------------------------------------
--  Validación de Campos relacionados a Catálogos                       --
--------------------------------------------------------------------------
  IF  @pTipoMovto  in  (@k_Alta, @k_modificacion)
  BEGIN
 
 
--  Validación contra catálogo campo CVE_ESPECIAL1
 
  SET  @cve_cat_key  = 'CVESPECIAL'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_especial1)
  BEGIN
    SET @cve_etiqueta = 'lbcveEspecial1'
    SET @etiqueta = 'Cve Esp 1'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
--  Validación contra catálogo campo CVE_ESPECIAL2
 
  SET  @cve_cat_key  = 'CVESPECIAL'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_especial2)
  BEGIN
    SET @cve_etiqueta = 'lbcveEspecial2'
    SET @etiqueta = 'Cve Esp 2'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
--  Validación contra catálogo campo CVE_PROCESO1
 
  SET  @cve_cat_key  = 'PROCESO'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_proceso1)
  BEGIN
    SET @cve_etiqueta = 'IbCveProceso1'
    SET @etiqueta = 'Proceso 1'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
--  Validación contra catálogo campo CVE_PROCESO2
 
  SET  @cve_cat_key  = 'PROCESO'
  IF NOT EXISTS(SELECT 1 FROM INF_CAT_CATALOGO
  WHERE  BASE_DATOS  = @pBaseDatos AND 
         CVE_CATALOGO = @cve_cat_key  AND
         CVE_CAMPO    = @cve_proceso2)
  BEGIN
    SET @cve_etiqueta = 'IbCveProceso2'
    SET @etiqueta = 'Proceso 2'
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos,22, @idioma, @k_forma, @nom_tabla, @cve_etiqueta, @etiqueta))
  END
 
  END 
 
  IF  @pTipoMovto  =  @k_baja AND  @num_foraneas <> 0
  BEGIN
    INSERT #TError (DESC_ERROR) VALUES (dbo.fnObtDescError(@pBaseDatos, 23, @idioma, @k_no_dato, @k_no_dato, @k_no_dato, @k_no_dato))
  END
  SELECT DESC_ERROR FROM #TError
END