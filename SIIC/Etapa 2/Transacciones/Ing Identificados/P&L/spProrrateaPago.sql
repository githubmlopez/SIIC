USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
-- EXECUTE spProrrateaPago  '201804'

ALTER PROCEDURE [dbo].[spProrrateaPago] @pCveEmpresa varchar(4), @pAnoMes varchar(6)
AS
BEGIN

  DECLARE  @id_concilia_cxc   numeric(9,0),
		   @id_movto_bancario numeric(9,0),
		   @imp_transaccion   numeric(16,2),
		   @imp_f_neto        numeric(16,2),
		   @cve_f_moneda      varchar(1),
		   @cve_moneda        varchar(1),
		   @f_operacion       date,
		   @f_operacion_m     date

-- 0 - Una Factura que no tiene pagos relacionados
-- 1 - Una Factura que tiene un solo movimiento de pago relacionado
-- 2 - Una Factura relacionada a varios pagos
-- 3 - Varias Facturas relacionadas a un solo pago
-- 4 - Varias Facturas relacionadas a varios Pagos 

  DECLARE  @k_cuenta_x_pagar   varchar(4)  = 'CXC',
           @k_cancelada        varchar(1)  = 'C',
		   @k_pesos            varchar(1)  = 'P',
		   @k_dolares          varchar(1)  = 'D',
   		   @k_1fact_1pag       varchar(1)  = '1',
   		   @k_1fact_Npag       varchar(1)  = '2',
		   @k_Nfact_1pag       varchar(1)  = '3',
		   @k_Nfact_Npag       varchar(1)  = '4'


  DECLARE  @imp_pago           numeric(16,2),
           @imp_facturado      numeric(16,2),
           @imp_dif_pago_fact  numeric(16,2),
           @folio_max          int,
		   @pje_tot_fact       numeric(8,6)

  DECLARE  @NunRegistros    int, 
           @RowCount        int,
		   @cve_liq_fac     varchar(1)
  
  DECLARE  @TConcilia        TABLE
          (RowID             int  identity(1,1),
		   ID_CONCILIA_CXC   numeric(9,0),
		   ID_MOVTO_BANCARIO numeric(9,0),
		   IMP_TRANSACCION   numeric(16,2),
		   IMP_F_NETO        numeric(16,2),
		   CVE_F_MONEDA      varchar(1),
		   CVE_MONEDA        varchar(1),
		   F_OPERACION       date,
		   F_OPERACION_M     date)

  UPDATE  CI_CONCILIA_C_X_C SET IMP_PAGO_AJUST = 0 WHERE  ANOMES_PROCESO =  @pAnoMes

  INSERT   @TConcilia
  SELECT   cc.ID_CONCILIA_CXC, cc.ID_MOVTO_BANCARIO, m.IMP_TRANSACCION, f.IMP_F_NETO, f.CVE_F_MONEDA,
           ch.CVE_MONEDA, f.F_OPERACION, m.F_OPERACION
  FROM     CI_CONCILIA_C_X_C cc, CI_FACTURA f, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
           WHERE  cc.ANOMES_PROCESO    =  @pAnoMes             AND
		          cc.ID_CONCILIA_CXC   =  f.ID_CONCILIA_CXC    AND
				  cc.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND
				  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
				  m.CVE_TIPO_MOVTO     =  @k_cuenta_x_pagar

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT 
	@id_concilia_cxc   =  ID_CONCILIA_CXC, 
	@id_movto_bancario =  ID_MOVTO_BANCARIO,
	@imp_transaccion   =  IMP_TRANSACCION,
	@imp_f_neto        =  IMP_F_NETO,
	@cve_f_moneda      =  CVE_F_MONEDA,      
	@cve_moneda        =  CVE_MONEDA,
	@f_operacion       =  F_OPERACION,
	@f_operacion_m     =  F_OPERACION_M
	FROM  @TConcilia
	WHERE RowID  =  @RowCount

    EXEC  spDetCasoFacturaCom @id_concilia_cxc, @cve_liq_fac OUT

	IF  @cve_liq_fac  IN  (@k_1fact_1pag,@k_1fact_Npag)
	BEGIN
	  IF  @cve_moneda  =  @k_dolares
	  BEGIN
        UPDATE CI_CONCILIA_C_X_C  SET  IMP_PAGO_AJUST  =  IMP_PAGO_AJUST + @imp_transaccion *
		dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion_m) 
		WHERE ID_CONCILIA_CXC    =  @id_concilia_cxc  AND
		      ID_MOVTO_BANCARIO  =  @id_movto_bancario
	  END
      ELSE
	  BEGIN
        UPDATE CI_CONCILIA_C_X_C  SET  IMP_PAGO_AJUST  =  IMP_PAGO_AJUST + @imp_transaccion  
		WHERE ID_CONCILIA_CXC    =  @id_concilia_cxc  AND
		      ID_MOVTO_BANCARIO  =  @id_movto_bancario
	  END
	END
	ELSE
	BEGIN
      IF  @cve_liq_fac  IN  (@k_Nfact_1pag)
      BEGIN
		SET @imp_facturado =  ISNULL((SELECT SUM(f.IMP_F_NETO) FROM  CI_CONCILIA_C_X_C cc, CI_FACTURA f 
                               WHERE cc.ID_CONCILIA_CXC    = f.ID_CONCILIA_CXC   AND
                                     cc.ID_MOVTO_BANCARIO  = @id_movto_bancario  AND
				       			     f.SIT_TRANSACCION    <> @k_cancelada),0)                                  

        SET @pje_tot_fact  =  ISNULL((((@imp_f_neto * 100) / @imp_facturado)) / 100 ,0)  
		IF  @cve_moneda  =  @k_dolares
		BEGIN
		  UPDATE  CI_CONCILIA_C_X_C  SET  IMP_PAGO_AJUST  =  @imp_transaccion * @pje_tot_fact *
		  dbo.fnObtTipoCambC (@pCveEmpresa, @pAnoMes ,@f_operacion_m)
		  WHERE ID_CONCILIA_CXC  =  @id_concilia_cxc  AND  ID_MOVTO_BANCARIO = @id_movto_bancario
		END
		ELSE
		BEGIN
		  UPDATE  CI_CONCILIA_C_X_C  SET  IMP_PAGO_AJUST  =  @imp_transaccion * @pje_tot_fact 
		  WHERE ID_CONCILIA_CXC  =  @id_concilia_cxc  AND  ID_MOVTO_BANCARIO = @id_movto_bancario
		END
	  END
	  ELSE
	  BEGIN
        UPDATE CI_CONCILIA_C_X_C  SET  IMP_PAGO_AJUST  =  0 
		WHERE ID_CONCILIA_CXC    =  @id_concilia_cxc  AND
		      ID_MOVTO_BANCARIO  =  @id_movto_bancario
	  END
	END
	
    SET @RowCount  =  @RowCount  +  1
  END

END



