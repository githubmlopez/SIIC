-- EXECUTE spCCProrrateaPago  2017,05

ALTER PROCEDURE [dbo].[spCCProrrateaPago]   @pid_concilia_cxc int

AS
BEGIN

  DECLARE  @ano_mes            VARCHAR(6),
           @id_movto_bancario  INT

  DECLARE  @k_abono            varchar(1)

  DECLARE  @imp_pago           NUMERIC(12,2),
           @imp_facturado      NUMERIC(12,2),
           @imp_dif_pago_fact  NUMERIC(12,2),
           @folio_max          INT

  SET  @k_abono  =  'A'
      
  UPDATE CI_CONCILIA_C_X_C  SET IMP_PAGO_AJUST = m.IMP_TRANSACCION
  FROM   CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
  WHERE  cc.ID_CONCILIA_CXC      =  @pid_concilia_cxc   AND
         cc.ID_MOVTO_BANCARIO    =  m.ID_MOVTO_BANCARIO  


  DECLARE varias_fact_un_pago CURSOR FOR 
  SELECT  cc.ID_MOVTO_BANCARIO FROM  CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
  WHERE
  cc.ID_CONCILIA_CXC      =  @pid_concilia_cxc   AND
  m.CVE_CARGO_ABONO       =  @k_abono

  OPEN  varias_fact_un_pago

  FETCH varias_fact_un_pago INTO @id_movto_bancario   

  WHILE (@@fetch_status = 0 )
  BEGIN
    UPDATE CI_CONCILIA_C_X_C  SET IMP_PAGO_AJUST = f.IMP_F_NETO
    FROM   CI_CONCILIA_C_X_C cc, CI_FACTURA f
    WHERE  cc.ID_CONCILIA_CXC    =  f.ID_CONCILIA_CXC  AND
           cc.ID_MOVTO_BANCARIO  =  @id_movto_bancario


    SELECT @imp_pago   =  m.IMP_TRANSACCION FROM CI_MOVTO_BANCARIO m  
                                            WHERE m.ID_MOVTO_BANCARIO = @id_movto_bancario

    SELECT @imp_facturado =  SUM(f.IMP_F_NETO) FROM  CI_CONCILIA_C_X_C cc, CI_FACTURA f 
                                               WHERE cc.ID_CONCILIA_CXC = f.ID_CONCILIA_CXC  and
                                                     cc.ID_MOVTO_BANCARIO  = @id_movto_bancario                                   
    SET  @imp_dif_pago_fact  =  @imp_pago - @imp_facturado                                       
                                         
    SELECT @folio_max  =  MAX(ID_CONCILIA_CXC) FROM  CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO =  @id_movto_bancario                                                                               
                                        
    UPDATE CI_CONCILIA_C_X_C SET IMP_PAGO_AJUST  = IMP_PAGO_AJUST + @imp_dif_pago_fact
	                         WHERE ID_MOVTO_BANCARIO =  @id_movto_bancario AND
                                   ID_CONCILIA_CXC   =  @folio_max
                                                                       
    FETCH varias_fact_un_pago INTO @id_movto_bancario
  END

  CLOSE varias_fact_un_pago 
  DEALLOCATE varias_fact_un_pago

END


