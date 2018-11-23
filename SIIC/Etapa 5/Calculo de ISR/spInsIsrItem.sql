USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE [dbo].[spInsIsrItem]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pConcepto varchar(6),
                                      @pImpConcepto numeric(12,2) 
AS
BEGIN
  DECLARE  @k_ing_factura     varchar(10) = 'INGFAC', 
           @k_fac_cancel      varchar(10) = 'FACCAN', 
		   @k_int_bancario    varchar(10) = 'INTBAN',
		   @k_isr_bancario    varchar(10) = 'ISRBAN',
		   @k_util_camb       varchar(10) = 'UTILC'
 
--  select 'ENTRO A ISR ' + @pCveEmpresa + @pAnoMes + @pConcepto + CONVERT(VARCHAR(10), @pImpCOncepto)
  IF  @pConcepto =  @k_ing_factura
  BEGIN
    UPDATE  CI_PERIODO_ISR SET IMP_INGRESOS =  @pImpConcepto WHERE
	CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoMes
  END
  ELSE
  BEGIN
    IF  @pConcepto =  @k_fac_cancel
    BEGIN
      UPDATE  CI_PERIODO_ISR SET IMP_CANCELACIONES = @pImpConcepto  WHERE
	  CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoMes 
    END
    ELSE
    BEGIN
      IF  @pConcepto =  @k_int_bancario
      BEGIN
        UPDATE  CI_PERIODO_ISR SET IMP_INT_BANCARIO =  @pImpConcepto WHERE
		CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoMes
      END
      ELSE
      BEGIN
	    IF  @pConcepto =  @k_isr_bancario
        BEGIN
          UPDATE  CI_PERIODO_ISR SET IMP_ISR_BANCARIO =  @pImpConcepto WHERE 
		  CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoMes
        END
        ELSE
		BEGIN
          IF  @pConcepto =  @k_util_camb
          BEGIN
--            select 'act otros pros'
			UPDATE  CI_PERIODO_ISR SET IMP_OTR_PRODUC =  IMP_OTR_PRODUC + @pImpConcepto WHERE 
			CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoMes
          END
		END
      END
	END
  END

END
