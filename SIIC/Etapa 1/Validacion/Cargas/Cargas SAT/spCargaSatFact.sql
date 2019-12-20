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

--EXEC spCargaSatFact 'CU','MARIO','201906',140,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaSatFact]
(

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

  DECLARE @id_unico        varchar (36),
          @rfc_emisor      varchar (15),
          @nom_emisor      varchar (100),
          @rfc_receptor    varchar (15),
          @nom_receptor    varchar(100),
          @rfc_pac         varchar (15),
          @f_emision       date,
          @f_certificacion date,
          @imp_factura     numeric (16,2),
          @efecto_comprob  varchar (1),
          @f_cancelacion   date

  DECLARE @pIdCliente      int,
          @pTipoInfo       int,
          @pIdFormato      int,
          @pIdBloque       int

  DECLARE @RowCount     int = 0, 
		  @NumRegistros   int = 0,
		  @situacion       varchar(2),
		  @sit_fact_sat    bit

  DECLARE @k_verdadero     bit        = 1,
          @k_activa        varchar(2) = 'A',
		  @k_cancelada     varchar(2) = 'C',
		  @k_error         varchar(1) = 'E',
		  @k_factura       int        = 5,
		  @k_CXP           int        = 6,
		  @k_no_conc       varchar(2) = 'NC',
		  @k_cerrado       varchar(1) = 'C',
		  @k_f_ddmmyyyy  int         = 23

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

  IF  @pTipoInfo  =  @k_factura
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

  SELECT @NumRegistros = ISNULL(MAX(NUM_REGISTRO),0) FROM CARGADOR.dbo.FC_CARGA_COL_DATO WHERE
  ID_CLIENTE       = @pIdCliente  AND
  CVE_EMPRESA      = @pCveEmpresa AND
  TIPO_INFORMACION = @pTipoInfo   AND
  ID_FORMATO       = @pIdFormato  AND
  ID_BLOQUE        = @pIdBloque   AND
  PERIODO          = @pAnoPeriodo

  SET  @RowCount = 1

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SET  @id_unico  =
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 1, 1, 36)

	SET @rfc_emisor =  
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 2, 1, 15)

	SET @nom_emisor =   
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 3, 1, 100)

	SET @rfc_receptor  =  
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 4, 1, 15)

    SET  @nom_receptor =
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 5, 1, 15)

	SET  @rfc_pac  =  
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 6, 1, 15)

	SET  @f_emision =   
    dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 7, 1, 15, @k_f_ddmmyyyy) 

	SET  @f_certificacion =  
    dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 8, 1, 15, @k_f_ddmmyyyy) 

	SET @imp_factura  =  
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 9, 1, 18)

	SET  @efecto_comprob =  
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 10, 1, 1) 

	SET @sit_fact_sat  =
    dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 11, 1, 1) 

    IF  @sit_fact_sat = @k_verdadero
	BEGIN
      SET @situacion = @k_activa
    END
	ELSE
	BEGIN
      SET @situacion = @k_cancelada
    END

    SET @f_cancelacion =
    dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 12, 1, 15, @k_f_ddmmyyyy) 

    IF  @pTipoInfo  =  @k_factura
    BEGIN
--      DELETE FROM CI_SAT_FACTURA WHERE ID_UNICO = @id_unico
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
     )  VALUES
     (@id_unico,
      @rfc_emisor,
      @nom_emisor,
      @rfc_receptor,
      @nom_receptor,
      @rfc_pac,
      @f_emision,
      @f_certificacion,
      @imp_factura,
      @efecto_comprob,
      @situacion,
      @f_cancelacion,
	  @pAnoPeriodo,
	  @k_no_conc,
	  @k_verdadero,
	  NULL
     )
    END
    ELSE
    BEGIN
--      DELETE FROM CI_SAT_CXP WHERE ID_UNICO = @id_unico
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
     )  VALUES
     (@id_unico,
      @rfc_emisor,
      @nom_emisor,
      @rfc_receptor,
      @nom_receptor,
      @rfc_pac,
      @f_emision,
      @f_certificacion,
      @imp_factura,
      @efecto_comprob,
      @situacion,
      @f_cancelacion,
      NULL,
	  NULL,
	  @k_no_conc,
	  @pAnoPeriodo,
	  @k_verdadero,
	  NULL
     )
    END

    SET  @RowCount = @RowCount + 1

  END

  END TRY

  BEGIN CATCH
    IF  @pTipoInfo  =  @k_factura
    BEGIN
      SET  @pError    =  'Error Carga de Facturas SAT' + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
	END
	ELSE
	BEGIN
      SET  @pError    =  'Error Carga de CXP SAT' + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
	END

    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' ')) 
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @RowCount

  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado ' + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' ')) 
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

