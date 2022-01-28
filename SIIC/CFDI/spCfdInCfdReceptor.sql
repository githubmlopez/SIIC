USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdInCfdReceptor')
BEGIN
  DROP  PROCEDURE spCfdInCfdReceptor
END
GO
--EXEC spCfdInCfdReceptor 1,'CU','MARIO','SIIC','202008',202,1,1,'P',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdInCfdReceptor
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@phdoc            int,
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

  SET @seccion  =  'Receptor'

  INSERT intO CFDI_RECEPTOR
 (CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  UUID,
  RFC_REC,
  NOMBRE_REC,
  USO_CFDI_REC
 )
  SELECT @pCveEmpresa, @pAnoPeriodo, @pCveTipo, @pUuid,
  ISNULL(RFC_RC,' '),
  ISNULL(NOMBRE_RC,' '),
  ISNULL(USO_CFDI_REC, ' ')
  FROM OPENXML(@pHdoc, 'cfdi:Comprobante/cfdi:Receptor',2)
  WITH 
 (
  RFC_RC       varchar(20) '@Rfc',
  NOMBRE_RC    varchar(100) '@Nombre',
  USO_CFDI_REC varchar(100) '@UsoCFDI'
 )

  END TRY

  BEGIN CATCH
    IF  @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRAN 
    END    SET  @pError    =  '(E) CFDI ' + isnull(@seccion, 'nulo') + ' ' + @pUuid 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH


END