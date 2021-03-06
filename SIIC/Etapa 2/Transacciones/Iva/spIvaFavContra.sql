USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

-- exec spIvaFavContra 'CU', 'MARIO', '201804', 12, 361, ' ', ' '
ALTER PROCEDURE [dbo].[spIvaFavContra] @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                               @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
							   @pMsgError varchar(400) OUT

AS
BEGIN

--  DECLARE @LISTA AS VALOR_ALFA

  DECLARE
  @imp_bruto_p         numeric(16,2),
  @imp_iva_p           numeric(16,2),
  @imp_neto_p          numeric(16,2),
  @imp_comp_p          numeric(16,2),

---- Campos para importes en moneda extranjera

  @imp_bruto_d         numeric(16,2),
  @imp_iva_d           numeric(16,2),
  @imp_neto_d          numeric(16,2),

-- Campos para Cuentas Contables

  @cta_contable        varchar(30),
  @cta_contable_comp   varchar(30),
  @cta_contable_ing    varchar(30),
  @cta_contable_iva    varchar(30),

-- Campo para concepto de movimiento Y otros

  @tipo_cambio         varchar(4),
  @departamento        varchar(50),
  @proyecto            varchar(50),
  @conc_movimiento     varchar(400)

  DECLARE
  @id_transac          int,
  @gpo_transaccion     int,
  @ident_transaccion   varchar(400),
  @nom_titular         varchar(120),
  @cve_oper_cont       varchar(6),
  @tx_nota             varchar(250),
  @f_dia               date
		 
  DECLARE @k_activa          varchar(1)  =  'A',
          @k_cancelada       varchar(1)  =  'C',
          @k_legada          varchar(6)  =  'LEGACY',
          @k_peso            varchar(1)  =  'P',
          @k_dolar           varchar(1)  =  'D',
          @k_falso           bit         =  0,
          @k_verdadero       bit         =  1, 
		  @k_error           varchar(1)  =  'E',

  
-- Constantes para folios

		  @k_cta_cont        varchar(10) =  'CTAIVACOBR',
		  @k_cta_iva         varchar(10) =  'CTAIVAACPA',
   		  @k_id_transaccion  varchar(4)  =  'TRAC',
		  @k_gpo_transac     varchar(4)  =  'GPOT',

-- Claves de operación para transacciones

		   @k_trasp_iva_ac   varchar(6)  =  'TIAC',
		   @k_trasp_iva_cob  varchar(6)  =  'TICO'
 
  DECLARE  @imp_iva          numeric(16,2),
           @imp_iva_poliza   numeric(16,2)

  SELECT @imp_iva  = SUM(IMP_IVA)  FROM  CI_PERIODO_IVA
         WHERE CVE_EMPRESA  =  @pCveEmpresa  AND ANO_MES  =  @pAnoMes

 
  IF  @imp_iva   >  0
  BEGIN
    SELECT @imp_iva_poliza = SUM(ABS(IMP_IVA))  FROM  CI_PERIODO_IVA
           WHERE CVE_EMPRESA   =  @pCveEmpresa  AND
		         ANO_MES_ACRED =  @pAnoMes      AND
				 IMP_IVA       <  0             --AND
--				 B_ACREDITADO  = @k_verdadero

	SET  @cve_oper_cont   =  @k_trasp_iva_ac
  END
  ELSE
  BEGIN
    SELECT @imp_iva_poliza = SUM(ABS(IMP_IVA))  FROM  CI_PERIODO_IVA
           WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
		         ANO_MES      =  @pAnoMes      AND 
				 IMP_IVA      >  0             AND
				 B_ACREDITADO  = @k_verdadero

    SET  @cve_oper_cont  =  @k_trasp_iva_cob
  END

  
  --01 'IMBP', Importe Bruto Pesos
  SET  @imp_bruto_p  =  0
--02 'IMIP', Importe IVA Pesos
  SET  @imp_iva_p    =  @imp_iva_poliza
