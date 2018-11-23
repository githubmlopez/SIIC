USE [ADMON01]
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER  PROCEDURE spCreaPoliza   @pIdTarea int, @pIdProceso int, @pCveEmpresaP varchar(4), @pAnoMesP varchar(6), @pCvePolizaP varchar(6), 
                                 @pIdEncaPolizaP int, @pIdTransaccion numeric(9),
                                 @pCtaContableP varchar(30), @pDescDepartamentoP varchar(120), @pConcMovimientoP varchar(400),
                                 @pTipoCambioP numeric(8,4), @pImpDebeP numeric(16,2), @pImpHaberP numeric(16,2), @pProyectoP varchar(50),
								 @pError varchar(80) OUT, @pMsgError varchar(400) OUT     
AS  
BEGIN
 -- SELECT ' ENTRO A PROCEDIMIENTO CREA POLIZA'
  DECLARE
  @k_error          varchar(1),
  @k_id_det_pol     varchar(4),
  @k_activa         varchar(1)  =  'A',
  @k_falso          varchar(1)  =  0

  DECLARE
  @id_det_poliza       int

  SET  @k_error       =  'E'
  SET  @k_id_det_pol  =  'DETP'
 
  SET  @pError      =  ' '
  SET  @pMsgError   =  ' '
      
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_det_pol
  SET  @id_det_poliza  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_det_pol) 
  
-- SELECT ' ENTRO A INSERTAR DETALLE DE POLIZA'
  BEGIN TRY
 --  SELECT ' INTENTO CREAR DETALLE DE POLIZA' + @pCtaContableP
    INSERT  INTO  CI_DET_POLIZA
   (CVE_EMPRESA,
    ANO_MES,
    CVE_POLIZA,
    ID_ENCA_POLIZA,
    ID_ASIENTO,
	ID_TRANSACCION,
    CTA_CONTABLE,
    DESC_DEPARTAMENTO,
    CONC_MOVIMIENTO,
    TIPO_CAMBIO_P,
    IMP_DEBE,
    IMP_HABER,
    PROYECTO,
	SIT_DET_POLIZA,
	B_PROCESADA)  VALUES
   (@pCveEmpresaP,
	@pAnoMesP,
	@pCvePolizaP,
	@pIdEncaPolizaP,
	@id_det_poliza,
    @pIdTransaccion,
	@pCtaContableP,
	@pDescDepartamentoP,
	@pConcMovimientoP,
	@pTipoCambioP,
	@pImpDebeP,
	@pImpHaberP,
	@pProyectoP,
	@k_activa,
	@k_falso) 
-- SELECT ' OK CREAR DETALLE DE POLIZA'    
--SELECT ' SALGO DE INSERTAR DETALLE DE POLIZA'
	UPDATE  CI_ENCA_POLIZA  SET IMP_TOT_CARGO = IMP_TOT_CARGO  +  @pImpDebeP,
	                            IMP_TOT_ABONO  = IMP_TOT_ABONO  +  @pImpHaberP
		    WHERE  CVE_EMPRESA     =  @pCveEmpresaP    AND
	               ANO_MES         =  @pAnoMesP        AND
	               CVE_POLIZA      =  @pCvePolizaP     AND
	               ID_ENCA_POLIZA  =  @pIdEncaPolizaP           

--SELECT ' SALGO DE UPDATE ENCABEZADO'
  Exec spActCifControl  
       @pIdProceso,
       @pIdTarea,
       @pCvePolizaP,
       @pCveEmpresaP,
	   @pIdTransaccion,
       @pAnoMesP,
	   @pError OUT,
       @pMsgError OUT
  
  
  END  TRY
  BEGIN CATCH
--    SELECT ' SE PRESENTO UN ERROR'
    SET  @pError    =  'Error insert detalle de Poliza o Act Encabezado'
	SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
	EXECUTE spCreaTareaEvento @pCveEmpresaP,  @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END
