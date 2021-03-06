USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE spAcumMovtosBanc  @pCveEmpresa varchar(4),@pIdConciliaCXC int, @pAnoMes varchar(6), 
                                  @pImpAcumBPeso numeric(12,2) OUT, @pImpAcumIPeso numeric(12,2) OUT,
                                  @pImpAcumNPeso numeric(12,2) OUT, @pImpAcumBDolar numeric(12,2) OUT,
								  @pImpAcumIDolar numeric(12,2) OUT, @pImpAcumNDolar numeric(12,2)	OUT,
								  @pCveMoneda varchar(1) OUT								   
AS
BEGIN
  DECLARE @num_registros  int,
          @row_count      int,
		  @f_operacion    date,
		  @cve_moneda     varchar(1),
		  @imp_operacion  numeric(16,2)
  
  DECLARE @k_dolar        varchar(1)   =  'D',
          @k_cxc          varchar(3)   =  'CXC',
		  @k_fac_iva      numeric(8,2) =  1.16,
		  @k_iva          numeric(4,2) =  .16

  DECLARE @PAGOS TABLE (RowID int IDENTITY(1, 1), f_operacion date, cve_moneda varchar(1), imp_operacion numeric(12,2))
  
  INSERT INTO @PAGOS  (f_operacion, cve_moneda, imp_operacion)
  SELECT m.F_OPERACION, ch.CVE_MONEDA, m.IMP_TRANSACCION 
  FROM  CI_FACTURA f, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE f.ID_CONCILIA_CXC     =  @pIdConciliaCXC      AND
        f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC   AND
		cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
		m.CVE_CHEQUERA	      =  ch.CVE_CHEQUERA      AND
		m.CVE_TIPO_MOVTO      =  @k_cxc               AND
		cc.ANOMES_PROCESO     =  @pAnoMes

  SET @num_registros = @@ROWCOUNT
  SET @row_count     = 1

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @f_operacion =  f_operacion, @cve_moneda = cve_moneda, @imp_operacion  =  imp_operacion
    FROM @PAGOS
    WHERE RowID = @row_count

	SET  @pImpAcumIPeso  =   0
    SET  @pImpAcumNPeso  =   0
   	SET  @pImpAcumBPeso  =   0
    SET  @pImpAcumIDolar =   0    
	SET  @pImpAcumNDolar =   0
	SET  @pImpAcumBDolar =   0 
	SET  @cve_moneda     =   @pCveMoneda

    IF  @cve_moneda  =  @k_dolar
	BEGIN
	  SET  @pImpAcumIPeso  =   ROUND(((@imp_operacion  * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion))  /  @k_fac_iva) * @k_iva,2)
      SET  @pImpAcumNPeso  =   ROUND(@imp_operacion  * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion),2)
   	  SET  @pImpAcumBPeso  =   @pImpAcumNPeso  - @pImpAcumIPeso
      SET  @pImpAcumIDolar =   ROUND(@imp_operacion  /  1.15,2)    
	  SET  @pImpAcumNDolar =   @imp_operacion
	  SET  @pImpAcumBDolar =   @pImpAcumNDolar - @pImpAcumIDolar 
	END
	ELSE
	BEGIN
	  SET  @pImpAcumIDolar =   ROUND(((@imp_operacion  / dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion))  /  @k_fac_iva) * @k_iva,2)
      SET  @pImpAcumNDolar =   ROUND(@imp_operacion  / dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion),2)
   	  SET  @pImpAcumBDolar =   @pImpAcumNDolar  - @pImpAcumIDolar
      SET  @pImpAcumIPeso  =   ROUND(@imp_operacion  /  1.15,2)    
	  SET  @pImpAcumNPeso  =   @imp_operacion
	  SET  @pImpAcumBPeso  =   @pImpAcumNPeso - @pImpAcumIPeso  
	END

    SET @row_count = @row_count + 1

  END 

END

