USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-- exec spAvisosInform 'CU', 'MLOPEZ', '201901', 1, 144, ' ', ' '
ALTER PROCEDURE [dbo].[spAvisosInform]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                         @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								         @pMsgError varchar(400) OUT
AS
BEGIN
--  SELECT 'entro a procedimiento'
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @id_cxc            int,
		   @id_concilia_cxc   numeric(9,0),
		   @sit_transaccion   varchar(2),
		   @cve_liq_fac       varchar(1),
		   @tot_imp_bruto     numeric(16,2),
		   @tot_imp_iva       numeric(16,2),
		   @tot_imp_neto      numeric(16,2),
		   @imp_acum_pagos    numeric(16,2),
		   @imp_p_factura     numeric(16,2),
		   @f_operacion       date,
		   @tipo_cambio       numeric(8,4),
		   @cve_operacion     varchar(4),
		   @cve_operacion_p   varchar(4)

  DECLARE  @id_movto_bancario int,
           @ano_mes           varchar(6),
		   @cve_moneda        varchar(1),
		   @cve_chequera      varchar(6),
		   @cve_tipo_movto    varchar(6),
		   @cve_cargo_abono   varchar(1),
		   @id_concilia_cxp   int,
		   @sit_movto         varchar(1),
		   @b_concilia        bit

  DECLARE  @id_cxp            int,
           @id_cxp_i          int,
		   @imp_bruto         numeric(16,2),
		   @imp_iva           numeric(16,2),
		   @imp_neto          numeric(16,2),
		   @sit_concilia_cxp  varchar(2),
		   @rfc               varchar(15),
		   @b_op_preferente   bit,
		   @b_emp_servicio    bit,
		   @id_proveedor      int,
		   @ano               int,
		   @mes               int,
		   @ano_mes_ant       varchar(6),
		   @num_reg_proc      int = 0,
		   @id_recibo         int,
           @mes_calc          int = 0,
           @f_revision date

-- 0 - Una Factura que no tiene pagos relacionados
-- 1 - Una Factura que tiene un solo movimiento de pago relacionado
-- 2 - Una Factura relaciona da a varios pagos
-- 3 - Varias Facturas relacionadas a un solo pago
-- 4 - Varias Facturas relacionadas a varios Pagos 

  DECLARE  @k_activa        varchar(1)  = 'A',
           @k_legada        varchar(6)  = 'LEGACY',
		   @k_cxc           varchar(4)  = 'CXC',
		   @k_cpa_b_dif     varchar(6)  = 'CMD',
  		   @k_vta_b_dif     varchar(6)  = 'VMD',
		   @k_error         varchar(1)  = 'E',
		   @k_warning       varchar(1)  = 'W',
		   @k_cancelada     varchar(1)  = 'C',
		   @k_1fact_Npag    varchar(1)  = '2',
		   @k_Nfact_1pag    varchar(1)  = '3',
		   @k_Nfact_Npag    varchar(1)  = '4',
		   @k_traspaso      varchar(4)  = 'TBC',
		   @k_dolar         varchar(1)  = 'D',
		   @k_no_conciliado varchar(1)  = 'N',
		   @k_conciliado    varchar(1)  = 'C',
		   @k_abono         varchar(1)  = 'A',
		   @k_cargo         varchar(1)  = 'C',
		   @k_verdadero     bit         =  1,
		   @k_enero         int         =  1,
		   @k_diciembre     int         =  12,
		   @k_revisado      varchar(1)  =  '*',
		   @k_cero_uno      int         =  1,
		   @k_primero       int         =  1,
		   @k_factura       int         =  30,
		   @k_cxp           int         =  20

  SET  @ano  =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @mes  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2))

  IF  @mes  <>  @k_enero
  BEGIN
    SET  @mes  =  @mes - 1
  END
  ELSE
  BEGIN
    SET  @ano  =  @ano  -  1
	SET  @mes  =  @k_diciembre
  END

  SET  @ano_mes_ant  =  dbo.fnArmaAnoMes (@ano, @mes)


