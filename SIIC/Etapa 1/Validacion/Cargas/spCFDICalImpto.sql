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

@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pUuid            varchar(36),
@pImpIva          numeric(16,2) OUT,
@pImpIeps         numeric(16,2) OUT,
@pImpIsr          numeric(16,2) OUT,
@pImpLocal        numeric(16,2) OUT,
@pImpDescuento    numeric(16,2) OUT,
@pError           varchar(80)   OUT,
@pMsgError        varchar(400)  OUT
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
           @k_ieps    varchar(3)     = '003'


  DECLARE @TvpImptoTrans TABLE
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

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImptoTrans (CVE_IMPUESTO, IMP_IMPUESTO)
  SELECT CVE_IMPUESTO, IMP_IMPUESTO FROM CFDI_TRASLADADO WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                         CVE_TIPO = @pCveTipo AND UUID = @pUuid
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TvpImptoTrans
  SET @RowCount     = 1

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

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImptoLocal (CVE_IMP_LOCAL, IMP_IMPUESTO)
  SELECT CVE_IMP_LOCAL, IMP_IMPUESTO FROM CFDI_IMP_LOCAL WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                          CVE_TIPO = @pCveTipo AND UUID = @pUuid
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------

  SET @RowCount     = 1
  SELECT * FROM @TvpImptoLocal
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_imp_local = CVE_IMP_LOCAL, @imp_impuesto = IMP_IMPUESTO
	FROM @TvpImptoLocal  WHERE NUM_REGISTRO = @RowCount

	SET  @pImpLocal  =  @pImpLocal + @imp_impuesto
	SET  @RowCount     = @RowCount + 1
  END
  SET  @pImpDescuento = 0

  IF EXISTS  (SELECT 1 FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                               CVE_TIPO = @pCveTipo AND UUID = @pUuid)
  BEGIN
    SET @pImpDescuento =
   (SELECT SUM(IMP_DESCUENTO) FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                          CVE_TIPO = @pCveTipo AND UUID = @pUuid)
END

END

