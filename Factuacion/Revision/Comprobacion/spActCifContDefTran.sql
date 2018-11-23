USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spActCifContDefTran 1,'CU',2016,01
CREATE PROCEDURE [dbo].[spActCifContDefTran] @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                            @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								            @pMsgError varchar(400) OUT

AS
BEGIN
  
  BEGIN TRY

  DECLARE  @k_verdadero  bit         =   1,
           @k_activa     varchar(1)  =  'A',
		   @k_procesada  varchar(1)  =  'P',
		   @k_error      varchar(1)  =  'E'

  MERGE INTO FC_CIFRA_CONTROL TARGET
     USING (
            SELECT CVE_EMPRESA, ANO_MES, CVE_OPER_CONT,
		    SUM(ID_TRANSACCION) AS im, COUNT(*) AS tot
            FROM   CI_TRANSACCION_CONT
            WHERE  
		         CVE_EMPRESA      =  @pCveEmpresa                    AND
			     ANO_MES          =  @pAnoMes                        AND
	             SIT_TRANSACCION  IN (@k_activa) 

		     GROUP BY CVE_EMPRESA, ANO_MES, CVE_OPER_CONT
           ) SOURCE
        ON TARGET.CVE_EMPRESA     = SOURCE.CVE_EMPRESA AND
           TARGET.ANO_MES         = SOURCE.ANO_MES AND
		   TARGET.CONCEPTO_PROC   = SOURCE.CVE_OPER_CONT
		 
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
		     SOURCE.CVE_OPER_CONT,
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