-------------------------------------------------------------------------------
-- Verificación de Tipos de Conciliación
-------------------------------------------------------------------------------

  DECLARE  @TFacturas       TABLE
          (RowID            int  identity(1,1),
		   ID_CONCILIA_CXC  numeric(9,0))
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TFacturas  (ID_CONCILIA_CXC)  
  SELECT cc.ID_CONCILIA_CXC  FROM CI_FACTURA f, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
  WHERE   f.CVE_EMPRESA      =  @pCveEmpresa         AND
          f.SERIE            <> @k_legada            AND
          f.SIT_TRANSACCION  =  @k_activa            AND
		  f.ID_CONCILIA_CXC  =  cc.ID_CONCILIA_CXC   AND
		  cc.ANOMES_PROCESO  =  @pAnoMes             AND
		  cc.ID_MOVTO_BANCARIO = m.ID_MOVTO_BANCARIO AND
		  m.CVE_TIPO_MOVTO     = @k_cxc
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_concilia_cxc = ID_CONCILIA_CXC FROM @TFacturas
	WHERE  RowID  =  @RowCount
	EXEC spDetCasoFacturaCom @id_concilia_cxc, @cve_liq_fac OUT   
	IF  @cve_liq_fac  =  @k_1fact_Npag  
	BEGIN
      SET @num_reg_proc = @num_reg_proc + 1  
      SET  @pError    =  'Id. Conc. CXC ' + CONVERT(VARCHAR(10), @id_concilia_cxc) + ' en relacion 1 Fact N Pag'  
 	  SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END
 	ELSE
	BEGIN
	  IF  @cve_liq_fac  =  @k_Nfact_1pag
	  BEGIN
--     SELECT '2'
	    SET @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'Id. Conc. CXC ' + CONVERT(VARCHAR(10), @id_concilia_cxc) + ' en relacion 1 Pag N Fact'  
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning,@pError, @pMsgError
	  END
	  ELSE
	  BEGIN
	    IF  @cve_liq_fac  =  @k_Nfact_Npag
	    BEGIN
--	      SELECT '3'
		  SET @num_reg_proc = @num_reg_proc + 1  
		  SET  @pError    =  'Id. Conc. CXC ' + CONVERT(VARCHAR(10), @id_concilia_cxc) + ' en relacion N Pag N Fact'  
          SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	    END
      END
    END
--    SELECT CONVERT(VARCHAR(10), @id_concilia_cxc) + ' ' + @cve_liq_fac
    SET  @RowCount = @RowCount + 1
  END

-------------------------------------------------------------------------------
-- Verificación de Facturas 
-------------------------------------------------------------------------------
  DECLARE  @TCtasxCobrar    TABLE
          (RowID            int  identity(1,1),
		   ID_CXC           int,
		   IMP_BRUTO        numeric(16,2),
		   IMP_IVA          numeric(16,2),
		   IMP_NETO         numeric(16,2),
		   CVE_MONEDA       varchar(1),
		   CVE_CHEQUERA     varchar(6),
		   ID_CONCILIA_CXC  int,
		   SIT_TRANSACCION  varchar(2),
		   TIPO_CAMBIO      numeric(8,4),
		   F_OPERACION      date)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT  @TCtasxCobrar(ID_CXC, IMP_BRUTO, IMP_IVA, IMP_NETO, CVE_MONEDA, CVE_CHEQUERA, ID_CONCILIA_CXC, SIT_TRANSACCION,
                        TIPO_CAMBIO, F_OPERACION) 
  SELECT  ID_CXC, IMP_F_BRUTO, IMP_F_IVA, IMP_F_NETO, CVE_F_MONEDA, CVE_CHEQUERA, ID_CONCILIA_CXC, SIT_TRANSACCION,
          dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, F_OPERACION), F_OPERACION
  FROM  CI_FACTURA WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
                  dbo.fnArmaAnoMes (YEAR(F_OPERACION), MONTH(F_OPERACION))  =  @pAnoMes
  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------

  SET @RowCount     = 1
				  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_cxc = ID_CXC, @imp_bruto = IMP_BRUTO, @imp_iva = IMP_IVA, @imp_neto = IMP_NETO, @cve_moneda = CVE_MONEDA, 
	       @cve_chequera = CVE_CHEQUERA, @id_concilia_cxc = ID_CONCILIA_CXC, @sit_transaccion = SIT_TRANSACCION,
		   @tipo_cambio = TIPO_CAMBIO, @f_operacion = F_OPERACION
	FROM   @TCtasxCobrar  WHERE  RowID = @RowCount

    IF  @tipo_cambio <>  dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_operacion) AND @cve_moneda = @k_dolar
	BEGIN
      SET  @num_reg_proc = @num_reg_proc + 1  
      SET  @pError    =  'La CXC ' + CONVERT(VARCHAR(10),@id_cxc) + ' con tipo cambio dif. al del día'   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END
    
	IF  SUBSTRING(@sit_concilia_cxp,1,1)  =  @k_conciliado
	BEGIN
      IF  NOT EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_C ccp WHERE
	                               ccp.ID_CONCILIA_CXC  =  @id_concilia_cxc)
      BEGIN
