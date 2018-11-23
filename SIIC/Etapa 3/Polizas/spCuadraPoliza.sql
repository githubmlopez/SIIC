USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--exec spCuadraPoliza 'CU','201705', 'DR1', 19, 108, ' ', ' '

ALTER PROCEDURE spCuadraPoliza  @pIdProceso numeric(9), @pIdTarea numeric(9), 
                                @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pCvePoliza varchar(6), @IdEncaPoliza int,
                                @pError varchar(80) OUT, @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @k_cta_ganancia  varchar(30),
           @k_cta_perdida   varchar(30),
		   @k_no_transac    numeric(9),
		   @k_tc_fijo       varchar(30),
           @k_depto_fijo    varchar(30),
           @k_error         varchar(1),
		   @k_umbral		int      =  1
  
  DECLARE  @tot_cargos        numeric(16,2),
           @tot_abonos        numeric(16,2),
		   @cta_contable_p    varchar(30),
		   @conc_movimiento_p varchar(40),
		   @proyecto_p        varchar(50),
		   @imp_debe_p        numeric(16,2),
		   @imp_haber_p       numeric(16,2)
		  
   SET  @k_cta_ganancia   =  'CTAGANCAM' 
   SET  @k_cta_perdida    =  'CTAPERCAM'
   SET  @k_no_transac     =  999999999
   SET  @k_tc_fijo        =  '0'
   SET  @k_DEPTO_fijo     =  '1'
   SET  @k_error          =  'E'
   SET  @conc_movimiento_p = 'MOVIMIENTO DE AJUSTE POR ARITMETICA'

   SET  @proyecto_p       =  ' '
   SET  @tot_cargos       =  0
   SET  @tot_abonos       =  0
   SET  @imp_debe_p       =  0
   SET  @imp_haber_p      =  0
   
   SET  @tot_cargos  = (SELECT SUM(d.IMP_DEBE) FROM CI_DET_POLIZA d WHERE d.CVE_EMPRESA     =  @pCveEmpresa  AND
                                                                          d.ANO_MES         =  @pAnoMes      AND
                                                                          d.CVE_POLIZA      =  @pCvePoliza   AND
												                          d.ID_ENCA_POLIZA  =  @IdEncaPoliza)
   SET  @tot_abonos  = (SELECT SUM(d.IMP_HABER) FROM CI_DET_POLIZA d WHERE d.CVE_EMPRESA    =  @pCveEmpresa  AND
                                                                          d.ANO_MES         =  @pAnoMes      AND
                                                                          d.CVE_POLIZA      =  @pCvePoliza   AND
												                          d.ID_ENCA_POLIZA  =  @IdEncaPoliza)

--   SELECT 'Cargo - Abono  ' +  convert(varchar(20),@tot_cargos) + ' ' + convert(varchar(20),@tot_cargos)
   IF   @tot_cargos <  @tot_abonos
   BEGIN
--     select ' cargos mayores '
	 SET  @cta_contable_p  =  dbo.fnObtParAlfa(@k_cta_perdida)
	 SET  @imp_debe_p      =  ABS(@tot_cargos - @tot_abonos)
   END
   ELSE
   BEGIN
     IF   @tot_cargos >  @tot_abonos
     BEGIN
--	   select ' abonos mayores '
	   SET  @cta_contable_p   =  dbo.fnObtParAlfa(@k_cta_ganancia)
	   SET  @imp_haber_p      =  ABS(@tot_cargos - @tot_abonos)
     END
   END

   IF  @imp_debe_p  <>  0  or  @imp_haber_p  <>  0
   BEGIN
     
--	 select ' ** voy a crear detalle ** '

	 EXEC  spCreaPoliza @pIdTarea, @pIdProceso, @pCveEmpresa, @pAnoMes, @pCvePoliza,  @IdEncaPoliza, @k_no_transac, @cta_contable_p,
	                    @k_depto_fijo, @conc_movimiento_p,
                        @k_tc_fijo, @imp_debe_p, @imp_haber_p, @proyecto_p, @pError OUT, @pMsgError OUT  
 

     IF  (ABS(@imp_debe_p) + ABS(@imp_haber_p)) > @k_umbral  
     BEGIN
       SET  @pError    =  'Ajuste supera UMBRAL Póliza ' + CONVERT(VARCHAR(10),@IdEncaPoliza)
	   SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
	   EXECUTE spCreaTareaEvento @pCveEmpresa,  @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
     END
   END
																	  																	   
END

 