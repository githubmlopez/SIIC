USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE spLimpCifControl
CREATE PROCEDURE spLimpCifControl  
      @pCveEmpresa         varchar(4),
      @pAnoMes             varchar(6),
      @pIdProceso          int,
	  @pCveTipo            varchar(1)

AS
BEGIN
   
   DECLARE @cve_poliza     varchar(6)

   DECLARE @k_cerrado      varchar(1)  =  'C',
           @k_transaccion  varchar(1)  =  'T',
		   @k_poliza       varchar(1)  =  'P',
		   @k_falso        bit         =   0
   

   SET  @cve_poliza  =  (SELECT SUBSTRING(PARAMETRO,1,6) FROM  FC_GEN_PROCESO  WHERE
                                CVE_EMPRESA  =  @pCveEmpresa  AND
								ID_PROCESO   =  @pIdProceso)

   IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE 
                            CVE_EMPRESA    =  @pCveEmpresa    AND
                            ANO_MES        =  @pAnoMes)  <>  @k_cerrado                

   BEGIN 
     DELETE FC_CIFRA_CONTROL
     WHERE 
	 CVE_EMPRESA    =  @pCveEmpresa    AND
     ANO_MES        =  @pAnoMes        AND        
     ID_PROCESO     =  @pIdProceso         
 
     IF @pCveTipo   =  @k_transaccion
	 BEGIN
       UPDATE CI_TRANSACCION_CONT SET B_PROCESADA  =  @k_falso  
	          WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND
			         ANO_MES      =  @pAnoMes      AND
					 CVE_OPER_CONT   IN
					 (SELECT  CVE_OPER_CONT  FROM  CI_POLIZA_TRANSAC  
					  WHERE   CVE_POLIZA  =  @cve_poliza)
			  
	 END
	 ELSE
	 BEGIN
	   UPDATE CI_DET_POLIZA SET B_PROCESADA  =  @k_falso  
	          WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND
			         ANO_MES      =  @pAnoMes      AND
					 CVE_POLIZA   =  @cve_poliza
	 END
   END 
             
END