--	    SELECT '4'
        SET  @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'La CXC ' + CONVERT(VARCHAR(10),@id_concilia_cxc) + ' con sit. conciliada no esta conciliada'   
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	  END                             
    END

	IF  SUBSTRING(@sit_transaccion,1,1)  =  @k_no_conciliado
	BEGIN
--      SELECT '5'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'La CXC ' + CONVERT(VARCHAR(10),@id_concilia_cxc) + ' no está conciliada'   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError

      IF  EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_C ccp WHERE
	                               ccp.ID_CONCILIA_CXC  =  @id_concilia_cxc)
      BEGIN
--	    SELECT '6'
		SET @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'La CXC ' + CONVERT(VARCHAR(10),@id_concilia_cxc) + 'con sit. no conciliada y esta conciliada'   
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	  END                             
    END

    SELECT  @tot_imp_bruto = SUM(IMP_BRUTO_ITEM)
	FROM CI_ITEM_C_X_C WHERE CVE_EMPRESA = @pCveEmpresa  AND  @id_cxc = ID_CXC

	SET  @tot_imp_bruto  =  ISNULL(@tot_imp_bruto,0)

	IF  @imp_bruto <> @tot_imp_bruto 
	BEGIN
--      SELECT '7'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'La CXC ' + CONVERT(VARCHAR(10),@id_concilia_cxc) + 'NO coincide en importes con sus ITEMS'   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

	IF  NOT EXISTS(SELECT 1 FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_operacion)  
	BEGIN
--      SELECT '7.1'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'NO existe T.C. CXC' + convert(varchar(12), @f_operacion, 121)    
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END


    SET @RowCount     =   @RowCount + 1
  END  			


-------------------------------------------------------------------------------
-- Verificación de Cuentas por Pagar 
-------------------------------------------------------------------------------

  DECLARE  @TCtasxPagar     TABLE
          (RowID            int  identity(1,1),
		   ID_CXP           int,
		   F_CAPTURA        date,
		   IMP_BRUTO        numeric(16,2),
		   IMP_IVA          numeric(16,2),
		   IMP_NETO         numeric(16,2),
		   CVE_MONEDA       varchar(1),
		   CVE_CHEQUERA     varchar(6),
		   ID_CONCILIA_CXP  int,
		   SIT_CONCILIA_CXP varchar(2),
		   B_CONCILIA       bit)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT  @TCtasxPagar(ID_CXP, F_CAPTURA, IMP_BRUTO, IMP_IVA, IMP_NETO, CVE_MONEDA, CVE_CHEQUERA, ID_CONCILIA_CXP, SIT_CONCILIA_CXP) 
  SELECT  ID_CXP, F_CAPTURA, IMP_BRUTO, IMP_IVA, IMP_NETO, CVE_MONEDA, CVE_CHEQUERA, ID_CONCILIA_CXP, SIT_CONCILIA_CXP
  FROM CI_CUENTA_X_PAGAR WHERE CVE_EMPRESA  =  @pCveEmpresa  AND SIT_C_X_P = @k_activa AND
                  dbo.fnArmaAnoMes (YEAR(F_CAPTURA), MONTH(F_CAPTURA))  =  @pAnoMes
  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------

  SET @RowCount     = 1
				  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_cxp = ID_CXP, @f_operacion = F_CAPTURA, @imp_bruto = IMP_BRUTO, @imp_iva = IMP_IVA, @imp_neto = IMP_NETO, @cve_moneda = CVE_MONEDA, 
	       @cve_chequera = CVE_CHEQUERA, @id_concilia_cxp = ID_CONCILIA_CXP, @sit_concilia_cxp = SIT_CONCILIA_CXP
	FROM   @TCtasxPagar  WHERE  RowID = @RowCount
    
	IF  SUBSTRING(@sit_concilia_cxp,1,1)  =  @k_conciliado
	BEGIN
      IF  NOT EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_P ccp WHERE
	                               ccp.ID_CONCILIA_CXP  =  @id_concilia_cxp)
      BEGIN
