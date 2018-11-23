USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spObtValorCpto  @pIdProceso numeric(9), 
                                @pIdTarea numeric(9),
								@pCveEmpresa varchar(4),
                                @pAnoMes varchar(6),
                                @pIdTransaccion numeric(9),
								@pCveOperCont varchar(6),
								@pCveConcTrans varchar(4),
								@pImporte  numeric(14,4) OUT,
								@pValor    varchar(400) OUT,
								@pEstatus varchar(1) OUT,
								@pError varchar(80) OUT,
								@pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @k_verdadero  bit,
           @k_warning    varchar(1)  = 'W'

  SET  @k_verdadero  =  1
--   SELECT 'DATO ' + @pCveEmpresa + @pAnoMes  + CONVERT(VARCHAR(20),@pIdTransaccion) +  @pCveOperCont + @pCveConcTrans

  IF 
  (SELECT  1
  FROM CI_CONCEP_TRANSAC
  WHERE CVE_EMPRESA     =  @pCveEmpresa     AND
        ANO_MES         =  @pAnoMes         AND
        ID_TRANSACCION  =  @pIdTransaccion  AND
        CVE_OPER_CONT   =  @pCveOperCont    AND
	    CVE_CONC_TRANS  =  @pCveConcTrans) =  @k_verdadero
  BEGIN
    SELECT  @pValor =  VALOR_CONCEPTO, @pImporte  =  IMP_CONCEPTO
    FROM CI_CONCEP_TRANSAC
    WHERE CVE_EMPRESA     =  @pCveEmpresa     AND
          ANO_MES         =  @pAnoMes         AND
          ID_TRANSACCION  =  @pIdTransaccion  AND
          CVE_OPER_CONT   =  @pCveOperCont    AND
	      CVE_CONC_TRANS  =  @pCveConcTrans
  END
  ELSE
  BEGIN
--    SELECT ' ERROR >>' + @pCveEmpresa + @pAnoMes + convert(varchar(20),@pIdTransaccion) + @pCveOperCont + @pCveConcTrans
    SET @pValor    =  '**** ERROR ****'
    SET @pImporte  =  9999
    SET @pEstatus  =   @k_warning
	SET @pError    =  'Cpto no local ' + @pCveEmpresa + @pAnoMes + convert(varchar(20),@pIdTransaccion) + @pCveOperCont + @pCveConcTrans
    SET @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

END