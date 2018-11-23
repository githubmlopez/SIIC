USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spActCifContDefPol 2017,07
CREATE PROCEDURE [dbo].[spActCifContDefPol]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                            @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								            @pMsgError varchar(400) OUT

AS
BEGIN

  DECLARE  @k_verdadero  bit         =   1,
           @k_activa     varchar(1)  =  'A',
		   @k_procesada  varchar(1)  =  'P',
		   @k_error      varchar(1)  =  'E'

  BEGIN TRY

  MERGE INTO FC_CIFRA_CONTROL TARGET
     USING (
            SELECT CVE_EMPRESA, ANO_MES, CVE_POLIZA,
		    SUM(ID_TRANSACCION) AS im, COUNT(*) AS tot
            FROM   CI_DET_POLIZA
            WHERE  
	   	       CVE_EMPRESA      =  @pCveEmpresa                 AND
		 	   ANO_MES          =  @pAnoMes                     AND
	           SIT_DET_POLIZA   =  @k_activa
		    GROUP BY CVE_EMPRESA, ANO_MES, CVE_POLIZA
           ) SOURCE
      ON TARGET.CVE_EMPRESA       = SOURCE.CVE_EMPRESA AND
           TARGET.ANO_MES         = SOURCE.ANO_MES AND
		   TARGET.CONCEPTO_PROC   = SOURCE.CVE_POLIZA
		 
  WHEN MATCHED THEN			
     UPDATE 
        SET TARGET.TOT_CONC_CAL = SOURCE.tot,
	        TARGET.IMP_CONC_CAL = SOURCE.im

  WHEN NOT MATCHED BY TARGET THEN 
     INSERT (CVE_EMPRESA,
             ANO_MES,
             ID_PROCESO,
             CONCEPTO_PROC,
             TOT_CONCEPTO,
             IMP_CONCEPTO,
             TOT_CONC_CAL,
             IMP_CONC_CAL) 
     VALUES
            (SOURCE.CVE_EMPRESA,
		     SOURCE.ANO_MES, 
	         @pIdProceso,
	         SOURCE.CVE_POLIZA,
		     0,
		     0,
		     1,
		     SOURCE.im);
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Cif Control Transac '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH


END