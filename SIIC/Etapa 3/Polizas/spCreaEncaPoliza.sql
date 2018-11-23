USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spCreaEncaPoliza @pIdTarea numeric(9), @pIdProceso numeric(9), @pCveEmpresa varchar(6), @pAnoMes varchar(6),
                                  @pCvePoliza varchar(6), @pDescPoliza varchar(100), @pIdEncaPoliza int OUT,  
         						  @pError varchar(80) OUT, @pMsgError varchar(400) OUT
AS
BEGIN
   DECLARE  @k_activa       varchar(1),
            @k_enca_poliza  varchar(4),
			@k_error        varchar(1),
			@k_verdadero    bit   =  1 
      
   SET @pError         =  ' '
   SET @k_error        =  'E'
   SET @pMsgError      =  ' '
   SET @k_activa       =  'A'
   SET @k_enca_poliza  =  'ENCP'
   
   UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_enca_poliza
   SET  @pIdEncaPoliza  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_enca_poliza)  

   BEGIN TRY
 --    SELECT ' INTENTO INSERT ENCABEZADO'
     INSERT INTO  CI_ENCA_POLIZA
    (CVE_EMPRESA,
     ANO_MES,
     CVE_POLIZA,
     ID_ENCA_POLIZA,
	 DESC_POLIZA,
	 IMP_TOT_CARGO,
     IMP_TOT_ABONO,
     SIT_POLIZA,
	 B_AUTOMATICA)  VALUES
    (@pCveEmpresa,
     @pAnoMes,
     @pCvePoliza,
	 @pIdEncaPoliza,
     @pDescPoliza,
     0,
     0,
     @k_activa,
	 @k_verdadero)
--   SELECT ' SALGO INSERT ENCABEZADO'
   END  TRY
   BEGIN CATCH
    SET  @pError    =  'Error al insertar Encabezado de Poliza'
	SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
	EXECUTE spCreaTareaEvento @pCveEmpresa,  @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH;
END