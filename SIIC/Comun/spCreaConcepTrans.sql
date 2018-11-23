USE [ADMON01]
GO

--exec spTranFacturacion 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
 
ALTER PROCEDURE spCreaConcepTrans
  @pIdProceso         int,
  @pIdTarea           int,
  @pCveEmpresa        varchar(4),  
  @pAnoMes            varchar(6),
  @pIdTransaccion     int,
  @pCveOperCont       varchar(4),
  @pCveConcTrans      varchar(4),
  @pImporte           numeric(16,2),
  @pCadena            varchar(250),
  @pError             varchar(100) OUT,
  @pMsgError          varchar(400) OUT

AS
BEGIN

  DECLARE
  @k_id_secuencia   varchar(4),
  @k_error          varchar(1)

  DECLARE  
  @imp_concepto     numeric(14,4),
  @concepto         varchar(250),
  @cve_naturaleza   varchar(1),
  @longitud         int 

  SET  @k_error       =  'E'
  --SELECT ' ??? STORE INSERT CONCEPTOS ?? '
  --SELECT ' CADENA ' + @pCadena
  IF  EXISTS (SELECT 1 FROM CI_CONC_TRANSACCION WHERE                                      
                                             CVE_EMPRESA     = @pCveEmpresa     AND
											 CVE_CONC_TRANS  = @pCveConcTrans)
  BEGIN
    SELECT @cve_naturaleza = CVE_NATURALEZA, @longitud = LONG_CONCEPTO
	FROM  CI_CONC_TRANSACCION 
	WHERE CVE_EMPRESA     = @pCveEmpresa  AND
          CVE_CONC_TRANS  = @pCveConcTrans
    BEGIN TRY
      --SELECT ' ¡¡¡ CONCEP TRANSAC INSERT ' + CONVERT(VARCHAR(5),@longitud)
	  INSERT  CI_CONCEP_TRANSAC (
      CVE_EMPRESA,
      ANO_MES,
      ID_TRANSACCION,
      CVE_OPER_CONT,
      CVE_CONC_TRANS,
      IMP_CONCEPTO,
      VALOR_CONCEPTO) VALUES
     (@pCveEmpresa,
	  @pAnoMes,
	  @pIdTransaccion,
	  @pCveOperCont,
	  @pCveConcTrans,
	  @pImporte,
	  substring(@pCadena,1,@longitud))
      --SELECT ' ¡¡¡ SALE CONCEP TRANSAC INSERT '

   END TRY
     
   BEGIN CATCH
     IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
     BEGIN
	    CLOSE cur_transaccion
        DEALLOCATE cur_transaccion
     END
     SET  @pError    =  'Error al insertar Concepto de Transaccion'
     SET  @pMsgError =  @pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' ')
     EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
   END CATCH;
	  																    
  END

END