declare @pAnoMes     varchar(6) = '201801',
        @pCveMoneda  varchar(1) = 'D'

DECLARE  @k_activo  varchar(1)     =  'A',
         @k_cxc     varchar(6)     =  'CXC',
		 @k_fact_iva numeric(4,2)  =  1.16,
		 @k_iva      numeric(4,2)  =  .16

SELECT m.ANO_MES, m.CVE_CHEQUERA, m.DESCRIPCION, ch.CVE_MONEDA, 
       m.IMP_TRANSACCION / @k_fact_iva AS IMP_BRUTO,
	  (m.IMP_TRANSACCION / @k_fact_iva) * @k_iva AS IVA,
	   m.IMP_TRANSACCION,
	   dbo.fnCalculaPesos(m.F_OPERACION, (m.IMP_TRANSACCION / @k_fact_iva) * @k_iva, ch.CVE_MONEDA) AS IVA_PESOS
      
FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_CONCILIA_C_X_C c
WHERE  m.ID_MOVTO_BANCARIO  =  c.ID_MOVTO_BANCARIO AND
       c.ANOMES_PROCESO  =  @pAnoMes  AND
       m.CVE_CHEQUERA =  ch.CVE_CHEQUERA  and
--       dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes  AND
       m.SIT_MOVTO  =   @k_activo  AND
	   m.CVE_TIPO_MOVTO  =  @k_cxc AND
	   ch.CVE_MONEDA  =  @pCveMoneda 
