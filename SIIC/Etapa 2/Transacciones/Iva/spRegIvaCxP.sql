USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
--EXEC spRegIvaCxP 'CU', '201804','E'
ALTER PROCEDURE [dbo].[spRegIvaCxP]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pCveTipo varchar(1)
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @id_cxp            int,
		   @f_captura         date,
		   @cve_moneda        varchar(1),
		   @imp_iva           numeric(16,2),
		   @imp_bruto         numeric(16,2),
		   @tx_nota           varchar(200),
		   @tx_nota_e         varchar(200),
		   @concepto          varchar(200),
		   @rfc               varchar(15),
		   @b_fac_cp          bit,
		   @b_fac_item        bit,
		   @id_proveedor      int,   
		   @cve_tipo_oper     varchar(2)

  DECLARE  @k_dolar           varchar(1) = 'D',
           @k_verdadero       bit          = 1,
		   @k_falso           bit          = 0,
		   @k_devengado       varchar(6)   = 'MPDEVE',
		   @k_iva             numeric(6,4) = .16

  DECLARE  @imp_ajuste        numeric(3,2)

  DECLARE  @TCxCConcil       TABLE
          (RowID             int  identity(1,1),
		   ID_CXP            int,
		   F_CAPTURA         date,
		   CVE_MONEDA        varchar(1),
		   IMP_IVA           numeric(16,2),
		   IMP_BRUTO         numeric(16,2),
		   RFC               varchar(15),
		   ID_PROVEEDOR      int,
		   TX_NOTA           varchar(200),
		   TX_NOTA_E         varchar(200),
		   B_FAC_CP          bit,
		   B_FAC_ITEM        bit)


  DELETE FROM CI_PERIODO_IVA WHERE ANO_MES  =  @pAnoMes  AND  CVE_TIPO =  @pCveTipo

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT  @TCxCConcil (ID_CXP, F_CAPTURA, CVE_MONEDA, IMP_IVA, IMP_BRUTO, TX_NOTA, TX_NOTA_E, RFC, ID_PROVEEDOR, B_FAC_CP, B_FAC_ITEM) 
  SELECT  cp.ID_CXP, cp.F_CAPTURA, cp.CVE_MONEDA, i.IVA, i.IMP_BRUTO, i.TX_NOTA, cp.TX_NOTA, i.RFC, cp.ID_PROVEEDOR, 
          cp.B_FACTURA, i.B_FACTURA
  FROM  CI_CONCILIA_C_X_P ccp, CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P i
  WHERE   ccp.ID_CONCILIA_CXP  =  cp.ID_CONCILIA_CXP  AND
          cp.CVE_EMPRESA       =  i.CVE_EMPRESA       AND
		  cp.ID_CXP            =  i.ID_CXP            AND
          ccp.ANOMES_PROCESO   =  @pAnoMes            AND
		  cp.CVE_CHEQUERA      <> @k_devengado  
  UNION
  SELECT  cp.ID_CXP, cp.F_CAPTURA, cp.CVE_MONEDA, i.IVA, i.IMP_BRUTO, i.TX_NOTA, cp.TX_NOTA, i.RFC, cp.ID_PROVEEDOR, cp.B_FACTURA, i.B_FACTURA
  FROM    CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P i
  WHERE   cp.CVE_EMPRESA       =  i.CVE_EMPRESA       AND
		  cp.ID_CXP            =  i.ID_CXP            AND
		  cp.CVE_CHEQUERA      =  @k_devengado        AND
		  dbo.fnArmaAnoMes (YEAR(cp.F_CAPTURA), MONTH(cp.F_CAPTURA))  = @pAnoMes 

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_cxp = ID_CXP, @f_captura = F_CAPTURA,  @cve_moneda = CVE_MONEDA, @imp_iva = IMP_IVA, @imp_bruto = IMP_BRUTO,
	       @tx_nota = TX_NOTA,
	       @tx_nota_e = TX_NOTA_E,  @rfc = RFC, @id_proveedor  =  ID_PROVEEDOR, @b_fac_cp = B_FAC_CP, @b_fac_item = B_FAC_CP
	FROM @TCxCConcil  WHERE  RowID = @RowCount

	IF  @cve_moneda  =  @k_dolar
	BEGIN
      SET  @imp_iva = @imp_iva * dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @f_captura)
	END

	SET  @concepto =  ISNULL('CXP ' + CONVERT(VARCHAR(10),@id_cxp) + ' ==> ' + @tx_nota,' ')

    SET  @cve_tipo_oper  =  ISNULL((SELECT CVE_TIPO_OPERACION FROM CI_PROVEEDOR WHERE ID_PROVEEDOR  =  @id_proveedor), ' ')

	IF  @b_fac_cp  =  @k_verdadero
	BEGIN
      SET  @rfc  =  ISNULL((SELECT RFC FROM CI_PROVEEDOR WHERE ID_PROVEEDOR  =  @id_proveedor), ' ')
	  SET  @concepto = ISNULL('CXPS ' + CONVERT(VARCHAR(10),@id_cxp) + ' ==> ' + @tx_nota_e,' ')    
 	END
	ELSE
	BEGIN
	  IF  @b_fac_item  =  @k_falso
	  BEGIN
	    SET @rfc = ' ' 
	  END
	END


	SET  @imp_bruto  =  @imp_iva / @k_iva

    INSERT  CI_PERIODO_IVA  (CVE_EMPRESA, ANO_MES, CVE_TIPO, IMP_IVA, IMP_BRUTO, CONCEPTO, RFC, ID_PROVEEDOR, CVE_TIPO_OPERACION,
	                         B_ACREDITADO, ANO_MES_ACRED, ID_MOVTO_BANCARIO) VALUES
	                        (@pCveEmpresa, @pAnoMes, @pCveTipo, @imp_iva, @imp_bruto, @concepto, @rfc, 
							 @id_proveedor, @cve_tipo_oper, @k_verdadero, @pAnoMes,0)

    SET @RowCount =   @RowCount + 1
  END

END