--	    SELECT '8'
		SET @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'La CXP ' + CONVERT(VARCHAR(10),@id_concilia_cxp) + ' con sit. conciliada no esta conciliada'   
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	  END                             
    END

	IF  SUBSTRING(@sit_concilia_cxp,1,1)  =  @k_no_conciliado AND
	   (SELECT B_CONCILIA FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera) = @k_verdadero 
	BEGIN
--      SELECT '9'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'La CXP ' + CONVERT(VARCHAR(10),@id_concilia_cxp) + ' no está conciliada'   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError

      IF  EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_P ccp WHERE
	                               ccp.ID_CONCILIA_CXP  =  @id_concilia_cxp)
      BEGIN
--        SELECT '10'
	    SET @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'La CXP ' + CONVERT(VARCHAR(10),@id_concilia_cxp) + 'con sit. no conciliada y esta conciliada'   
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	  END                             
    END

    SELECT  @tot_imp_bruto = SUM(IMP_BRUTO), @tot_imp_iva =  SUM(IVA), @tot_imp_neto = SUM(IMP_BRUTO + IVA) 
	FROM CI_ITEM_C_X_P WHERE CVE_EMPRESA = @pCveEmpresa  AND  @id_cxp = ID_CXP

	SET  @tot_imp_bruto  =  ISNULL(@tot_imp_bruto,0)
	SET  @tot_imp_iva    =  ISNULL(@tot_imp_iva,0)
	SET  @tot_imp_bruto  =  ISNULL(@tot_imp_bruto,0)

	IF  @imp_bruto <> @tot_imp_bruto  OR  @imp_iva <> @tot_imp_iva OR @imp_neto <> @imp_neto
	BEGIN
--      SELECT '11'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'La CXP ' + CONVERT(VARCHAR(10),@id_concilia_cxp) + ' NO coincide en importes con sus ITEMS o faltan ITEMS'   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

    SET @RowCount     =   @RowCount + 1
  END  				                

  IF  (@imp_bruto + @imp_iva) <> @imp_neto 
  BEGIN
--    SELECT '11'
    SET @num_reg_proc = @num_reg_proc + 1  
	SET  @pError    =  'La CXP ' + CONVERT(VARCHAR(10),@id_concilia_cxp) + ' NO cuadra importe neto'   
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

  IF  NOT EXISTS(SELECT 1 FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_operacion)  
  BEGIN
--     SELECT '11.1'
	SET @num_reg_proc = @num_reg_proc + 1  
	SET  @pError    =  'NO existe T.C. CXP ' + convert(varchar(12), @f_operacion, 121)    
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

-------------------------------------------------------------------------------
-- Verificación de Movimientos Bancarios
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TMovBancario     TABLE
          (RowID             int  identity(1,1),
		   ID_MOVTO_BANCARIO int,
		   ANO_MES           varchar(6),
		   F_OPERACION       date,
		   CVE_CHEQUERA      varchar(6),
		   CVE_MONEDA        varchar(1),
		   CVE_TIPO_MOVTO    varchar(6),
		   CVE_CARGO_ABONO   varchar(1),
		   SIT_MOVTO         varchar(1),
		   B_CONCILIA        bit)

  INSERT  @TMovBancario(ID_MOVTO_BANCARIO, ANO_MES, F_OPERACION, CVE_CHEQUERA, CVE_TIPO_MOVTO,
                        CVE_CARGO_ABONO, SIT_MOVTO, B_CONCILIA) 
  SELECT  m.ID_MOVTO_BANCARIO, m.ANO_MES, m.F_OPERACION, ch.CVE_CHEQUERA, m.CVE_TIPO_MOVTO,
          m.CVE_CARGO_ABONO, SUBSTRING(m.SIT_CONCILIA_BANCO,1,1),
          t.B_CONCILIA
          FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_TIPO_MOVIMIENTO t WHERE
                       m.ANO_MES             =  @pAnoMes             AND
					   m.CVE_CHEQUERA        = ch.CVE_CHEQUERA       AND
					   m.CVE_TIPO_MOVto      = t.CVE_TIPO_MOVTO      AND
					   m.SIT_MOVTO           = @k_activa  
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_movto_bancario = ID_MOVTO_BANCARIO, @ano_mes = ANO_MES, @f_operacion = F_OPERACION,
	       @cve_moneda = CVE_MONEDA, @cve_chequera = CVE_CHEQUERA,
	       @cve_tipo_movto = CVE_TIPO_MOVTO, @cve_cargo_abono = CVE_CARGO_ABONO,  @sit_movto = SIT_MOVTO, @b_concilia = B_CONCILIA
	FROM @TMovBancario  WHERE  RowID = @RowCount

	IF  YEAR(@f_operacion)    <>  CONVERT(INT,SUBSTRING(@ano_mes,1,4))  OR
	    MONTH(@f_operacion)   <>  CONVERT(INT,SUBSTRING(@ano_mes,5,6))                   
    BEGIN
      SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El Mov ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' no coincide fecha con ano-mes'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

    IF  @cve_moneda  =  @k_dolar  AND  @cve_tipo_movto  =  @k_traspaso 
	BEGIN
	  IF  NOT EXISTS(SELECT 1 FROM CI_TRASP_BANCARIO WHERE ANO_MES           =  @pAnoMes       AND
	                                                       CVE_CHEQUERA      =  @cve_chequera  AND
														   ID_MOVTO_BANCARIO =  @id_movto_bancario)
      BEGIN
