USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtTipoCamb]    Script Date: 12/03/2018 03:55:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  dbo.fnAcumMovtosBanc(f.ID_CONCILIA_CXC, f.CVE_F_MONEDA, f.IMP_F_NETO, f.IMP_F_IVA, f.F_OPERACION)		 

ALTER FUNCTION [dbo].[fnAcumMovtosBanc]
(
@pCveEmpresa    varchar(4),
@pAnoMes        varchar(6),
@pIdConciliaCXC int,
@pCveFMoneda    varchar(1),
@pImpFbruto     numeric(16,2),
@pFOperacion    date)
RETURNS         numeric(12,2)						  
AS
BEGIN
  DECLARE  @k_fact_iva        numeric(4,2) =  1.16,
		   @k_iva             numeric(4,2) =  .16,
		   @k_cxc             varchar(4)   =  'CXC',
		   @k_dolar           varchar(1)   =  'D',
		   @k_pesos           varchar(1)   =  'P'

  DECLARE  @imp_acum_pagos    numeric(16,2),
           @imp_utilidad      numeric(16,2),
		   @imp_p_factura     numeric(16,2)

  SET  @imp_acum_pagos  =  isnull((SELECT SUM(cc.IMP_PAGO_AJUST) FROM CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m WHERE
                           cc.ID_CONCILIA_CXC    =  @pIdConciliaCXC      AND
                           cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
						   m.CVE_TIPO_MOVTO      =  @k_cxc),0)

  IF  @pCveFMoneda  =  @k_dolar
  BEGIN
    SET  @imp_p_factura  =  @pImpFbruto * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @pFOperacion)
  END
  ELSE
  BEGIN
    SET  @imp_p_factura  =  @pImpFbruto
  END  

  SET  @imp_utilidad    = (@imp_acum_pagos / @k_fact_iva) -
						  @imp_p_factura

  return(@imp_utilidad)
END

