USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaBalanza')
BEGIN
  DROP  PROCEDURE spCargaBalanza
END
GO

--EXEC spCargaBalanza 'CU','MARIO','201906',142,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaBalanza]
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

  DECLARE @ano_mes      varchar(6),
          @cve_empresa  varchar(4),
          @cta_contable varchar(30),
          @sdo_inicial  numeric(16,2),
          @imp_cargo    numeric(16,2),
          @imp_abono    numeric(16,2),
          @sdo_final    numeric(16,2)

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
		  @K_f_ddmmyyyy  int        = 103

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

  DELETE  FROM  CI_BALANZA_OPERATIVA  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES  =  @pAnoPeriodo  

  --SELECT CONVERT(varchar(10),@pIdCliente)
  --SELECT CONVERT(varchar(10),@pTipoInfo)
  --SELECT CONVERT(varchar(10),@pIdBloque)
  --SELECT CONVERT(varchar(10),@pIdFormato)

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

 	SET  @cta_contable  =
	dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 1, 1, 30)

	SET  @sdo_inicial  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 3, 1, 20)
 
	SET  @imp_cargo  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 4, 1, 20)
 
	SET  @imp_abono  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 5, 1, 20)

	SET  @sdo_final  =
	dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount, 6, 1, 20)

    INSERT INTO CI_BALANZA_OPERATIVA 
   (
    ANO_MES,
    CVE_EMPRESA,
    CTA_CONTABLE,
    SDO_INICIAL,
    IMP_CARGO,
    IMP_ABONO,
    SDO_FINAL,
    SDO_INICIAL_C,
    IMP_CARGO_C,
    IMP_ABONO_C,
    SDO_FINAL_C,
	B_BALANZA
   )  VALUES
   (  
    @pAnoPeriodo,
    @pCveEmpresa,
    @cta_contable,
    @sdo_inicial,
    @imp_cargo,
    @imp_abono,
    @sdo_final,
    0,
    0,
    0,
    0,
	@k_verdadero
   )

    SET  @RowCount = @RowCount + 1
  END

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Carga de Balanza'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @RowCount

  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

