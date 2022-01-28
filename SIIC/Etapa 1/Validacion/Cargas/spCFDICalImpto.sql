USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCFDICalImpto')
BEGIN
  DROP  PROCEDURE spCFDICalImpto
END
GO
--EXEC spCFDICalImpto 'CU','MARIO','201906',104,1, 'FACT', 
--'06C7C9DA-BADF-49E7-9A42-3D7A289FD4EC',
--0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spCFDICalImpto]
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
@pUuid            varchar(36),
@pImpIva          numeric(16,2) OUT,
@pImpIva_r        numeric(16,2) OUT,
@pImpIeps         numeric(16,2) OUT,
@pImpIsr          numeric(16,2) OUT,
@pImpIsr_r        numeric(16,2) OUT,
@pImpLocal        numeric(16,2) OUT,
@pBError          bit OUT,
@pError           varchar(80) OUT, 
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @cve_impuesto  varchar(3),
           @cve_imp_local varchar(3),
           @imp_impuesto  numeric(18,6) = 0,
  		   @NunRegistros  int = 0, 
		   @RowCount      int = 0

  DECLARE  @k_isr     varchar(3)     = '001',
           @k_iva     varchar(3)     = '002',
           @k_ieps    varchar(3)     = '003',
           @k_isr_r   varchar(3)     = '001',
           @k_iva_r   varchar(3)     = '002'

  DECLARE @TvpImptoTrans TABLE
 (
  NUM_REGISTRO  int identity(1,1),
  CVE_IMPUESTO  varchar(3),
  IMP_IMPUESTO  numeric(18,6)
 )

  DECLARE @TvpImpRetenido TABLE
 (
  NUM_REGISTRO  int identity(1,1),
  CVE_IMPUESTO  varchar(3),
  IMP_IMPUESTO  numeric(18,6)
 )

  DECLARE @TvpImptoLocal TABLE
 (
  NUM_REGISTRO  int identity(1,1),
  CVE_IMP_LOCAL varchar(3),
  IMP_IMPUESTO  numeric(18,6)
 )

 ---------------------------------------
 --  CALCULO DE IMPUESTOS TRASLADADOS --
 ---------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImptoTrans (CVE_IMPUESTO, IMP_IMPUESTO)
  SELECT t.CVE_IMPUESTO, t.IMP_IMPUESTO FROM
  CFDI_COMPROBANTE c , CFDI_PROD_SERV p, CFDI_IMPUESTO_S ms, CFDI_TRASLADO_S ts, CFDI_TRASLADO t  WHERE
  c.UUID          =  @pUuid          AND
  c.CVE_EMPRESA   =  p.CVE_EMPRESA   AND
  c.ANO_MES       =  p.ANO_MES       AND
  c.CVE_TIPO      =  p.CVE_TIPO      AND
  c.UUID          =  p.UUID          AND

  p.CVE_EMPRESA   =  ms.CVE_EMPRESA  AND
  p.ANO_MES       =  ms.ANO_MES      AND
  p.CVE_TIPO      =  ms.CVE_TIPO     AND
  p.UUID          =  ms.UUID         AND
  p.ID_NODO       =  ms.ID_NODO_P    AND

  ms.CVE_EMPRESA  =  ts.CVE_EMPRESA  AND
  ms.ANO_MES      =  ts.ANO_MES      AND
  ms.CVE_TIPO     =  ts.CVE_TIPO     AND
  ms.UUID         =  ts.UUID         AND
  ms.ID_NODO      =  ts.ID_NODO_P    AND

  ts.CVE_EMPRESA  =  t.CVE_EMPRESA   AND
  ts.ANO_MES      =  t.ANO_MES       AND
  ts.CVE_TIPO     =  t.CVE_TIPO      AND
  ts.UUID         =  t.UUID          AND
  ts.ID_NODO      =  t.ID_NODO_P
