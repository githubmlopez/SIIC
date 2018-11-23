USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO


--exec spCuCoXCxC 'CU', 'MARIO', '201804', 1, 2, ' ', ' '
ALTER PROCEDURE spCuCoXCxC  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                   @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								   @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @k_legada         varchar(6)   =  'LEGACY',
           @k_peso           varchar(1)   =  'P',
		   @k_dolar          varchar(1)   =  'D',
  		   @k_activa         varchar(1)   =  'A',
		   @k_no_concilida   varchar(2)   =  'NC',
		   @k_error          varchar(1)   =  'K',
		   @k_cerrado        varchar(1)   =  'C',
           @k_no_act         numeric(9,0) =  99999,
		   @k_ind_cxc_p      varchar(10)  =  'CUCOCXC',
		   @k_ind_cxc_d      varchar(10)  =  'CUCOCXCD'

  DECLARE  @imp_tot_cxc      numeric(16,2),
           @num_reg_proc     int = 0

  BEGIN TRY

    IF  (SELECT SIT_PERIODO  FROM CI_PERIODO_CONTA WHERE ANO_MES = @pAnoMes) <> @k_cerrado
	BEGIN
      DELETE FROM CI_CUCO_C_X_C WHERE ANO_MES = @pAnoMes 
	END
	ELSE
	BEGIN

      INSERT INTO CI_CUCO_C_X_C (ANO_MES, CVE_EMPRESA, SERIE, ID_CXC, F_OPERACION, ID_CLIENTE, NOMBRE_CLIENTE, DESC_PRODUCTO_FACT,
                                 CVE_F_MONEDA, IMP_F_NETO, TIPO_CAMBIO, TX_NOTA, IMP_PESOS, TX_NOTA_COBRANZA)
      SELECT @pAnoMes, @pCveEmpresa, f.SERIE, f.ID_CXC, f.F_OPERACION, c.ID_CLIENTE, c.NOM_CLIENTE, 
             dbo.fnArmaProducto120(f.ID_CONCILIA_CXC),
             f.CVE_F_MONEDA, f.IMP_F_NETO, f.TIPO_CAMBIO, ' ', 
		     dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA), f.TX_NOTA_COBRANZA
      FROM CI_FACTURA f, CI_VENTA v, CI_CLIENTE c     
      WHERE f.CVE_EMPRESA         = @pCveEmpresa        AND
	        f.SIT_CONCILIA_CXC    = @k_no_concilida     AND
            f.ID_VENTA            = v.ID_VENTA          AND    
            v.ID_CLIENTE          = c.ID_CLIENTE        AND  
		    f.SERIE              <> @k_legada           AND   
	        f.SIT_TRANSACCION     = @k_activa  
  
      SET @imp_tot_cxc =
	  ISNULL((SELECT SUM(IMP_F_NETO)  FROM  CI_CUCO_C_X_C WHERE ANO_MES = @pAnoMes AND CVE_F_MONEDA = @k_peso),0)
  	  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ind_cxc_p,  @imp_tot_cxc, @k_no_act 

	  SET @imp_tot_cxc =
	  ISNULL((SELECT SUM(IMP_F_NETO)  FROM  CI_CUCO_C_X_C WHERE ANO_MES = @pAnoMes AND CVE_F_MONEDA = @k_dolar),0)
  	  EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @k_ind_cxc_d,  @imp_tot_cxc, @k_no_act 

	  SET @num_reg_proc = (SELECT COUNT(*)  FROM  CI_CUCO_C_X_C WHERE ANO_MES = @pAnoMes)

	  EXEC  spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc

	END

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error CUCO CXC ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc
END

