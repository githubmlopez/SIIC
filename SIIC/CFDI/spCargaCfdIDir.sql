USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaCfdiDir')
BEGIN
  DROP  PROCEDURE spCargaCfdiDir
END
GO

--EXEC spCargaCfdiDir'CU','MARIO','201906',143,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaCfdiDir]
(
--@pIdProceso       numeric(9),
--@pIdTarea         numeric(9),
--@pCodigoUsuario   varchar(20),
--@pIdCliente       int,
--@pCveEmpresa      varchar(4),
--@pCveAplicacion   varchar(10),
--@pIdFormato       int,
--@pIdBloque        int,
--@pAnoPeriodo      varchar(6),
--@pError           varchar(80) OUT,
--@pMsgError        varchar(400) OUT
--)
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @pTipoInfo     int,
          @pIdCliente    int,
          @pIdFormato    int,
          @pIdBloque     int

  DECLARE @cve_tipo      varchar(4),
          @cont_regist   int

  DECLARE @k_verdadero   bit        = 1,
          @k_activa      varchar(2) = 'A',
		  @k_error       varchar(1) = 'E',
		  @k_cve_factura varchar(4) = 'FACT',
		  @k_cve_CXP     varchar(4) = 'CXP',
		  @k_fmt_factura int        = 10,
		  @k_fmt_CXP     int        = 20,
		  @k_cerrado     varchar(1) = 'C'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado

  BEGIN

  SELECT
  @pIdCliente = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,13,6)),
  @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,19,6))
  FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  SELECT @cont_regist =  @@ROWCOUNT

  BEGIN TRY

  IF  @pIdFormato  =  @k_fmt_factura
  BEGIN
    SET  @cve_tipo  =  	@k_cve_factura
  END
  ELSE
  BEGIN
    SET  @cve_tipo  =  	@k_cve_CXP
  END 

  DELETE CFDI_XML_CTE_PERIODO WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND CVE_TIPO = @cve_tipo

  INSERT INTO CFDI_XML_CTE_PERIODO
 (
  CVE_EMPRESA,
  ANO_MES,
  CVE_TIPO,
  NOM_ARCHIVO,
  CVE_TIPO_COMP
  )
  SELECT
  @pCveEmpresa, @pAnoPeriodo, @cve_tipo, c.VAL_DATO, ' '
  FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
  ID_CLIENTE       = @pIdCliente  AND
  CVE_EMPRESA      = @pCveEmpresa AND
  TIPO_INFORMACION = @pTipoInfo   AND
  ID_BLOQUE        = @pIdBloque   AND
  ID_FORMATO       = @pIdFormato  AND
  PERIODO          = @pAnoPeriodo AND
  NUM_COLUMNA      = 1            AND
  NOT EXISTS (SELECT 1 FROM CFDI_XML_CTE_PERIODO WHERE
    CVE_EMPRESA      = @pCveEmpresa AND
	ANO_MES          = @pAnoPeriodo AND
	CVE_TIPO         = @cve_tipo    AND
	NOM_ARCHIVO      = c.VAL_DATO)


  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Carga de CFDI ' + @cve_tipo
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @cont_regist

  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