--        SELECT '12'
		SET @num_reg_proc = @num_reg_proc + 1  
		SET  @pError    =  'El Mov ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' de trasp. USD no tiene reg, de TRASPASO'  
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
      END
	END

	IF  SUBSTRING(@sit_movto,1,1)  =  @k_no_conciliado  AND @b_concilia = @k_verdadero
	BEGIN
--      SELECT '13'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El Mov ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' ' + @cve_cargo_abono + ' NO conciliado y es conciliable'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

	IF  SUBSTRING(@sit_movto,1,1)  =  @k_conciliado  AND  @cve_cargo_abono  = @k_abono  AND
	    NOT EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO = @id_movto_bancario) 
	BEGIN
--      SELECT '14' + CONVERT(VARCHAR(18), @id_movto_bancario)
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El Mov (A) ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' esta conc. y no existe en conciliaciones'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

	IF  SUBSTRING(@sit_movto,1,1)  =  @k_conciliado  AND  @cve_cargo_abono  = @k_cargo AND
	    NOT EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_P  WHERE ID_MOVTO_BANCARIO = @id_movto_bancario) AND
		NOT EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO = @id_movto_bancario) 
	BEGIN
--      SELECT '15' + + CONVERT(VARCHAR(18), @id_movto_bancario)
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El Mov (C) ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' esta conc. y no existe en conciliaciones'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

	IF  @cve_tipo_movto  IN  (@k_cpa_b_dif,@k_vta_b_dif)
	BEGIN
--      SELECT '15-1' + + CONVERT(VARCHAR(18), @id_movto_bancario)
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET @pError    =  'El Mov (C) ' + CONVERT(VARCHAR(10), @id_movto_bancario) + ' es trasp. en moneda diferente'
      SET @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END

    IF  NOT EXISTS(SELECT 1 FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_operacion)  
    BEGIN
--     SELECT '15.2'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'NO existe T.C. M. Banc ' + convert(varchar(12), @f_operacion, 121)    
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END


    SET @RowCount     =   @RowCount + 1

  END  				                

-------------------------------------------------------------------------------
-- Verificación de Periodos Contables
-------------------------------------------------------------------------------  

  IF  NOT EXISTS(SELECT 1 FROM CI_PERIODO_ISR  WHERE ANO_MES = @pAnoMes)   
  BEGIN
--      SELECT '16'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Periodo de ISR para ' + @pAnoMes + ' no existe'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

  IF  NOT EXISTS(SELECT 1 FROM CI_PERIODO_CONTA  WHERE ANO_MES = @pAnoMes)   
  BEGIN
--      SELECT '17'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Periodo Contable para ' + @pAnoMes + ' no existe'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

