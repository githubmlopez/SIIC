USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdProdServ')
BEGIN
  DROP  PROCEDURE spCfdInCfdProdServ
END
GO
--EXEC spCfdInCfdProdServ 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdProdServ
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pHdoc            int,
@pUuid            varchar(36),
@pCveTipo         varchar(4),
@pBError          bit          OUT,
@pError           varchar(80)  OUT, 
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @seccion      varchar(20)

  DECLARE @k_verdadero  varchar(1)  = '1',
          @k_error      varchar(1)  = 'E'

  BEGIN TRY

---------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Productos y Servicios                                                                --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Productos'
	
  INSERT INTO CFDI_PROD_SERV
 (
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
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  ID_NODO,
  ISNULL(CVE_PROD_SERV, ' '),
  ISNULL(CANTIDAD,0),
  ISNULL(CVE_UNIDAD, ' '),
  ISNULL(DESCRIPCION, ' '), 
  ISNULL(VALOR_UNITARIO,0),
  ISNULL(IMPORTE_C,0),
  ISNULL(IMP_DESCUENTO,0),
  ISNULL(NO_IDENTIFICACION,' ')
  FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto',2)
  WITH 
(
  ID_NODO INT '@mp:id',
  CVE_PROD_SERV [varchar](8) '@ClaveProdServ',
  CANTIDAD [NUMERIC](18,6) '@Cantidad',
  CVE_UNIDAD [varchar](3) '@ClaveUnidad',
  DESCRIPCION [varchar](max) '@Descripcion',
  VALOR_UNITARIO [NUMERIC](18,6) '@ValorUnitario',
  IMPORTE_C [NUMERIC](18,6) '@Importe',
  IMP_DESCUENTO [NUMERIC](18,6) '@Descuento',
  NO_IDENTIFICACION [varchar](100) '@NoIdentificacion'
 )
 
  END TRY

  BEGIN CATCH
	SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END