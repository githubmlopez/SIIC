USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdPagoRelac')
BEGIN
  DROP  PROCEDURE spCfdInCfdPagoRelac
END
GO
--EXEC spCfdInCfdPagoRelac 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdPagoRelac
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

----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Pago                                                                --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Pag Relacionado'
	
  INSERT intO CFDI_PAGO_RELAC
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  ID_NODO,
  ID_NODO_P,
  UUID_REL,
  NUM_PARCIALIDAD,
  SERIE,
  IMP_SDO_INSOLUTO,
  IMP_PAGADO,
  IMP_SDO_ANT,
  CVE_METODO_PAGO,
  CVE_MONEDA,
  FOLIO
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  ID_NODO,
  ID_NODO_P,
  UUID_REL,
  ISNULL(NUM_PARCIALIDAD,0),
  ISNULL(SERIE,' '),
  ISNULL(IMP_SDO_INSOLUTO,0),
  ISNULL(IMP_PAGADO,0),
  ISNULL(IMP_SDO_ANT,0),
  ISNULL(CVE_METODO_PAGO,' '),
  ISNULL(CVE_MONEDA,' '),
  ISNULL(FOLIO,' ')
  FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado',2)
  WITH 
 (
  ID_NODO          int '@mp:id',
  ID_NODO_P        int '@mp:parentid',
  UUID_REL         varchar(36) '@IdDocumento',
  NUM_PARCIALIDAD  int '@NumParcialidad',
  SERIE            varchar(25) '@Serie',
  IMP_SDO_INSOLUTO numeric(18,6) '@ImpSaldoInsoluto',
  IMP_PAGADO       numeric(18,6) '@ImpPagado',
  IMP_SDO_ANT      numeric(18,6) '@ImpSaldoAnt',
  CVE_METODO_PAGO  varchar(3) '@MetodoDePagoDR',
  CVE_MONEDA       varchar(3) '@MonedaDR',
  FOLIO            varchar(40)  '@Folio'
 )
 
  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END