-------------------------------------------------------------------------------
-- Verificación de Movimientos Bancarios
-------------------------------------------------------------------------------
  --DECLARE  @TFactConcil     TABLE
  --        (RowID             int  identity(1,1),
		--   ID_CONCILIA_CXC   int,
		--   F_OPERACION       date,
		--   CVE_MONEDA        varchar(1),
		--   IMP_NETO          numeric(16,2))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  --INSERT  @TFactConcil (ID_CONCILIA_CXC,  F_OPERACION, IMP_NETO, CVE_MONEDA) 
  --SELECT  f.ID_CONCILIA_CXC, f.F_OPERACION,  f.CVE_F_MONEDA FROM  CI_CONCILIA_C_X_C cc, CI_FACTURA f 
  --WHERE   cc.ID_CONCILIA_CXC  =  f.ID_CONCILIA_CXC  AND
  --        cc.ANOMES_PROCESO  =  @pAnoMes  
  --SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

 -- SET @RowCount     = 1

 -- EXEC spProrrateaPago @pAnoMes

 -- WHILE @RowCount <= @NunRegistros
 -- BEGIN
 --   SELECT @id_concilia_cxc = ID_CONCILIA_CXC, @f_operacion = F_OPERACION, @imp_neto = IMP_NETO, @cve_moneda = CVE_MONEDA
	--FROM @TFactConcil  WHERE  RowID = @RowCount

 --   SET  @imp_acum_pagos  =  isnull((SELECT SUM(cc.IMP_PAGO_AJUST) FROM CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m WHERE
 --                            cc.ID_CONCILIA_CXC    =  @id_concilia_cxc     AND
 --                            cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
	--	           		     m.CVE_TIPO_MOVTO      =  @k_cxc),0) 

 --   IF  @cve_moneda  =  @k_dolar
	--BEGIN
 --     SET  @imp_p_factura  =  @imp_neto * DBO.fnObtTipoCamb(@f_operacion)
 --   END
	--ELSE
	--BEGIN
	--  SET  @imp_p_factura = @imp_neto
	--END

 --   SET @RowCount =   @RowCount + 1
 -- END

-------------------------------------------------------------------------------
-- Verificación de Movimientos Items CXP
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TItemCxP         TABLE
          (RowID             int  identity(1,1),
		   ID_CXP            int,
		   ID_CXC_I          int,
		   CVE_OPERACION     varchar(4),
		   CVE_OPERACION_P   varchar(4),
		   RFC               varchar(15),
		   B_EMP_SERVICIO    bit, 
		   ID_PROVEEDOR      int,
		   IMP_IVA           numeric, 
		   B_OP_PREFERENTE   bit)

  INSERT  @TItemCxP(ID_CXP, ID_CXC_I, CVE_OPERACION, CVE_OPERACION_P, RFC, B_EMP_SERVICIO, ID_PROVEEDOR, IMP_IVA, B_OP_PREFERENTE)
  SELECT  i.ID_CXP, i.ID_CXP_DET, i.CVE_OPERACION, p.CVE_OPERACION, i.RFC, cp.B_EMP_SERVICIO, p.ID_PROVEEDOR, i.IVA, B_OP_PREFERENTE
  FROM  CI_ITEM_C_X_P i, CI_PROVEEDOR p, CI_CUENTA_X_PAGAR cp 
  WHERE   i.CVE_EMPRESA   =  @pCveEmpresa   AND
          i.CVE_EMPRESA   =  cp.CVE_EMPRESA AND
		  i.ID_CXP        =  cp.ID_CXP      AND
		  cp.ID_PROVEEDOR = p.ID_PROVEEDOR  AND
		  dbo.fnArmaAnoMes (YEAR(cp.F_CAPTURA), MONTH(cp.F_CAPTURA))  =  @pAnoMes

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_cxp = ID_CXP, @id_cxp_i = ID_CXC_I,
	       @cve_operacion = CVE_OPERACION, @cve_operacion_p = CVE_OPERACION_P,
	       @rfc = RFC, @b_emp_servicio = B_EMP_SERVICIO, @id_proveedor = ID_PROVEEDOR, @imp_iva = IMP_IVA
	FROM @TItemCxP  WHERE  RowID = @RowCount
    IF  @cve_operacion <> @cve_operacion_p AND @b_op_preferente = @k_verdadero
	BEGIN
--      SELECT '18'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Cve Id cxp ' + CONVERT(VARCHAR(10), @id_cxp) + ' ' + '/' + CONVERT(VARCHAR(10), @id_cxp_i) +
	  'Prov. ' + 
	  ISNULL(CONVERT(VARCHAR(6), @id_proveedor), ' ') + ' oper no preferente'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError

	END

	IF  @b_emp_servicio =  @k_verdadero  AND isnull(@rfc,' ') = ' ' AND  @imp_iva <> 0
	BEGIN
--      SELECT '19'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Cve. Oper Id cxp ' + CONVERT(VARCHAR(10), @id_cxp) + '/' + CONVERT(VARCHAR(10), @id_cxp_i) +
	  ' se requiere RFC'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError

	END

    SET @RowCount     = @RowCount + 1
  END

