USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdRelacionadoS')
BEGIN
  DROP  PROCEDURE spCfdInCfdRelacionadoS
END
GO
--EXEC spCfdiBaseDatos 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE spCfdInCfdRelacionadoS
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
-- Carga de la infromación de PagoS                                                                --
----------------------------------------------------------------------------------------------------------------------

  SET @seccion  =  'RelacionadoS'

  INSERT INTO CFDI_RELACIONADO_S
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  ID_NODO,
  TIPO_RELACION
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  ID_NODO,
  TIPO_RELACION
  FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:CfdiRelacionados',2)
  WITH 
(
  ID_NODO       int '@mp:id',
  TIPO_RELACION int '@TipoRelacion'
 )

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

END