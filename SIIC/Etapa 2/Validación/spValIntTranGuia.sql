USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
                             
--EXEC spValIntTranGuia 'CU', 'MLOPEZ', '201901', 1,2, ' ', ' '

ALTER PROCEDURE [dbo].[spValIntTranGuia]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT
AS
BEGIN
  
  DECLARE  @NunRegistros   int, 
           @RowCount       int,
           @NunRegTran     int, 
           @RowCount_t     int,
           @NunRegCon      int, 
           @RowCount_c     int,
		   @num_reg_proc   int = 0

  DECLARE  @TClavesGuia    TABLE
          (RowID           int  identity(1,1),
		   OPERACION       varchar(10))

  DECLARE  @TTransaccion   TABLE
          (RowID           int  identity(1,1),
		   ID_TRANSACCION  int,
		   CVE_OPER_CONT   varchar(6))

  DECLARE  @TOperacion     TABLE
          (RowID           int  identity(1,1),
		   ID_TRANSACCION  int,
		   CVE_CONC_TRANS  varchar(6),
		   VALOR_CONCEPTO  VARCHAR(200)) 

  DECLARE  @TConcTran      TABLE
          (RowID           int  identity(1,1),
		   ID_TRANSACCION  numeric(9,0),
		   CVE_CONC_TRANS  varchar(4),
		   CTA_CONTABLE    varchar(30)) 

  DECLARE  @TConcTranCero  TABLE
          (RowID           int  identity(1,1),
		   ID_TRANSACCION  numeric(9,0),
		   CVE_CONC_TRANS  varchar(4),
		   NATURALEZA      VARCHAR(1),
		   IMP_CONCEPTO    numeric(16,4)) 

  DECLARE  @operacion         varchar(10),
           @cve_oper_cont     varchar(6),
		   @cve_conc_trans    varchar(4),
		   @id_transaccion    int,
		   @valor_concepto    varchar(200),
		   @cta_contable      varchar(30),
		   @naturaleza        varchar(1),
		   @ano_mes_acred     varchar(6),
		   @id_movto_bancario numeric(9,0),
		   @imp_concepto      numeric(16,4)
 
  DECLARE  @b_correcto     bit  =  0

  DECLARE  @k_verdadero    bit  =  1,
           @k_falso        bit  =  0,
		   @k_error        varchar(1)  =  'E',
		   @k_pref_cta_con varchar(2)  =  'CT',
		   @k_no_aplica    varchar(2)  =  'NA',
           @k_iva_pesos    varchar(4)  =  'IMIP',
           @k_iva_dolares  varchar(4)  =  'IMID',
		   @k_numero       varchar(1)  =  'N'


  INSERT @TClavesGuia 
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_DEPTO) FROM CI_GUIA_CONTABLE   WHERE 
  CVE_DEPTO <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_CONCEPTO) FROM CI_GUIA_CONTABLE WHERE
  CVE_CONCEPTO <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_TIPO_CAMBIO) FROM CI_GUIA_CONTABLE WHERE
  CVE_TIPO_CAMBIO <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_DEBE) FROM CI_GUIA_CONTABLE WHERE
  CVE_DEBE <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_HABER) FROM CI_GUIA_CONTABLE WHERE
  CVE_HABER <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_NUM_CUENTA) FROM CI_GUIA_CONTABLE WHERE
  CVE_NUM_CUENTA <>  @k_no_aplica
  UNION
  SELECT DISTINCT(CVE_OPER_CONT + REPLICATE (' ',(06 - LEN(CVE_OPER_CONT))) + CVE_PROYECTO) FROM CI_GUIA_CONTABLE WHERE
  CVE_PROYECTO <>  @k_no_aplica

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @operacion  =  OPERACION
    FROM   @TClavesGuia
    WHERE  RowID = @RowCount

    INSERT  @TTransaccion (ID_TRANSACCION, CVE_OPER_CONT)
    SELECT  ID_TRANSACCION, CVE_OPER_CONT  FROM  CI_TRANSACCION_CONT
            WHERE  CVE_EMPRESA    =  @pCveEmpresa   AND
	   	           ANO_MES        =  @pAnoMes       AND
		           CVE_OPER_CONT  =  SUBSTRING(@operacion,1,6)  

    SET @NunRegTran = @@ROWCOUNT

    SET @RowCount_t = ISNULL((SELECT MIN(RowID)  FROM @TTransaccion),0)
    IF  @NunRegTran  >  0
    BEGIN
      SET @NunRegTran  = @NunRegTran + @RowCount_t - 1
    END

    WHILE @RowCount_t <= @NunRegTran
    BEGIN
 
      SET  @b_correcto  =  @k_falso
      SELECT @id_transaccion  =  ID_TRANSACCION, @cve_oper_cont  =  CVE_OPER_CONT
      FROM   @TTransaccion
      WHERE  RowID = @RowCount_t      
 
      INSERT  @TOperacion (ID_TRANSACCION, CVE_CONC_TRANS, VALOR_CONCEPTO)
      SELECT  ID_TRANSACCION, CVE_CONC_TRANS, VALOR_CONCEPTO  FROM  CI_CONCEP_TRANSAC
              WHERE  CVE_EMPRESA     =  @pCveEmpresa   AND
		            ANO_MES         =  @pAnoMes       AND
			        ID_TRANSACCION  =  @id_transaccion  AND
			        CVE_OPER_CONT   =  @cve_oper_cont

      SET @NunRegCon  = @@ROWCOUNT

      SET @RowCount_c = ISNULL((SELECT MIN(RowID)  FROM @TOperacion),0) 
      IF  @NunRegCon  > 0 
	  BEGIN
	    SET @NunRegCon  = @NunRegCon + @RowCount_c - 1
      END

      WHILE @RowCount_c <= @NunRegCon
      BEGIN
        SELECT @cve_conc_trans  =  CVE_CONC_TRANS, @valor_concepto  =  VALOR_CONCEPTO
        FROM   @TOperacion
        WHERE  RowID = @RowCount_c  
 
        IF  SUBSTRING(@operacion,7,10)  =  @cve_conc_trans	     
	    BEGIN
		  SET  @b_correcto  =  @k_verdadero
	    END
   
        SET @RowCount_c = @RowCount_c + 1

      END

	  DELETE @TOperacion

      IF  @NunRegTran  <>  0
	  BEGIN
	    IF  @b_correcto  =  @k_falso	     
	    BEGIN
	      SET  @num_reg_proc  =  @num_reg_proc  +  1
		  SET  @pError    =  'No Existe Concepto ' + CONVERT(varchar(14),@id_transaccion) + ' ' +  SUBSTRING(@operacion,7,10) 
          SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
        END
  	  END
	  SET @RowCount_t = @RowCount_t + 1
    END	
 
    DELETE @TTransaccion 
    SET @RowCount = @RowCount + 1

  END                                                                                             
             
  INSERT  @TConcTran  (ID_TRANSACCION, CVE_CONC_TRANS, CTA_CONTABLE)
  SELECT ID_TRANSACCION, CVE_CONC_TRANS, SUBSTRING(VALOR_CONCEPTO,1,30) FROM CI_CONCEP_TRANSAC WHERE
         SUBSTRING(CVE_CONC_TRANS,1,2) = @k_pref_cta_con 

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
	SELECT  @id_transaccion  =  ID_TRANSACCION, @cve_conc_trans = CVE_CONC_TRANS, @cta_contable = CTA_CONTABLE
	FROM @TConcTran
    WHERE  RowID = @RowCount

    IF  NOT EXISTS(SELECT 1  FROM  CI_CAT_CTA_CONT  WHERE  
   	               CVE_EMPRESA  =  @pCveEmpresa   AND
	               CTA_CONTABLE =   @cta_contable)
    BEGIN
      SET  @num_reg_proc  =  @num_reg_proc  +  1
	  SET  @pError    =  'No Existe Cuenta TRAN ' + @cta_contable + ' ' +  @cve_conc_trans
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError

	END
    SET @RowCount     = @RowCount + 1

  END 
                      
  INSERT  @TConcTranCero  (ID_TRANSACCION, CVE_CONC_TRANS, NATURALEZA, IMP_CONCEPTO)
  SELECT co.ID_TRANSACCION, co.CVE_CONC_TRANS, ct.CVE_NATURALEZA, IMP_CONCEPTO FROM CI_CONC_TRANSACCION ct, CI_CONCEP_TRANSAC co  WHERE
         ct.CVE_EMPRESA     =  @pCveEmpresa        AND
         ct.CVE_EMPRESA     =  co.CVE_EMPRESA      AND
		 ct.CVE_CONC_TRANS  =  co.CVE_CONC_TRANS   AND
		 co.ANO_MES         =  @pAnoMes            

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
	SELECT  @id_transaccion  =  ID_TRANSACCION, @cve_conc_trans = CVE_CONC_TRANS, @naturaleza = NATURALEZA,
	        @imp_concepto    =  IMP_CONCEPTO
	FROM @TConcTranCero
    WHERE  RowID = @RowCount
 
    IF  @naturaleza    =  @k_numero  AND  @cve_conc_trans NOT IN (@k_iva_pesos, @k_iva_dolares)  AND
	    @imp_concepto  =  0
	BEGIN
	  SET  @num_reg_proc  =  @num_reg_proc  +  1
	  SET  @pError    =  'Concepto en ceros ' + convert(varchar(16), @id_transaccion) + ' ' +  @cve_conc_trans 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END
    SET @RowCount    =  @RowCount + 1
  END  

  DECLARE  @TRegNoAcred       TABLE
          (RowID              int  identity(1,1),
		   ANO_MES_ACRED     VARCHAR(6),
		   ID_MOVTO_BANCARIO  numeric(9,0)) 

  INSERT  @TRegNoAcred  (ANO_MES_ACRED, ID_MOVTO_BANCARIO)
  SELECT ANO_MES_ACRED, ID_MOVTO_BANCARIO FROM CI_PERIODO_IVA WHERE
         B_ACREDITADO = @k_falso 

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
	SELECT @ano_mes_acred     =  ISNULL(ANO_MES_ACRED,' '),
	       @id_movto_bancario =  ISNULL(ID_MOVTO_BANCARIO,0)
	FROM @TRegNoAcred 
    WHERE  RowID = @RowCount
    SET  @num_reg_proc  =  @num_reg_proc  +  1
    SET  @pError    =  'Reg IVA no Acreditado ' + @ano_mes_acred + ' ' +
	                   CONVERT(varchar(9), @id_movto_bancario)
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError

    SET @RowCount     = @RowCount + 1

  END 

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc					                                                                           

END