-------------------------------------------------------------------------------
-- Verificación de Proveedores
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TProveedor       TABLE
          (RowID             int  identity(1,1),
		   ID_PROVEEDOR      int,
		   RFC               varchar(15))

  INSERT  @TProveedor(ID_PROVEEDOR, RFC) 
  SELECT  p.ID_PROVEEDOR, p.RFC
  FROM    CI_PROVEEDOR p, CI_CUENTA_X_PAGAR cp
  WHERE   cp.ID_PROVEEDOR  =  p.ID_PROVEEDOR  AND
          dbo.fnArmaAnoMes (YEAR(cp.F_CAPTURA), MONTH(cp.F_CAPTURA))  =  @pAnoMes
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_proveedor = ID_PROVEEDOR, @rfc = RFC
	FROM @TProveedor  WHERE  RowID = @RowCount

	IF  ISNULL(@rfc,' ') =  ' '
	BEGIN
--      SELECT '20'
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El Proveedor ' + ISNULL(CONVERT(VARCHAR(10), @id_proveedor), ' ') + ' no tiene RFC'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

    SET @RowCount     = @RowCount + 1
  END

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TMovNoConc       TABLE
          (RowID             int  identity(1,1),
		   ID_MOVTO_BANCARIO int)

  INSERT  @TMovNoConc(ID_MOVTO_BANCARIO) 
  SELECT  ID_MOVTO_BANCARIO
  FROM    CI_CUCO_MB_NO_CONC 
  WHERE   ANO_MES  =  @ano_mes_ant
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_movto_bancario = ID_MOVTO_BANCARIO
	FROM @TMovNoConc  WHERE  RowID = @RowCount

	IF  EXISTS (SELECT 1  FROM CI_CONCILIA_C_X_C WHERE ANOMES_PROCESO = @pAnoMes AND ID_MOVTO_BANCARIO = @id_movto_bancario)
	BEGIN
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'El movto pend. conc. ' + ISNULL(CONVERT(VARCHAR(10), @id_movto_bancario), ' ') + ' fue conciliado'  
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

    SET @RowCount     = @RowCount + 1
  END

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TRecibos       TABLE
          (RowID          int  identity(1,1),
		   ANO_MES        varchar(6),
		   ID_RECIBO      int,
		   IMP_RECIBO     numeric(16,2))

  INSERT  @TRecibos(ANO_MES, ID_RECIBO, IMP_RECIBO) 
  SELECT  ANO_MES, ID_RECIBO, IMP_RECIBO
  FROM    CI_RECIBO_PAGO_CXC  WHERE
          CVE_EMPRESA            =   @pCveEmpresa  AND
		  SUBSTRING(TX_NOTA,1,1) <>  @k_revisado

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN

    SELECT @ano_mes = ANO_MES, @id_recibo = ID_RECIBO, @imp_neto = IMP_RECIBO
	FROM @TRecibos  WHERE  RowID = @RowCount
--    SELECT 'CICLO RECIBOS', CONVERT(VARCHAR(10),@id_recibo)
    IF  @imp_neto <> ISNULL(
	(SELECT SUM(m.IMP_TRANSACCION) FROM  CI_REC_PAG_BAN_CXC rp, CI_CONCILIA_C_X_C c,
	                                     CI_MOVTO_BANCARIO m
    WHERE
	rp.CVE_EMPRESA       =  @pCveEmpresa        AND
	rp.ANO_MES           =  @ano_mes            AND
	rp.ID_RECIBO         =  @id_recibo          AND
 	rp.ID_MOVTO_BANCARIO =  c.ID_MOVTO_BANCARIO AND
	c.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO),0)
	BEGIN
      SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'No cuadra importe de Recibo ' + @ano_mes + ' ' + CONVERT(VARCHAR(10),@id_recibo)   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

	IF  @ano_mes = @pAnoMes AND EXISTS
	(SELECT 1 FROM  CI_REC_PAG_BAN_CXC rp, CI_CONCILIA_C_X_C c
    WHERE
	rp.CVE_EMPRESA       =  @pCveEmpresa        AND
	rp.ANO_MES           =  @ano_mes            AND
	rp.ID_RECIBO         =  @id_recibo          AND
 	rp.ID_MOVTO_BANCARIO =  c.ID_MOVTO_BANCARIO AND
	c.ANOMES_PROCESO     <> @pAnoMes)
	BEGIN
      SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Recibo con pago de otros meses ' + @ano_mes + ' ' + CONVERT(VARCHAR(10),@id_recibo)   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

    SET @RowCount     = @RowCount + 1
  END

