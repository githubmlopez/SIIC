USE [ADMON01]
GO

--exec spCalSdosCuentas 2017, 07 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXECUTE spCalSdosCuentas 2017,07
CREATE PROCEDURE [dbo].[spCalSdosCuentas]   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT


AS
BEGIN


--CREATE TYPE SDOSCTAS AS TABLE
--(CVE_EMPRESA          varchar(4)           not null,
-- ANO_MES              varchar(4)           not null,
-- CTA_CONTABLE         varchar(30)          not null,
-- IMP_CARGO_C          numeric(16,2)        null,
-- IMP_ABONO_C          numeric(16,2)        null)

declare @SdosCtas as SDOSCTAS

-- Copia los saldos iniciales de cierre de año a la tabla CI_BALANZA_OPERATIVA



MERGE CI_BALANZA_OPERATIVA AS TARGET
   USING CI_SDO_CIERRE_ANUAL AS SOURCE 
      ON TARGET.CVE_EMPRESA            = SOURCE.CVE_EMPRESA  AND
         SUBSTRING(TARGET.ANO_MES,1,4) = SOURCE.ANO          AND
		 TARGET.CTA_CONTABLE           = SOURCE.CTA_CONTABLE AND 
		 TARGET.CVE_EMPRESA            = @pCveEmpresa        AND
		 TARGET.ANO_MES                = @pAnoMes
WHEN MATCHED THEN
   UPDATE 
      SET SDO_INICIAL_C  = SOURCE.IMP_SALDO
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
           SDO_FINAL_C)
   VALUES
          (SOURCE.CVE_EMPRESA,
		   @pAnoMes,
		   SOURCE.CTA_CONTABLE,
		   0,
		   0,
		   0,
		   0,
		   SOURCE.IMP_SALDO,
		   0,
		   0,
		   SOURCE.IMP_SALDO);

-- Calcula el total de cargos y abonos correspondientes al mes

INSERT	INTO @SdosCtas 	
SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, SUM(IMP_DEBE), SUM(IMP_HABER)  FROM CI_DET_POLIZA
        WHERE ANO_MES  =  @pAnoMes
		GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE

-- Calcula los saldos iniciales con los movimientos del año antes del mes en curso 

MERGE INTO CI_BALANZA_OPERATIVA TARGET
   USING (
          SELECT CVE_EMPRESA, CTA_CONTABLE, 
		  @pAnoMes AS ANO_MES,
		  SUM(IMP_DEBE) AS td, SUM(IMP_HABER) AS th
            FROM CI_DET_POLIZA 
           WHERE ANO_MES      <>  @pAnoMes AND
		         SUBSTRING(ANO_MES,1,4) = SUBSTRING(@pAnoMes,1,4) AND
		         CVE_EMPRESA  =   @pCveEmpresa    
		   GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE
         ) SOURCE
      ON TARGET.CVE_EMPRESA  = SOURCE.CVE_EMPRESA AND
         TARGET.ANO_MES      = SOURCE.ANO_MES AND
		 TARGET.CTA_CONTABLE = SOURCE.CTA_CONTABLE 
WHEN MATCHED THEN
   UPDATE 
      SET TARGET.SDO_INICIAL = TARGET.SDO_INICIAL - SOURCE.td + SOURCE.th;

--  Actualiza los campos de calculo de cargos y abonos del mes

MERGE CI_BALANZA_OPERATIVA AS TARGET
   USING @SdosCtas AS SOURCE 
      ON TARGET.CVE_EMPRESA  = SOURCE.CVE_EMPRESA AND
         TARGET.ANO_MES      = SOURCE.ANO_MES     AND
		 TARGET.CTA_CONTABLE = SOURCE.CTA_CONTABLE 
WHEN MATCHED THEN
   UPDATE 
      SET IMP_CARGO   = SOURCE.IMP_CARGO_C, 
          IMP_ABONO   = SOURCE.IMP_ABONO_C,
		  SDO_FINAL_C = TARGET.SDO_INICIAL - SOURCE.IMP_CARGO_C + SOURCE.IMP_ABONO_C
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
           SDO_FINAL_C)
   VALUES
          (SOURCE.CVE_EMPRESA,
		   SOURCE.ANO_MES,
		   SOURCE.CTA_CONTABLE,
		   0,
		   0,
		   0,
		   0,
		   0,
		   SOURCE.IMP_CARGO_C,
		   SOURCE.IMP_ABONO_C,
		   SOURCE.IMP_CARGO_C + SOURCE.IMP_ABONO_C);
END

