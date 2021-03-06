USE  ADMON01 
GO
/******  Obtiene folio de instancia de ejecucion de proceso ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'P') AND Name =  'spInicioPeriodo')
BEGIN
  DROP  PROCEDURE spInicioPeriodo
END
GO

--EXEC spInicioPeriodo 1,'CU','MARIO', 'SIIC', '202003', 303, 1,0, ' ',' ',' '
CREATE PROCEDURE  dbo.spInicioPeriodo  
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

  DECLARE  @k_abierto    varchar(1)  =  'A',
           @k_prim_dia   varchar(2)  =  '01',
		   @k_verdadero  varchar(1)  =  '1',
		   @k_falso      varchar(1)  =  '0',
		   @k_error      varchar(1)  =  'E'

  DECLARE  @f_inicial   date,
           @f_final     date,
		   @ano_mes_ant varchar(6)

-- Verifica registros existentes del periodo

  SET  @ano_mes_ant = dbo.fnObtAnoMesAnt(@pAnoPeriodo)

  IF  EXISTS(SELECT 1 FROM CI_PERIODO_CONTA  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES = @pAnoPeriodo)
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Periodo ya existe ' + ISNULL(@pAnoPeriodo,'NULO')  
    SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

  IF  EXISTS(SELECT 1 FROM CI_PERIODO_ISR WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES = @pAnoPeriodo)
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Periodo de ISR ya existe ' + ISNULL(@pAnoPeriodo,'NULO')  
    SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

  IF  (SELECT COUNT(*)  FROM  CI_CHEQUERA_PERIODO  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo) > 1  
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Existen chequeras del periodo ' + ISNULL(@pAnoPeriodo,'NULO')  
    SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

  IF  (SELECT COUNT(*)  FROM  CI_CHEQUERA_PERIODO  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @ano_mes_ant) < 1  
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) No existen cheq. periodo anterior ' + ISNULL(@ano_mes_ant,'NULO')  
    SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END


  IF  @pBError    =  @k_falso
  BEGIN
  
  BEGIN TRAN

  BEGIN TRY

  INSERT  CI_PERIODO_CONTA (
  CVE_EMPRESA,
  ANO_MES,
  F_INICIAL,
  F_FINAL,
  TIPO_CAM_F_MES,
  SIT_PERIODO,
  IMP_RENOVACION,
  IMP_RENOV_BCO,
  IMP_RENOV_ANT,
  TIPO_CAMB_PROM,
  CVE_TIPO_VAL
  ) VALUES
  (
  @pCveEmpresa,
  @pAnoPeriodo,
  @f_inicial,
  EOMONTH(@f_inicial),
  0,
  @k_abierto,
  0,
  0,
  0,
  0,
  (SELECT CVE_TIPO_VAL  FROM CI_EMPRESA  WHERE CVE_EMPRESA = @pCveEmpresa)
  )

  INSERT INTO CI_CHEQUERA_PERIODO (
  CVE_EMPRESA,
  ANO_MES,
  CVE_CHEQUERA,
  SDO_INICIO_MES,
  SDO_FIN_MES,
  SDO_FIN_MES_CALC)
  SELECT    
  CVE_EMPRESA,
  @pAnoPeriodo,
  CVE_CHEQUERA,
  ISNULL((SELECT SDO_FIN_MES FROM CI_CHEQUERA_PERIODO  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @ano_mes_ant AND
  CVE_CHEQUERA = ch.CVE_CHEQUERA),0),
  ISNULL((SELECT SDO_FIN_MES FROM CI_CHEQUERA_PERIODO  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @ano_mes_ant AND
  CVE_CHEQUERA = ch.CVE_CHEQUERA),0),
  ISNULL((SELECT SDO_FIN_MES FROM CI_CHEQUERA_PERIODO  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @ano_mes_ant AND
  CVE_CHEQUERA = ch.CVE_CHEQUERA),0)
  FROM  CI_CHEQUERA  ch WHERE
  CVE_EMPRESA = @pCveEmpresa   

  INSERT INTO CI_PERIODO_ISR
 (
  CVE_EMPRESA,
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
  IMP_EFECT_PAGADO
 )
  VALUES
 (  
  @pCveEmpresa,
  @pAnoPeriodo,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
 )
  END TRY

  BEGIN CATCH

  IF  @@TRANCOUNT > 0
  BEGIN
    ROLLBACK TRAN
  END

  SET  @pBError    =  @k_verdadero
  SET  @pError    =  '(E) Error al insertar registros ' + ISNULL(@ano_mes_ant,'NULO')  
  SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
  EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError

  END CATCH

  IF  @@TRANCOUNT > 0
  BEGIN
    IF  @pBError  =  1
    BEGIN
	  ROLLBACK TRAN
	END
	ELSE
	BEGIN
      COMMIT TRAN
    END
  END

  END

END
