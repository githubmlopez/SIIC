USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spBorraTransac  @pCveEmpresa varchar(4), @pAnoMes  varchar(6), @pIdProceso numeric(9)
AS
BEGIN

  IF  EXISTS(SELECT 1  FROM  FC_GEN_PROCESO_BIT  WHERE
              CVE_EMPRESA  =  @pCveEmpresa   AND
			  ID_PROCESO   =  @pIdProceso    AND
			  FT_PROCESO   =  @pAnoMes + '00')
  BEGIN
    DELETE CI_CONCEP_TRANSAC  WHERE  ID_TRANSACCION  IN
    (SELECT ID_TRANSACCION FROM  CI_TRANSACCION_CONT t WHERE
			t.CVE_EMPRESA  = @pCveEmpresa      AND
            t.ANO_MES      = @pAnoMes          AND
	        t.GPO_TRANSACCION IN
	       (SELECT GPO_TRANSACCION  FROM  FC_GEN_PROCESO_BIT  WHERE
            CVE_EMPRESA  =  @pCveEmpresa  AND
			ID_PROCESO   =  @pIdProceso   AND
			FT_PROCESO   =  @pAnoMes + '00'))

    
    DELETE CI_TRANSACCION_CONT  WHERE  GPO_TRANSACCION IN
	       (SELECT GPO_TRANSACCION  FROM  FC_GEN_PROCESO_BIT  WHERE
            CVE_EMPRESA  =  @pCveEmpresa  AND
			ID_PROCESO   =  @pIdProceso   AND
			FT_PROCESO   =  @pAnoMes + '00')

  END  

END