--03 'IMNP', Importe Neto Pesos
  SET  @imp_neto_p   =  0
--04 'IMCP', Importe Complementario Pesos
  SET @imp_comp_p    =  0
--05 'IMBD', Importe Bruto Dólares
  SET @imp_bruto_d   =  0
--06 'IMID', Importe IVA Dólares
  SET @imp_iva_d     =  0
--07 'IMND', Importe Neto Dólares
  SET @imp_neto_d    =  0
--08 'CTCO', Cuenta Contable
  SET @cta_contable  =  dbo.fnObtParAlfa(@k_cta_cont)
--09 'CTCM', Cuenta Contable Complementaria
  SET @cta_contable_comp = ' '
--10 'CTIN', Cuenta Contable Ingresos
  SET @cta_contable_ing  =  ' '
--11 'CTIV', Cuenta Contable IVA
  SET @cta_contable_iva  =   dbo.fnObtParAlfa(@k_cta_iva)
--12 'TCAM', Tipo de Cambio
  SET @tipo_cambio     = 1
--13 'DPTO', Departamento
  SET @departamento  = 0
--14 'PROY', Proyecto
  SET @proyecto  =  ' '
--15 'CPTO', Concepto
  SET @conc_movimiento  =  'Traspaso de IVA mensual' + ' ' + @pAnoMes
  
  EXEC spBorraTransac  @pCveEmpresa, @pAnoMes, @pIdProceso

  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_gpo_transac
  SET  @gpo_transaccion  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_gpo_transac)  

  INSERT FC_GEN_PROCESO_BIT (CVE_EMPRESA, ID_PROCESO, FT_PROCESO, GPO_TRANSACCION) 
  VALUES
  (@pCveEmpresa,
   @pIdProceso, 
   @pAnoMes + '00',
   @gpo_transaccion)

  SET  @f_dia  =  GETDATE()

  SET  @ident_transaccion  =  @pAnoMes
  SET  @nom_titular  =  'IVA A FAVOR'
  SET  @tx_nota  =  ' '

  --	select ' Voy a crear transaccion '
   
  SET @id_transac  =  0
  
  UPDATE CI_FOLIO SET NUM_FOLIO = NUM_FOLIO + 1 WHERE CVE_FOLIO  = @k_id_transaccion
  SET  @id_transac  =  (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO  = @k_id_transaccion)   
-- SELECT ' **** VOY A INSERTAR TRANSACCION ** '

  BEGIN TRY

  EXEC  spCreaTransaccionCont
  @pIdProceso,
  @pIdTarea,
  @id_transac,
  @pCveUsuario,
  @pCveEmpresa,
  @pAnoMes,
  @cve_oper_cont,
  @f_dia,
  @ident_transaccion,
  @nom_titular,
  @tx_nota,
  @gpo_transaccion,
  @pError OUT,
  @pMsgError OUT
-- SELECT ' **** TERMINE TRANSACCION ** '
-- SELECT ' **** VOY A CREAR CONCEPTOS ** '
  EXEC spLanzaCreaConTrans
  @pIdProceso,
  @pIdTarea,
  @pCveEmpresa,
  @pAnoMes,
  @id_transac,
  @cve_oper_cont,
  @imp_bruto_p,
  @imp_iva_p,
  @imp_neto_p,
  @imp_comp_p,
  @imp_bruto_d,
  @imp_iva_d, 
  @imp_neto_d,
  @cta_contable,    
  @cta_contable_comp,
  @cta_contable_ing,
  @cta_contable_iva,
  @tipo_cambio,
  @departamento,
  @proyecto,    
  @conc_movimiento,
  @pError OUT,
  @pMsgError OUT

  EXEC  spActRegProc  @pCveEmpresa, @pIdProceso, @pIdTarea, @gpo_transaccion

  EXEC spActPctTarea @pIdTarea, 90
  
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error de Transacción IVA (a favor)'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END