--  SELECT * FROM   @TvpImptoTrans
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
--  SELECT * FROM @TvpImptoTrans
  SET @RowCount     = 1

  SET  @pImpIsr  =  0
  SET  @pImpIva  =  0
  SET  @pImpIeps =  0


  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_impuesto = CVE_IMPUESTO, @imp_impuesto = IMP_IMPUESTO
	FROM @TvpImptoTrans  WHERE NUM_REGISTRO = @RowCount
    IF  @cve_impuesto =  @k_isr
	BEGIN
      SET  @pImpIsr =  @pImpIsr + @imp_impuesto 
	END
	ELSE
	IF  @cve_impuesto =  @k_iva
	BEGIN
      SET  @pImpIva =  @pImpIva + @imp_impuesto 
	END
	ELSE
	IF  @cve_impuesto =  @k_ieps
	BEGIN
      SET  @pImpIeps =  @pImpIeps + @imp_impuesto 
	END
	SET @RowCount     = @RowCount + 1
  END

 ---------------------------------------
 --  CALCULO DE IMPUESTOS RETENIDOS   --
 ---------------------------------------

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImpRetenido (CVE_IMPUESTO, IMP_IMPUESTO)
  SELECT r.CVE_IMPUESTO, r.IMP_IMPUESTO FROM
  CFDI_COMPROBANTE c , CFDI_PROD_SERV p, CFDI_IMPUESTO_S ms, CFDI_RETENCION_S rs, CFDI_RETENCION r  WHERE
  c.UUID          =  @pUuid          AND
  c.CVE_EMPRESA   =  p.CVE_EMPRESA   AND
  c.ANO_MES       =  p.ANO_MES       AND
  c.CVE_TIPO      =  p.CVE_TIPO      AND
  c.UUID          =  p.UUID          AND

  p.CVE_EMPRESA   =  ms.CVE_EMPRESA  AND
  p.ANO_MES       =  ms.ANO_MES      AND
  p.CVE_TIPO      =  ms.CVE_TIPO     AND
  p.UUID          =  ms.UUID         AND
  p.ID_NODO       =  ms.ID_NODO_P    AND

  ms.CVE_EMPRESA  =  rs.CVE_EMPRESA  AND
  ms.ANO_MES      =  rs.ANO_MES      AND
  ms.CVE_TIPO     =  rs.CVE_TIPO     AND
  ms.UUID         =  rs.UUID         AND
  ms.ID_NODO      =  rs.ID_NODO_P    AND

  rs.CVE_EMPRESA  =  r.CVE_EMPRESA   AND
  rs.ANO_MES      =  r.ANO_MES       AND
  rs.CVE_TIPO     =  r.CVE_TIPO      AND
  rs.UUID         =  r.UUID          AND
  rs.ID_NODO      =  r.ID_NODO_P     

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
--  SELECT * FROM @TvpImptoTrans
  SET @RowCount     = 1

  SET  @pImpIsr_r  = 0
  SET  @pImpIva_r  = 0

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_impuesto = CVE_IMPUESTO, @imp_impuesto = IMP_IMPUESTO
	FROM @TvpImptoTrans  WHERE NUM_REGISTRO = @RowCount

	--IF  @pUuid  =  '4D7AA124-5D58-4FF1-9878-76705369E453'
	--BEGIN
	--  SELECT  @cve_impuesto  +  ' ' + CONVERT(VARCHAR(20), @imp_impuesto)
	--END

    IF  @cve_impuesto =  @k_isr
	BEGIN
      SET  @pImpIsr_r =  @pImpIsr + @imp_impuesto 
	END
	ELSE
	IF  @cve_impuesto =  @k_iva
	BEGIN
      SET  @pImpIva_r =  @pImpIva + @imp_impuesto 
	END
	SET @RowCount     = @RowCount + 1
  END

---------------------------------------
--  CALCULO DE IMPUESTOS LOCALES     --
---------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImptoLocal (CVE_IMP_LOCAL, IMP_IMPUESTO)
  SELECT l.CVE_IMP_LOCAL, l.IMP_IMPUESTO FROM
  CFDI_COMPROBANTE c , CFDI_COMPLEMENTO cm, CFDI_IMP_LOCAL_S ls, CFDI_IMP_LOCAL l  WHERE
  c.UUID          =  @pUuid           AND
  c.CVE_EMPRESA   =  cm.CVE_EMPRESA   AND
  c.ANO_MES       =  cm.ANO_MES       AND
  c.CVE_TIPO      =  cm.CVE_TIPO      AND
  c.UUID          =  cm.UUID          AND

  cm.CVE_EMPRESA  =  ls.CVE_EMPRESA   AND
  cm.ANO_MES      =  ls.ANO_MES       AND
  cm.CVE_TIPO     =  ls.CVE_TIPO      AND
  cm.UUID         =  ls.UUID          AND
  cm.ID_NODO      =  ls.ID_NODO_P     AND

  ls.CVE_EMPRESA  =  l.CVE_EMPRESA    AND
  ls.ANO_MES      =  l.ANO_MES        AND
  ls.CVE_TIPO     =  l.CVE_TIPO       AND
  ls.UUID         =  l.UUID           AND
  ls.ID_NODO      =  l.ID_NODO_P     

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------

  SET @RowCount     = 1
  -- SELECT * FROM @TvpImptoLocal

  SET  @pImpLocal  =  0

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_imp_local = CVE_IMP_LOCAL, @imp_impuesto = IMP_IMPUESTO
	FROM @TvpImptoLocal  WHERE NUM_REGISTRO = @RowCount

	SET  @pImpLocal  =  @pImpLocal + @imp_impuesto
	SET  @RowCount   = @RowCount + 1
  END

END

