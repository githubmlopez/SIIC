USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION dbo.fnImpLiqPesos  (@pIdConciliaCXC int, @pAnoMes varchar(6))
RETURNS NUMERIC (16,2)					  
AS
BEGIN
  DECLARE @num_registros    int,
          @row_count        int,
		  @f_operacion      date,
		  @cve_moneda       varchar(1),
		  @imp_operacion    numeric(16,2)

  DECLARE @imp_oper_peso    numeric(16,2)
  
  DECLARE @k_dolar          varchar(1)   =  'D',
          @k_cxc            varchar(3)   =  'CXC',
		  @k_verdadero      bit          =  1,
		  @k_falso          bit          =  0
  
  DECLARE @PAGOS TABLE (RowID int IDENTITY(1, 1), f_operacion date, cve_moneda varchar(1), 
                        imp_operacion numeric(16,2))
  
  INSERT INTO @PAGOS  (f_operacion, cve_moneda, imp_operacion)
  SELECT m.F_OPERACION, ch.CVE_MONEDA, cc.IMP_PAGO_AJUST
  FROM  CI_FACTURA f, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE f.ID_CONCILIA_CXC     =  @pIdConciliaCXC      AND
        f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC   AND
		cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
		m.CVE_CHEQUERA	      =  ch.CVE_CHEQUERA      AND
		m.CVE_TIPO_MOVTO      =  @k_cxc               AND
		cc.ANOMES_PROCESO    <=  @pAnoMes

  SET @num_registros   = @@ROWCOUNT
  SET @row_count       = 1
  SET @imp_oper_peso   = 0

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @f_operacion =  f_operacion, @cve_moneda = cve_moneda, @imp_operacion  =  imp_operacion
    FROM @PAGOS
    WHERE RowID = @row_count
	BEGIN
 	  SET  @imp_oper_peso   =  @imp_oper_peso  +  @imp_operacion
	END

    SET @row_count = @row_count + 1
  END 

  RETURN @imp_oper_peso

END

