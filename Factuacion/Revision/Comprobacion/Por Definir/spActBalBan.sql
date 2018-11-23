USE [ADMON01]
GO

--exec spActBalBan 2017, 07 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spActBalCxC 2017,07
ALTER PROCEDURE [dbo].[spActBalBan]   @pCveEmpresa varchar(4),
                                      @pAno int,
                                      @pMes int

AS
BEGIN
   
  MERGE CI_BALANZA_OPERATIVA AS TARGET
     USING 
	      (SELECT CVE_EMPRESA, cp. ANO_MES, c.CTA_CONTABLE
		  (select 'CU' AS CVE_EMPRESA, cp. ANO_MES, c.CTA_CONTABLE     
                 FROM  CI_CHEQUERA c, CI_CHEQUERA_PERIODO cp
				 WHERE c.CVE_CHEQUERA  =  cp.CVE_CHEQUERA    AND
				       cp.ANO_MES      =  dbo.fnArmaAnoMes(@pAno, @pMes)) sub
		         GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE)
         ) SOURCE
           ON TARGET.CVE_EMPRESA  = 'CU'           AND
              TARGET.ANO_MES      = SOURCE.ANO_MES AND
		      TARGET.CTA_CONTABLE = SOURCE.CTA_CONTABLE 

  WHEN MATCHED THEN
     UPDATE 
        SET IMP_CXC  = SOURCE.imp 

  WHEN NOT MATCHED BY TARGET THEN 
     INSERT (CVE_EMPRESA,
             ANO_MES,
             CTA_CONTABLE,
		     SDO_INICIAL,
		     IMP_CARGO,
             IMP_ABONO,
             SDO_FINAL,
             SALDO_INICIAL_C,
             IMP_CARGO_C,
             IMP_ABONO_C,
             SDO_FINAL_C
			 IMP_CALCULADO) 
     VALUES
            (SOURCE.CVE_EMPRESA,
		     SOURCE.ANO_MES,
		     SOURCE.CTA_CONTABLE,
		     0,
		     0,
		     0,
		     0,
		     0,
		     0,
		     0,
		     0,
			 SOURCE.imp);
END


 
		