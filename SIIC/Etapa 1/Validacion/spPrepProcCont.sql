USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spPrepProcCont')
BEGIN
  DROP  PROCEDURE spPrepProcCont
END
GO

--EXEC spPrepProcCont'CU','MARIO','201907',135,1,' ',' '
CREATE PROCEDURE [dbo].[spPrepProcCont]
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
  DECLARE @f_ini         date,
          @f_fin         date,
		  @ano_mes_ant   varchar(6)

  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_error       varchar(1) = 'E',
		  @k_f_ddmmyyyy  int         = 111,
		  @k_f_ini       varchar(10) = 'FINIMES',
		  @k_f_fin       varchar(10) = 'FFINMES'

  SET @f_ini   = CONVERT(DATE,SUBSTRING(dbo.fnObtParAlfa(@k_f_ini),1,10),@k_f_ddmmyyyy)
  SET @f_fin   = CONVERT(DATE,SUBSTRING(dbo.fnObtParAlfa(@k_f_fin),1,10),@k_f_ddmmyyyy)

  SET @ano_mes_ant = dbo.fnObtAnoMesAnt(@pAnoPeriodo)

  IF  MONTH(@f_ini) = CONVERT(INT,SUBSTRING(@pAnoPeriodo,5,2))                AND
      MONTH(@f_fin) = CONVERT(INT,SUBSTRING(@pAnoPeriodo,5,2))                AND
	  EXISTS (SELECT 1 FROM CI_CHEQUERA_PERIODO WHERE ANO_MES = @ano_mes_ant) AND
	  EXISTS (SELECT 1 FROM CI_PERIODO_ISR WHERE ANO_MES = @ano_mes_ant)      AND
	  NOT EXISTS (SELECT 1 FROM CI_MOVTO_BANCARIO WHERE ANO_MES = @pAnoPeriodo)
  BEGIN
 
    DELETE FROM CI_CHEQUERA_PERIODO WHERE ANO_MES = @pAnoPeriodo

    INSERT INTO CI_CHEQUERA_PERIODO
   (ANO_MES,
    CVE_CHEQUERA,
	F_INICIO,
	F_FIN,
	CVE_BANCO,
	SDO_INICIO_MES,
	SDO_FIN_MES,
	SDO_FIN_MES_CALC
   )
    SELECT @pAnoPeriodo, CVE_CHEQUERA, @f_ini, @f_fin, CVE_BANCO, SDO_FIN_MES, 0,0 FROM CI_CHEQUERA_PERIODO 
	WHERE ANO_MES = @ano_mes_ant

    DELETE FROM CI_PERIODO_ISR WHERE ANO_MES = @pAnoPeriodo

	INSERT INTO CI_PERIODO_ISR
   (CVE_EMPRESA,
	ANO_MES,
	IMP_INGRESOS,
	IMP_VTA_ACTIVOS,
	IMP_OTRO_GTOS_IVA,
	IMP_ING_GRABADOS,
	IMP_CANCELACIONES,
	IMP_INT_BANCARIO,
	IMP_OTR_PRODUC,
	IMP_EXENTOS,
	IMP_ING_NOMINALES,
	IMP_ING_MES_ANT,
	IMP_ING_TOTALES,
	COEF_UTLIDAD,
	IMP_UTIL_ESTIM,
	IMP_INVENT_ACUM,
	IMP_UTIL_ADICION,
	IMP_PER_FISC_PA,
	IMP_BASE_PAG_PROV,
	TASA_ISR,
	IMP_ISR_PERIODO,
	IMP_ISR_MES_ANT,
	IMP_ISR_BANCARIO,
	IMP_PAG_PROV_PER,
	IMP_ISR_COMPENSA,
	IMP_ISR,
	IMP_ISR_BANC_ACUM,
	IMP_CANC_UTILIDAD,
	IMP_EFECT_PAGADO) 
	SELECT CVE_EMPRESA,@pAnoPeriodo,0,0,0,0,0,0,0,0,0, IMP_ISR_PERIODO,0,COEF_UTLIDAD,0,0,0,0,0,TASA_ISR ,0,IMP_ISR_PERIODO,0,0,0,0,0,0,0
	FROM CI_PERIODO_ISR  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @ano_mes_ant
	
  END
  ELSE
  BEGIN
    SET  @pError    =  'Inconsistencia en periodo '  + @pAnoPeriodo  + ' ' + ISNULL(ERROR_PROCEDURE(), ' ')
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--          SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

