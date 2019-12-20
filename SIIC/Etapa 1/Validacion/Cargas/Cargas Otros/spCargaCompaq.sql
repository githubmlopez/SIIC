USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaCompaq')
BEGIN
  DROP  PROCEDURE spCargaCompaq
END
GO

--EXEC spCargaCompaq 'CU','MARIO','201906',141,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaCompaq]
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
  DECLARE @f_operacion     date,
          @serie           varchar(6),
          @id_cxc          int,
          @id_cliente      numeric(10),
          @razon_social    varchar(100),
          @rfc             varchar(20),
          @concepto        varchar(50),
          @aprobacion      varchar(1),
          @estado          varchar(20),
          @f_expedicion    date,
          @imp_bruto       numeric(16,2),
          @imp_descuento   numeric(16,2),
          @imp_impuesto    numeric(16,2),
          @imp_neto        numeric(16,2)

  DECLARE @pIdCliente    int,
          @pIdFormato    int,
		  @pTipoInfo     int,
          @pIdBloque     int,
		  @pNomArchivo   varchar(20)

  DECLARE @RowCount      int = 0, 
		  @NumRegistros  int = 0,
          @val_dato_c    varchar(250),
		  @val_dato_n    numeric(16,2)

  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_error       varchar(1) = 'E',
		  @k_cerrado     varchar(1) = 'C',
		  @k_activa      varchar(1) = 'A',
		  @k_cancelada   varchar(1) = 'C',
		  @k_inicio      varchar(1) = 'I',
 		  @k_fin         varchar(1) = 'F',
		  @K_f_ddmmyyyy  int        = 103,
		  @k_vigente     varchar(7) = 'Vigente'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado
  BEGIN

  SELECT
  @pIdCliente = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdBloque = CONVERT(INT,SUBSTRING(PARAMETRO,13,6)),
  @pIdFormato  = CONVERT(INT,SUBSTRING(PARAMETRO,19,6))
  FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  DELETE  FROM  CI_COM_FISC_CONTPAQ  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES  =  @pAnoPeriodo  

  BEGIN TRY

  SELECT @NumRegistros= MAX(NUM_REGISTRO) FROM CARGADOR.dbo.FC_CARGA_COL_DATO WHERE
  ID_CLIENTE       = @pIdCliente  AND
  CVE_EMPRESA      = @pCveEmpresa AND
  TIPO_INFORMACION = @pTipoInfo   AND
  ID_BLOQUE        = @pIdBloque   AND
  ID_FORMATO       = @pIdFormato  AND
  PERIODO          = @pAnoPeriodo

  SET  @RowCount = 1
 
  WHILE @RowCount <= @NumRegistros
  BEGIN

 	SET  @f_operacion  =
    dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 1, 1, 20, @K_f_ddmmyyyy) 

	SET  @serie  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 2, 1, 6)

	SET  @id_cxc  =
	dbo.fnobtObtValNum  (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 3, 1, 20)

	SET  @id_cliente  =
	dbo.fnobtObtValNum  (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 4, 1, 20)

	SET  @razon_social  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 5, 1, 100)

	SET  @rfc  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 6, 1, 20)

	SET  @concepto  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 7, 1, 50)

	SET  @aprobacion  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 8, 1, 1)

	IF LTRIM(dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 9, 1, 10)) = @k_vigente
    BEGIN
	  SET  @estado  = @k_activa
    END
	ELSE
	BEGIN
	  SET  @estado  = @k_cancelada
	END
 
 	SET  @f_expedicion  =
    dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 10, 1, 20, @K_f_ddmmyyyy) 

	SET  @imp_bruto  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 11, 1, 20)

	SET  @imp_descuento  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 12, 1, 20)

	SET  @imp_impuesto  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 13, 1, 20)

	SET  @IMP_NETO  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 14, 1, 20)

    INSERT INTO CI_COM_FISC_CONTPAQ  
   (
    CVE_EMPRESA,
    ANO_MES,
    F_OPERACION,
    SERIE,
    ID_CXC,
    ID_CLIENTE,
    RAZON_SOCIAL,
    RFC,
    CONCEPTO,
    APROBACION,
    ESTADO,
    F_EXPEDICION,
    IMP_BRUTO,
    IMP_DESCUENTO,
    IMP_IMPUESTO,
    IMP_NETO,
    IMP_BRUTO_C,
    IMP_IMPUESTO_C,
    IMP_NETO_C,
    B_CONTPAQ,
    TIPO_CAMBIO
   )  VALUES
   (
    @pCveEmpresa,
    @pAnoPeriodo,
    @f_operacion,
    @serie,
    @id_cxc,
    @id_cliente,
    @razon_social,
    @rfc,
    @concepto,
    @aprobacion,
    @estado,
    @f_expedicion,
    @imp_bruto,
    @imp_descuento,
    @imp_impuesto,
    @imp_neto,
    0,
    0,
    0,
    1,
    0
   )
    SET  @RowCount = @RowCount + 1

  END

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Carga de Sat CONTPAQ' + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
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

