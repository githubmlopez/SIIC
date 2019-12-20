USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCFDICalImptoI')
BEGIN
  DROP  PROCEDURE spCFDICalImptoI
END
GO
--EXEC spCFDICalImptoI 'CU','MARIO','201906',104,1, 'FACT', 
--'isJhlk/EsLUWIpI2x7g2r033pX1VnWK58Ce+n4/HTHAbUyEXF22QRcsDGBSQWNM9lwDMOM9qNpjP7Qv+wuMxXUtt33NbvQfSdLzaZHKpZzg3ZYveG2bY7KHtCpmWtnEHpxHTcTLFgVFSM9qJKk3mwGJ4h4LhEotTBsqkDZBGKwDqUmSa7cn7ar03Z3eI60b1rj52RlVa/by+JxQxmkCWrONMUFHnoRypn06QbIXCQMGKStPNMfJvL/rmwwvaK3+2J22Plr+T2zFkBlj7ugt0VFsQQ23jTMDP40NnlRUVX1V0by5mgPoZDSwNfy/b6KMmWStyHF7JglUvB3/RUo9Hdg==',
--0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spCFDICalImptoI]
(

@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pUuid            varchar(36),
@pIdConcepto      int,
@pIdOrden         int,
@pImpIva          numeric(16,2) OUT,
@pImpIeps         numeric(16,2) OUT,
@pImpIsr          numeric(16,2) OUT,
@PimpDescuento    numeric(16,2) OUT,
@pError           varchar(80)   OUT,
@pMsgError        varchar(400)  OUT
)
AS
BEGIN
  DECLARE  @cve_impuesto  varchar(3),
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

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TvpImptoTrans (CVE_IMPUESTO, IMP_IMPUESTO)
  SELECT CVE_IMPUESTO, IMP_IMPUESTO FROM CFDI_TRASLADADO WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                         CVE_TIPO  = @pCveTipo AND UUID = @pUuid AND  ID_CONCEPTO = @pIdConcepto  AND
										 ID_ORDEN  = @pIdOrden
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------

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

  SET  @pImpDescuento = 0

  IF EXISTS  (SELECT 1 FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                                 CVE_TIPO = @pCveTipo AND UUID = @pUuid  AND ID_CONCEPTO = @pIdConcepto)
  BEGIN
    SET @pImpDescuento =
   (SELECT SUM(IMP_DESCUENTO) FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                   CVE_TIPO = @pCveTipo AND UUID = @pUuid)
  END

END