-----------------------------------------------------------------------------------------------------
-- Verifica si faltan registros de tipo de cambio del mes 
-----------------------------------------------------------------------------------------------------

  SET  @f_revision = SUBSTRING(@pAnoMes,1,4) + '-' + SUBSTRING(@pAnoMes,5,6) + '-' + '01' 
  SET @mes         = CONVERT(INT, SUBSTRING(@pAnoMes,5,6))
  SET @mes_calc    = CONVERT(INT, SUBSTRING(@pAnoMes,5,6))

  WHILE  @mes = @mes_calc
  BEGIN
    IF  NOT EXISTS(SELECT 1 FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_revision)
    BEGIN
      SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'No existe tipo cambio ' + CONVERT(VARCHAR(10), @f_revision, 101)   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END
    SET @f_revision =  DATEADD(DAY, 1, @f_revision)
    SET @mes_calc = MONTH(@f_revision)
  END

----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TConcilia        TABLE
          (RowID             int  identity(1,1),
		   ID_MOVTO_BANCARIO int,
		   ID_CONCILIA_CXC   int)
		   
  INSERT  @TConcilia(ID_MOVTO_BANCARIO, ID_CONCILIA_CXC) 
  SELECT  ID_MOVTO_BANCARIO, ID_CONCILIA_CXC 
  FROM    CI_CONCILIA_C_X_C 
  WHERE   ANOMES_PROCESO  =  @pAnoMes
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_movto_bancario = ID_MOVTO_BANCARIO, @id_concilia_cxc = ID_CONCILIA_CXC
	FROM @TConcilia  WHERE  RowID = @RowCount

	IF  (SELECT F_OPERACION FROM CI_MOVTO_BANCARIO WHERE ID_MOVTO_BANCARIO = @id_movto_bancario) <
        (SELECT F_OPERACION FROM CI_FACTURA WHERE ID_CONCILIA_CXC = @id_concilia_cxc)
	BEGIN
	  SET @num_reg_proc = @num_reg_proc + 1  
	  SET  @pError    =  'Fecha M. Banc < Fact  ' + ISNULL(CONVERT(VARCHAR(10), @id_movto_bancario), ' ')   
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END

    SET @RowCount     = @RowCount + 1
  END

  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc 

-- Verifica si existen registros para carga de movimientos SAT

  IF  NOT EXISTS (SELECT 1 FROM CARGADOR.dbo.FC_CARGA_COL_DATO d WHERE
                  d.ID_CLIENTE  =  @k_cero_uno    AND
				  d.CVE_EMPRESA =  @pCveEmpresa   AND
				  d.ID_FORMATO  =  @k_factura     AND
				  d.ID_BLOQUE   =  @k_primero     AND
				  SUBSTRING(d.PERIODO,1,6)     =  @pAnoMes)
  BEGIN
    SET @num_reg_proc = @num_reg_proc + 1  
	SET  @pError    =  'No existen registros SAT CXC   ' + ISNULL(@pAnoMes, ' ')   
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

  IF  NOT EXISTS (SELECT 1 FROM CARGADOR.dbo.FC_CARGA_COL_DATO d WHERE
                  d.ID_CLIENTE  =  @k_cero_uno    AND
				  d.CVE_EMPRESA =  @pCveEmpresa   AND
				  d.ID_FORMATO  =  @k_cxp         AND
				  d.ID_BLOQUE   =  @k_primero     AND
				  SUBSTRING(d.PERIODO,1,6)     =  @pAnoMes)
  BEGIN
    SET @num_reg_proc = @num_reg_proc + 1  
	SET  @pError    =  'No existen registros SAT CXP   ' + ISNULL(@pAnoMes, ' ')   
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

  IF  NOT EXISTS (SELECT 1 FROM CI_COM_FISC_CONTPAQ c WHERE
				  c.CVE_EMPRESA =  @pCveEmpresa   AND
				  ANO_MES       =  @pAnoMes)
  BEGIN
    SET @num_reg_proc = @num_reg_proc + 1  
	SET  @pError    =  'No existen de CONTPAQ a CONCILIAR  ' + ISNULL(@pAnoMes, ' ')   
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END
END


  