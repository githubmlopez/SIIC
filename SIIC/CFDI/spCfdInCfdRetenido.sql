USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdRetenido')
BEGIN
  DROP  PROCEDURE spCfdInCfdRetenido
END
GO
--EXEC spCfdInRetenido 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdRetenido
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

  SET @seccion  =  'Retencion'
	
  INSERT INTO CFDI_RETENCION
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  ID_NODO,
  ID_NODO_P,
  CVE_IMPUESTO,
  BASE,
  TIPO_FACTOR,
  TASA_CUOTA,
  IMP_IMPUESTO
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid, 
  ID_NODO,
  ID_NODO_P,
  ISNULL(CVE_IMPUESTO, ' '),
  ISNULL(BASE, 0),
  ISNULL(TIPO_FACTOR, ' '),
  ISNULL(TASA_CUOTA, 0),
  ISNULL(IMP_IMPUESTO, 0)
  FROM OPENXML(@pHDoc, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',2)
  WITH 
 (
  ID_NODO      int '@mp:id',
  ID_NODO_P    int '@mp:parentid',
  CVE_IMPUESTO varchar(3) '@Impuesto',
  BASE         numeric(18,6) '@Base',
  TIPO_FACTOR  varchar(10) '@TipoFactor',
  TASA_CUOTA   numeric(8,6) '@TasaOCuota',
  IMP_IMPUESTO numeric(18,6) '@Importe'
 )
 
  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END
