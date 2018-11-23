USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

ALTER PROCEDURE [dbo].[spRegIva]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @CveTipo varchar(1), @pImpIva numeric(16,2), 
                                  @pConcepto varchar(400), @pRfc varchar(15), @pBAredita bit, @pAnoMesAcred varchar(6),
								  @pIdMovtoBancario numeric(9,0)  
AS
BEGIN
  DECLARE  @k_otro        varchar(2)   =  '85',
           @k_iva         numeric(6,2) =  .16
		   
  DECLARE  @imp_bruto     numeric(16,2)	

  SET  @imp_bruto  =  @pImpIva / @k_iva

  INSERT  CI_PERIODO_IVA  (CVE_EMPRESA, ANO_MES, CVE_TIPO, IMP_IVA, IMP_BRUTO, CONCEPTO, RFC, ID_PROVEEDOR, CVE_TIPO_OPERACION,
                           B_ACREDITADO, ANO_MES_ACRED, ID_MOVTO_BANCARIO) VALUES
	                      (@pCveEmpresa, @pAnoMes, @CveTipo, @pImpIva, @imp_bruto ,@pConcepto, @pRfc,0,@k_otro,
						   @pBAredita, @pAnoMesAcred, @pIdMovtoBancario)
END
