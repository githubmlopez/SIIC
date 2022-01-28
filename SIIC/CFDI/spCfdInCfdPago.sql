USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdPago')
BEGIN
  DROP  PROCEDURE spCfdInCfdPago
END
GO
--EXEC spCfdInCfdPago 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdPago
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

  SET @seccion  =  'Pago'
	
    INSERT INTO CFDI_PAGO
   (
    CVE_EMPRESA,
    ANO_MES,
    CVE_TIPO,
    UUID,
    ID_NODO,
	ID_NODO_P,
    IMP_PAGO,
    CVE_MONEDA,
	FORMA_PAGO,
	F_PAGO
   )
    SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
    ID_NODO,
	ID_NODO_P,
    ISNULL(IMP_PAGO,0),        
    ISNULL(CVE_MONEDA,' '),
	ISNULL(FORMA_PAGO,' '),
	F_PAGO 
    FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:Complemento/pago10:Pagos/pago10:Pago',2)
    WITH 
   (
    ID_NODO    int '@mp:id',
    ID_NODO_P  int '@mp:parentid',
    IMP_PAGO   numeric(18,2)  '@Monto',
    CVE_MONEDA varchar(3) '@MonedaP',  
	FORMA_PAGO varchar(2) '@FormaDePagoP',      
    F_PAGO     date '@FechaPago'
   )

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END
