USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaSatFact')
BEGIN
  DROP  PROCEDURE spCargaSatFact
END
GO
--EXEC spCargaSatFact 'CU','MARIO','201901',94,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaSatFact]
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

  DECLARE @pIdCliente    int,
          @pIdFormato    int,
          @pIdBloque     int

  DECLARE @f_dummy       date = '2050-01-01',
          @f_cancelacion date,
          @cont_regist   int = 0, 
		  @tot_registros int = 0,
		  @situacion     varchar(2)

  DECLARE @k_verdadero   bit        = 1,
          @k_activa      varchar(2) = 'A',
		  @k_cancelada   varchar(2) = 'C',
		  @k_error       varchar(1) = 'E',
		  @k_factura     int        = 30,
		  @k_CXP         int        = 20,
		  @k_no_conc     varchar(2) = 'NC'

  DECLARE @TvpSatFact TABLE
 (
  NUM_REGISTRO    int  PRIMARY KEY,
  ID_UNICO        varchar (36)   NOT NULL,
  RFC_EMISOR      varchar (15)   NOT NULL,
  NOM_EMISOR      varchar (100)  NOT NULL,
  RFC_RECEPTOR    varchar (15)   NOT NULL,
  NOM_RECEPTOR    varchar(100)   NOT NULL,
  RFC_PAC         varchar (15)   NOT NULL,
  F_EMISION       date           NOT NULL,
  F_CERTIFICACION date           NOT NULL,
  IMP_FACTURA     numeric (16,2) NOT NULL,
  EFECTO_COMPROB  varchar (1)    NOT NULL,
  ESTATUS         varchar (1)    NULL,
  F_CANCELACION   date           NULL
  )


  SELECT
  @pIdCliente = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
  FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  IF  @pIdFormato  =  @k_factura
  BEGIN
    DELETE FROM CI_SAT_FACTURA WHERE
    ANO_MES_PROC = @pAnoPeriodo 
  END
  ELSE
  BEGIN
	DELETE FROM CI_SAT_CXP WHERE
    ANO_MES_PROC = @pAnoPeriodo 
  END

  --SELECT CONVERT(varchar(10),@pIdCliente)
  --SELECT CONVERT(varchar(10),@pIdFormato)
  --SELECT CONVERT(varchar(10),@pIdBloque)

  BEGIN TRY

  INSERT INTO @TvpSatFact 
 (
  NUM_REGISTRO,
  ID_UNICO,
  RFC_EMISOR,
  NOM_EMISOR,
  RFC_RECEPTOR,
  NOM_RECEPTOR,
  RFC_PAC,
  F_EMISION,
  F_CERTIFICACION,
  IMP_FACTURA,
  EFECTO_COMPROB,
  ESTATUS,
  F_CANCELACION
  )
  SELECT
  NUM_REGISTRO,
  SUBSTRING(LTRIM(c.VAL_DATO),1,36),
  ' ',
  ' ',
  ' ',
  ' ',
  ' ',
  @f_dummy,
  @f_dummy,
  0,
  ' ',
  NULL,
  NULL
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
    UPDATE @TvpSatFact 
	SET RFC_EMISOR =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,15) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 2),  
	NOM_EMISOR =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,100) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 3),  
	RFC_RECEPTOR =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,15) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 4),  
    NOM_RECEPTOR =
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,100) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 5),
	RFC_PAC =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,15) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 6),  
	F_EMISION =  
   (SELECT CONVERT(DATE, LTRIM(VAL_DATO), 126) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 7),  
	F_CERTIFICACION =  
   (SELECT CONVERT(DATE, LTRIM(VAL_DATO), 126) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 8),  
	IMP_FACTURA =  
   (SELECT CONVERT(numeric(16,2), LTRIM(VAL_DATO)) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 9),  
	EFECTO_COMPROB =  
   (SELECT SUBSTRING(LTRIM(VAL_DATO),1,1) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 10) WHERE NUM_REGISTRO = @cont_regist

    IF  (SELECT LTRIM(VAL_DATO) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 11) = @k_verdadero
	BEGIN
      SET @situacion = @k_activa
    END
	ELSE
	BEGIN
      SET @situacion = @k_cancelada
    END

    UPDATE @TvpSatFact SET ESTATUS = @situacion WHERE NUM_REGISTRO = @cont_regist   

    IF  (SELECT LTRIM(VAL_DATO) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
    ID_CLIENTE   = @pIdCliente  AND
    CVE_EMPRESA  = @pCveEmpresa AND
    ID_FORMATO   = @pIdFormato  AND
    ID_BLOQUE    = @pIdBloque   AND
    PERIODO      = @pAnoPeriodo AND
	NUM_REGISTRO = @cont_regist AND
    NUM_COLUMNA  = 12) = ' '
	BEGIN
      SET @f_cancelacion = NULL
    END
	ELSE
	BEGIN
      SET  @f_cancelacion =
     (SELECT CONVERT(DATE, LTRIM(VAL_DATO), 126) FROM CARGADOR.dbo.FC_CARGA_COL_DATO c WHERE
      ID_CLIENTE   = @pIdCliente  AND
      CVE_EMPRESA  = @pCveEmpresa AND
      ID_FORMATO   = @pIdFormato  AND
      ID_BLOQUE    = @pIdBloque   AND
      PERIODO      = @pAnoPeriodo AND
	  NUM_REGISTRO = @cont_regist AND
      NUM_COLUMNA  = 12)
    END

    UPDATE @TvpSatFact SET F_CANCELACION = @f_cancelacion WHERE NUM_REGISTRO = @cont_regist   

    SET  @cont_regist = @cont_regist + 1

  END
