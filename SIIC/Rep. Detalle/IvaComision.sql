declare @pAnoMes     varchar(6) = '201801',
        @pCveMoneda  varchar(1) = 'D'
DECLARE  @k_activo     varchar(1)     =  'A',
         @k_iva_trans  varchar(6)     =  'CIC', 
		 @k_iva_comis  varchar(6)     =  'MIC', 
		 @k_fact_iva   numeric(4,2)  =  1.16,
		 @k_iva        numeric(4,2)  =  .16

SELECT m.ANO_MES, m.CVE_CHEQUERA, m.DESCRIPCION, ch.CVE_MONEDA, 
	   m.IMP_TRANSACCION,
	   dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, ch.CVE_MONEDA) AS IVA_PESOS
      
FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
WHERE  m.CVE_CHEQUERA =  ch.CVE_CHEQUERA  and
       dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes  AND
       m.SIT_MOVTO  =   @k_activo  AND
	   m.CVE_TIPO_MOVTO  in (@k_iva_trans, @k_iva_comis)  --AND
--	   ch.CVE_MONEDA  =  @pCveMoneda 
