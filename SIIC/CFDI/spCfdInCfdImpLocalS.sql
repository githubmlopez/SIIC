USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdImpLocalS')
BEGIN
  DROP  PROCEDURE spCfdInCfdImpLocalS
END
GO
--EXEC spCfdInCfdPago 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdImpLocalS
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
-- Carga de la infromación de Productos y Servicios                                                                --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'Im LocalS'
	
    INSERT INTO CFDI_IMP_LOCAL_S
   (
    CVE_EMPRESA,
    ANO_MES,
    CVE_TIPO,
    UUID,
    ID_NODO,
	ID_NODO_P,
    TOT_TRASLADOS,
    TOT_RETENCIONES,
	VERSION
   )
    SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
    ID_NODO,
	ID_NODO_P,
    ISNULL(TOT_TRASLADOS,0),        
    ISNULL(TOT_RETENCIONES,' '),
	ISNULL(VERSION,' ')
   FROM OPENXML(@pHDoc, 'cfdi:Comprobante/cfdi:Complemento/implocal:ImpuestosLocales',2)   WITH 
   (
    ID_NODO    int '@mp:id',
    ID_NODO_P  int '@mp:parentid',
    TOT_TRASLADOS numeric(18,2)  '@TotaldeTraslados',
    TOT_RETENCIONES numeric(18,2) '@TotaldeRetenciones',  
	VERSION varchar(10) '@version'      
   )
 
  END TRY

  BEGIN CATCH
	SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
 --   SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END
