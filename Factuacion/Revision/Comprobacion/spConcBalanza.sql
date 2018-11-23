USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spConcBalanza]   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT


AS
BEGIN

  DECLARE @k_error     varchar(1) = 'E',
          @k_falso     bit        = 0

  BEGIN TRY

  DELETE  FROM  CI_BALANZA_OPERATIVA  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
                                             B_BALANZA    =  @k_falso    
  
  UPDATE CI_BALANZA_OPERATIVA  SET  SDO_INICIAL_C  =  0,
                                    IMP_CARGO_C    =  0,
     								IMP_ABONO_C    =  0,
									SDO_FINAL_C    =  0
  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes


  MERGE CI_BALANZA_OPERATIVA AS TARGET
       USING (
	          SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, SDO_INICIAL, IMP_CARGO, IMP_ABONO, SDO_FINAL  FROM  CI_BALANZA_OPER_CALC
			 )  AS SOURCE 
          ON TARGET.CVE_EMPRESA     = SOURCE.CVE_EMPRESA  AND
             TARGET.ANO_MES         = SOURCE.ANO_MES      AND
		     TARGET.CTA_CONTABLE    = SOURCE.CTA_CONTABLE  

  WHEN MATCHED THEN
       UPDATE 
          SET SDO_INICIAL_C = SOURCE.SDO_INICIAL,
		      IMP_CARGO_C   = SOURCE.IMP_CARGO,
		      IMP_ABONO_C   = SOURCE.IMP_ABONO,
			  SDO_FINAL_C   = SOURCE.SDO_FINAL

  WHEN NOT MATCHED BY TARGET THEN 
       INSERT (CVE_EMPRESA,
               ANO_MES,
               CTA_CONTABLE,
		       SDO_INICIAL,
		       IMP_CARGO,
               IMP_ABONO,
               SDO_FINAL,
			   SDO_INICIAL_C,
			   IMP_CARGO_C,
			   IMP_ABONO_C,
			   SDO_FINAL_C,
			   B_BALANZA)
       VALUES
              (SOURCE.CVE_EMPRESA,
		       SOURCE.ANO_MES,
		       SOURCE.CTA_CONTABLE,
               0,
			   0,
			   0,
			   0,
		       SOURCE.SDO_INICIAL,
			   SOURCE.IMP_CARGO,
		       SOURCE.IMP_ABONO,
		       SOURCE.SDO_FINAL,
			   @k_falso);

  SELECT ' TERMINE MERGE '

  -- 100-02-02-01
  IF  EXISTS(SELECT 1 FROM  CI_BALANZA_OPERATIVA  WHERE
             SUBSTRING(CTA_CONTABLE,11,12)  <> 0 AND
            (SDO_INICIAL  <>  SDO_INICIAL_C      OR 
             IMP_CARGO    <>  IMP_CARGO_C        OR
     		 IMP_ABONO    <>  IMP_ABONO_C        OR
			 SDO_FINAL    <>  SDO_FINAL_C        OR
			 B_BALANZA    =   @k_falso))
  BEGIN
    SET  @pError    =  'No cuadra balanza Previa y Balanza'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    
  END
			    

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Act Sdos Balanza'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END
