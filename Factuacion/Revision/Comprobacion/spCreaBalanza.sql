USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spCreaBalanza]   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
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

  DECLARE @k_error     varchar(1) = 'E',
          @k_enero     int        = 1,
		  @k_diciembre int        = 12


  DECLARE @ano          int,
          @mes          int,
		  @ano_mes_ant  varchar(6)

  DECLARE @SdosCtas as SDOSCTAS

-- Copia los saldos iniciales de cierre de año a la tabla CI_BALANZA_OPERATIVA
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  DELETE  CI_BALANZA_OPER_CALC  WHERE CVE_EMPRESA = @pCveEmpresa  AND
                                      ANO_MES     = @pAnoMes

  SELECT ' ** Termine de Borrar *'

  SET  @ano  =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @mes  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2))

  IF  @mes  <>  @k_enero
  BEGIN
    SET  @mes  =  @mes - 1
  END
  ELSE
  BEGIN
    SET  @ano  =  @ano  -  1
	SET  @mes  =  @k_diciembre
  END

  SET  @ano_mes_ant  =  dbo.fnArmaAnoMes (@ano, @mes)

  SELECT  ' Año Mes Anterior ', @ano_mes_ant
  
  BEGIN  TRY

  INSERT  CI_BALANZA_OPER_CALC (ANO_MES, CVE_EMPRESA, CTA_CONTABLE, SDO_INICIAL, IMP_CARGO, IMP_ABONO, SDO_FINAL)
  SELECT  @pAnoMes, @pCveEmpresa, CTA_CONTABLE, IMP_SALDO, 0,0, IMP_SALDO
  FROM CI_SDO_CIERRE_MES  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @ano_mes_ant

  SELECT  ' INSERTE LOS SALDOS INICIALES '

  INSERT	INTO  @SdosCtas 	
  SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, SUM(IMP_DEBE), SUM(IMP_HABER)  FROM CI_DET_POLIZA
  WHERE ANO_MES  >=   @pAnoMes
  GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE

  SELECT  ' CREO TABLA TEMPORAL '

  MERGE CI_BALANZA_OPER_CALC AS TARGET
       USING (
	          SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, IMP_CARGO_C, IMP_ABONO_C  FROM  @SdosCtas
			 )  AS SOURCE 
          ON TARGET.CVE_EMPRESA     = SOURCE.CVE_EMPRESA  AND
             TARGET.ANO_MES         = SOURCE.ANO_MES      AND
		     TARGET.CTA_CONTABLE    = SOURCE.CTA_CONTABLE  

  WHEN MATCHED THEN
       UPDATE 
          SET IMP_CARGO  = SOURCE.IMP_CARGO_C,
		      IMP_ABONO  = SOURCE.IMP_ABONO_C,
			  SDO_FINAL  = SDO_INICIAL  + SOURCE.IMP_ABONO_C -  SOURCE.IMP_CARGO_C

  WHEN NOT MATCHED BY TARGET THEN 
       INSERT (CVE_EMPRESA,
               ANO_MES,
               CTA_CONTABLE,
		       SDO_INICIAL,
		       IMP_CARGO,
               IMP_ABONO,
               SDO_FINAL)
       VALUES
              (SOURCE.CVE_EMPRESA,
		       @pAnoMes,
		       SOURCE.CTA_CONTABLE,
               0,
		       SOURCE.IMP_CARGO_C,
		       SOURCE.IMP_ABONO_C,
		       SOURCE.IMP_ABONO_C -  SOURCE.IMP_CARGO_C);

  SELECT ' TERMINE MERGE '
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Act Sdos Balanza'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END
