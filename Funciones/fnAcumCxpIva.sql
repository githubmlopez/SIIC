USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtTipoCamb]    Script Date: 12/03/2018 03:55:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnAcumCxpIva] (@pAnoMes  varchar(6))
RETURNS numeric(12,2)						  
AS
BEGIN
  DECLARE @num_registros  int,
          @row_count      int,
		  @f_operacion    date,
		  @cve_moneda     varchar(1),
		  @imp_operacion  numeric(12,2),
		  @imp_movtos     numeric(12,2)
  
  DEClARE @k_dolar        varchar(1)  =  'D',
          @k_activa       varchar(3)  =  'A'
  
  DECLARE @CXP TABLE (RowID int IDENTITY(1, 1), f_operacion date, cve_moneda varchar(1), imp_iva numeric(12,2))
  
  INSERT INTO @CXP  (f_operacion, cve_moneda, imp_iva)
  SELECT c.F_CAPTURA, c.CVE_MONEDA, i.IVA 
  FROM  CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i
  WHERE c.CVE_EMPRESA  =  i.CVE_EMPRESA  AND
        c.ID_CXP       =  i.ID_CXP       AND
		c.SIT_C_X_P    =  @k_activa      AND
		dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoMes 

  SET @num_registros = @@ROWCOUNT
  SET @row_count     = 1
  SET @imp_movtos    = 0

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @f_operacion =  f_operacion, @cve_moneda = cve_moneda, @imp_operacion  =  imp_iva
    FROM @CXP
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