--  SELECT * FROM @TvpSatFact

  DELETE FROM CI_SAT_FACTURA WHERE ID_UNICO IN
 (SELECT ID_UNICO FROM @TvpSatFact)

  IF  @pIdFormato  =  @k_factura
  BEGIN
    INSERT CI_SAT_FACTURA 
   (
    ID_UNICO,
    RFC_EMISOR,
    NOM_EMISOR,
    RFC_RECEPTOR,
    NOM_RECEPTOR,
    RFC_PAC,
    F_EMISION,
    F_CERTIFICACION,
    IMP_FACTURA,
    EFECTO_COMPROB,
    ESTATUS,
    F_CANCELACION,
	ANO_MES_PROC,
	SIT_CONCILIA,
	B_AUTOMATICO, 
	CVE_CONC_MAN
    )
    SELECT 
    ID_UNICO,
    RFC_EMISOR,
    NOM_EMISOR,
    RFC_RECEPTOR,
    NOM_RECEPTOR,
    RFC_PAC,
    F_EMISION,
    F_CERTIFICACION,
    IMP_FACTURA,
    EFECTO_COMPROB,
    ESTATUS,
    F_CANCELACION,
	@pAnoPeriodo,
	@k_no_conc,
	@k_verdadero,
	NULL
    FROM  @TvpSatFact
  END
  ELSE
  BEGIN
    INSERT CI_SAT_CXP 
   (
    ID_UNICO,
    RFC_EMISOR,
    NOM_EMISOR,
    RFC_RECEPTOR,
    NOM_RECEPTOR,
    RFC_PAC,
    F_EMISION,
    F_CERTIFICACION,
    IMP_FACTURA,
    EFECTO_COMPROB,
    ESTATUS,
    F_CANCELACION,
	ID_CXP,
	ID_CXP_DET,
	SIT_CONCILIA,
	ANO_MES_PROC,
	B_AUTOMATICO,
	CVE_CONC_MAN
    )
    SELECT 
    ID_UNICO,
    RFC_EMISOR,
    NOM_EMISOR,
    RFC_RECEPTOR,
    NOM_RECEPTOR,
    RFC_PAC,
    F_EMISION,
    F_CERTIFICACION,
    IMP_FACTURA,
    EFECTO_COMPROB,
    ESTATUS,
    F_CANCELACION,
	NULL,
	NULL,
	@k_no_conc,
	@pAnoPeriodo,
	@k_verdadero,
	NULL
    FROM  @TvpSatFact

  END
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Carga de Facturas SAT'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @cont_regist
END

