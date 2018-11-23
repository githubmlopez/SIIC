USE ADMON01
GO

--DECLARE @cve_liq_fac varchar (1)
--EXEC spDetCasoFacturaCom 336,@cve_liq_fac
--select @cve_liq_fac

ALTER PROCEDURE spDetCasoFacturaCom (@id_concilia_cxc int, @pcve_liq_fac varchar(1) OUT)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  DECLARE @id_mov_bancario     int,
		  @imp_transaccion     numeric(12,2),
          @f_operacion         date,
		  @cve_r_moneda        varchar(1),
		  @cve_cargo_abono     varchar(1)
  
  DECLARE @contador_mv       int,
          @cve_liq_fac       int,
		  @contador_fc       int,
		  @NunRegistros      int,
          @RowCount          int,
		  @b_una_factura     bit
  
  DECLARE @k_verdadero       varchar(1),
          @k_falso           varchar(1)
  
  IF OBJECT_ID('tempdb..#mov_bancario') IS NOT NULL DROP TABLE #mov_bancario
    
  SET @k_verdadero  =  1
  SET @k_falso      =  0
  SET @contador_mv  =  0
  SET @contador_fc  =  0

-- 0 - Una Factura que no tiene pagos relacionados
-- 1 - Una Factura que tiene un solo movimiento de pago relacionado
-- 2 - Una Factura relaciona da a varios pagos
-- 3 - Varias Facturas relacionadas a un solo pago
-- 4 - Varias Facturas relacionadas a varios Pagos 

  SET  @contador_mv = (SELECT COUNT(*) FROM CI_CONCILIA_C_X_C  WHERE ID_CONCILIA_CXC  =  @id_concilia_cxc)

  IF  @contador_mv  =  0  or  @contador_mv IS NULL
  BEGIN 
 	SET  @pcve_liq_fac  =  0
  END
  ELSE
  BEGIN
    IF  @contador_mv  =  1  
    BEGIN 
	  SET  @pcve_liq_fac = 1
      SET  @id_mov_bancario  =
	  ISNULL((SELECT ID_MOVTO_BANCARIO FROM CI_CONCILIA_C_X_C  WHERE ID_CONCILIA_CXC  =  @id_concilia_cxc),0)
	  SET  @contador_fc  =
	  ISNULL((SELECT COUNT(*) FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO =  @id_mov_bancario),0)
	  IF   @contador_fc  >  1  
	  BEGIN
		SET  @pcve_liq_fac = 3
	  END
    END
    ELSE
    BEGIN
-- En este punto se determina que la factura tiene mas de un pago
      CREATE TABLE #mov_bancario (
              RowID              int IDENTITY(1, 1), 
              ID_MOVTO_BANCARIO  int,
		      IMP_TRANSACCION    numeric(12,2),
              F_OPERACION        date,
			  CVE_R_MONEDA       varchar(1),
			  CVE_CARGO_ABONO    varchar(1))
	  
	  INSERT INTO #mov_bancario (ID_MOVTO_BANCARIO, IMP_TRANSACCION, F_OPERACION, CVE_R_MONEDA, CVE_CARGO_ABONO)
	  SELECT c.ID_MOVTO_BANCARIO,
             m.IMP_TRANSACCION,
			 m.F_OPERACION,
			 ch.CVE_MONEDA,
			 m.CVE_CARGO_ABONO
			 FROM  CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
			 WHERE
			 c.ID_CONCILIA_CXC   =  @id_concilia_cxc     AND
			 c.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND
			 m.CVE_CHEQUERA      =   ch.CVE_CHEQUERA 

	  SET @NunRegistros   = @@ROWCOUNT
      SET @RowCount       = 1
	  SET @b_una_factura  =  @k_verdadero

      WHILE @RowCount <= @NunRegistros
      BEGIN
	    SELECT @id_mov_bancario = ID_MOVTO_BANCARIO, @imp_transaccion = IMP_TRANSACCION, 
	           @f_operacion = F_OPERACION, @cve_r_moneda = CVE_R_MONEDA, @cve_cargo_abono = CVE_CARGO_ABONO
        FROM   #mov_bancario
        WHERE  RowID = @RowCount
--		SELECT 'MB ' + CONVERT(VARCHAR(10), @id_mov_bancario)
--		SELECT 'COUNT ' + CONVERT(VARCHAR(4), (SELECT COUNT(--*) FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO =  @id_mov_bancario))
	    IF (SELECT COUNT(*) FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO =  @id_mov_bancario) > 1
	    BEGIN
	      SET @b_una_factura = @k_falso
	    END
			   
	    SET @RowCount = @RowCount + 1 		 
	  END
	  
	  IF  @b_una_factura = @k_verdadero
	  BEGIN
	    SET  @pcve_liq_fac  =  2
	  END
      ELSE
	  BEGIN
	    SET  @pcve_liq_fac  =  4
	  END
    END
  END

END

