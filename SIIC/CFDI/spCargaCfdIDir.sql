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

--exec spCargaCfdiDir 1,'CU','MARIO','SIIC','202002',220,1,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCargaCfdiDir]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pBError        bit OUT,
@pError         varchar(80) OUT, 
@pMsgError      varchar(400) OUT
)
AS
BEGIN

  DECLARE @pTipoInfo     int,
          @pIdFormato    int,
          @pIdBloque     int

  DECLARE @cve_tipo      varchar(4),
          @cont_regist   int

  DECLARE @k_verdadero   bit        = 1,
          @k_activa      varchar(2) = 'A',
		  @k_error       varchar(1) = 'E',
		  @k_cve_factura varchar(4) = 'FACT',
		  @k_cve_cxp     varchar(4) = 'CXP',
		  @k_cve_pag     varchar(4) = 'PAG',
		  @k_fmt_factura int        = 10,
		  @k_fmt_cxp     int        = 20,
		  @k_fmt_pag     int        = 30,
		  @k_cerrado     varchar(1) = 'C'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado

  BEGIN

  SELECT
  @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
  FROM  FC_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  IF  @pIdFormato  =  @k_fmt_factura
  BEGIN
    DELETE  FROM  CFDI_XML_CTE_PERIODO  WHERE CVE_TIPO  =  @k_cve_factura  AND  ANO_MES  =  @pAnoPeriodo 
  END
  ELSE
  IF  @pIdFormato  =  @k_fmt_cxp
  BEGIN
    DELETE  FROM  CFDI_XML_CTE_PERIODO  WHERE CVE_TIPO  =  @k_cve_cxp  AND  ANO_MES  =  @pAnoPeriodo 
  END

  SELECT @cont_regist =  @@ROWCOUNT

  BEGIN TRY

 IF  @pIdFormato  =  @k_fmt_factura
 BEGIN
  SET  @cve_tipo  =  @k_cve_factura
 END
 ELSE
 BEGIN
   IF  @pIdFormato  =  @k_fmt_cxp
   BEGIN
     SET  @cve_tipo  =  @k_cve_cxp
   END
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
  FROM FC_CARGA_COL_DATO c WHERE
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
    SET  @pError    =  '(E) Carga de CFDI ' + @cve_tipo
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero
  END CATCH

--  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @cont_regist

  END
  ELSE
  BEGIN
    SET  @pError    =  '(E) El Periodo esta cerrado '
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero
  END

END

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       