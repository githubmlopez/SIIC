USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtTipoCamb]    Script Date: 12/03/2018 03:55:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnAcumMovtosBancMes] (@pIdConciliaCXC int, @pAnoMes varchar(6))
RETURNS numeric(12,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @num_registros  int,
          @row_count      int,
		  @f_operacion    date,
		  @cve_moneda     varchar(1),
		  @imp_operacion  numeric(12,2),
		  @imp_movtos     numeric(12,2)
  
  DEClARE @k_dolar        varchar(1)  =  'D',
          @k_cxc          varchar(3)  =  'CXC',
		  @k_parcial      varchar(2)  =  'CP'
  
  DECLARE @PAGOS TABLE (RowID int IDENTITY(1, 1), f_operacion date, cve_moneda varchar(1), imp_operacion numeric(12,2))
  
  INSERT INTO @PAGOS  (f_operacion, cve_moneda, imp_operacion)
  SELECT m.F_OPERACION, ch.CVE_MONEDA, m.IMP_TRANSACCION 
  FROM  CI_FACTURA f, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE f.ID_CONCILIA_CXC     =  @pIdConciliaCXC      AND
        f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC   AND
		f.SIT_CONCILIA_CXC    =  @k_parcial           AND
		cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
		m.CVE_CHEQUERA	      =  ch.CVE_CHEQUERA      AND
		m.CVE_TIPO_MOVTO      =  @k_cxc               AND
	    dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes 

  SET @num_registros = @@ROWCOUNT
  SET @row_count     = 1
  SET @imp_movtos    = 0

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @f_operacion =  f_operacion, @cve_moneda = cve_moneda, @imp_operacion  =  imp_operacion
    FROM @PAGOS
    WHERE RowID = @row_count

    IF  @cve_moneda  =  @k_dolar
	BEGIN
	  SET  @imp_movtos  =  @imp_movtos  +  ROUND((@imp_operacion * dbo.fnObtTipoCamb(@f_operacion)),2)
	END
	ELSE
	BEGIN
	  SET  @imp_movtos  =  @imp_movtos  +  @imp_operacion 
	END

    SET @row_count = @row_count + 1

  END 

  return(@imp_movtos)
END

