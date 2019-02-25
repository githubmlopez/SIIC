USE [ADMON01]
GO
/****** Carga y conciliación de documentación ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaDocum')
BEGIN
  DROP  PROCEDURE spCargaDocum
END
GO
--EXEC spCargaDocum 'CU','MARIO','201902',82,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaDocum]
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

  DECLARE @pIdCliente     int,
          @pIdFormato     int,
          @pIdBloque      int

  DECLARE @cont_regist    int = 0, 
		  @tot_registros  int = 0,
		  @situacion      varchar(2)

  DECLARE @k_verdadero    bit        = 1,
		  @k_error        varchar(1) = 'E',
		  @k_docto_fact   int        = 100,
		  @k_no_conc      varchar(2) = 'NC',
		  @k_conciliada   varchar(2) = 'CO'

  DECLARE @cve_empresa    varchar(4),
		  @serie          varchar(6),
		  @id_factura     int,
		  @id_item        int,
		  @cve_tipo_docum varchar(4)

  DECLARE @TvpDoctoFact TABLE
 (
  NUM_REGISTRO    int  PRIMARY KEY,
  CVE_EMPRESA     varchar (4 )   NOT NULL,
  SERIE           varchar (6)    NOT NULL,
  ID_FACTURA      int            NOT NULL,
  ID_ITEM         int            NOT NULL,
  CVE_TIPO_DOCUM  varchar(4)     NOT NULL
  )


  SELECT
  @pIdCliente = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
  FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  BEGIN TRY

  INSERT INTO @TvpDoctoFact 
 (
  NUM_REGISTRO,
  CVE_EMPRESA,
  SERIE,
  ID_FACTURA,
  ID_ITEM,
  CVE_TIPO_DOCUM
  )
  SELECT
  NUM_REGISTRO,
  SUBSTRING(LTRIM(c.VAL_DATO),1,4),
  ' ',
  0,
  0,
  ' '
  FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
  ID_CLIENTE  = @pIdCliente  AND
  CVE_EMPRESA = @pCveEmpresa AND
  ID_FORMATO  = @pIdFormato  AND
  ID_BLOQUE   = @pIdBloque   AND
  PERIODO     = @pAnoPeriodo AND
  NUM_COLUMNA = 1

  SELECT @tot_registros= MAX(NUM_REGISTRO) FROM CARGADOR.dbo.FC_CARGA_COL_DATO WHERE
  ID_CLIENTE  = @pIdCliente  AND
  CVE_EMPRESA = @pCveEmpresa AND
  ID_FORMATO  = @pIdFormato  AND
  ID_BLOQUE   = @pIdBloque   AND
  PERIODO     = @pAnoPeriodo

  SET  @cont_regist = 1

  WHILE @cont_regist <= @tot_registros
  BEGIN
    UPDATE @TvpDoctoFact 
	SET SERIE    =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,6) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 2),  
    ID_FACTURA   =  
   (SELECT CONVERT(int,SUBSTRING(LTRIM(VAL_DATO),1,10))
    FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 3),  
	ID_ITEM =  
   (SELECT CONVERT(int,SUBSTRING(LTRIM(VAL_DATO),1,10))
    FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 4),  
    CVE_TIPO_DOCUM =
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,2) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 5)
	WHERE NUM_REGISTRO = @cont_regist

    SET  @cont_regist = @cont_regist + 1

  END
  SELECT * FROM @TvpDoctoFact 

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Concilia Documentacion '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  SELECT @tot_registros = COUNT(*) FROM @TvpDoctoFact

  SET  @cont_regist = 1

  WHILE @cont_regist <= @tot_registros
  BEGIN
    SELECT @cve_empresa = CVE_EMPRESA, @id_factura = ID_FACTURA, @serie = SERIE,
	       @id_item = ID_ITEM, @cve_tipo_docum = CVE_TIPO_DOCUM
	FROM   @TvpDoctoFact WHERE NUM_REGISTRO = @cont_regist

	IF  EXISTS(SELECT 1 FROM CI_DOCUM_ITEM WHERE 
	           CVE_EMPRESA    =  @cve_empresa  AND
			   SERIE          =  @serie        AND
			   ID_CXC         =  @id_factura   AND
			   ID_ITEM        =  @id_item      AND
			   CVE_TIPO_DOCUM =  @cve_tipo_docum)
    BEGIN
      UPDATE CI_DOCUM_ITEM 
	  SET SITUACION  = @k_conciliada 
	  WHERE 
	  CVE_EMPRESA    =  @cve_empresa  AND
	  SERIE          =  @serie        AND
	  ID_CXC         =  @id_factura   AND
	  ID_ITEM        =  @id_item      AND
	  CVE_TIPO_DOCUM =  @cve_tipo_docum
	END
	ELSE
	BEGIN
      SET  @pError    =  'PDF NO REQUERIDO ' + @cve_empresa + @serie + 
	  CONVERT(varchar(6),@id_factura) + CONVERT(varchar(6),@id_item) + @cve_tipo_docum
	  SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

	SET  @cont_regist = @cont_regist + 1
  END


  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @cont_regist
END

