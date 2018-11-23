USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spActBalCxC 2017,07
ALTER PROCEDURE [dbo].[spActBalCxC]   @pCveEmpresa varchar(4),
                                      @pAno int,
                                      @pMes int

AS
BEGIN
  DECLARE  @k_conciliada  varchar(2),
           @k_conc_error  varchar(2),
		   @k_legado      varchar(6),
		   @k_cancelada   varchar(1)
  
  SET @k_conciliada  =  'CC'
  SET @k_conc_error  =  'CE'
  SET @k_legado      =  'LEGACY'
  SET @k_cancelada   =  'C'

 -- CREATE TYPE SDOCALCTA AS TABLE
 --(CVE_EMPRESA          varchar(4)           not null,
 -- ANO_MES              varchar(4)           not null,
 -- CTA_CONTABLE         varchar(30)          not null,
 -- IMP_CUENTA           numeric(16,2)        not null)

  DECLARE @SdoCalCta as SDOCALCTA

  INSERT	INTO  @SdoCalCta 	
  SELECT    
          f.CVE_EMPRESA, dbo.fnArmaAnoMes(YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)),
		  dbo.fnObtCtaCont(c.ID_CLIENTE, f.CVE_F_MONEDA) AS CTA_CONTABLE, f.IMP_F_NETO
		  from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c     
          WHERE dbo.fnArmaAnoMes(YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) <=
                dbo.fnArmaAnoMes(YEAR(@pAno), MONTH(@pMes))                 AND
                f.SIT_CONCILIA_CXC    NOT IN (@k_conciliada,@k_conc_error)  AND    
                f.ID_VENTA            =  v.ID_VENTA                          AND
                v.ID_CLIENTE          =  c.ID_CLIENTE                        AND    
                f.SIT_TRANSACCION     <> @k_cancelada                   AND    
                f.SERIE <> @k_legado

  MERGE CI_BALANZA_OPERATIVA AS TARGET
     USING 
	     (
		  SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, SUM(IMP_CUENTA) AS IMP
		  FROM @SdoCalCta          
		  GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE
         ) SOURCE
           ON TARGET.CVE_EMPRESA  = SOURCE.CVE_EMPRESA AND
              TARGET.ANO_MES      = SOURCE.ANO_MES AND
		      TARGET.CTA_CONTABLE = SOURCE.CTA_CONTABLE 

  WHEN MATCHED THEN
     UPDATE 
        SET IMP_CXC  = SOURCE.IMP 

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
			 IMP_CXC) 
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
			 SOURCE.IMP);
END


 
		