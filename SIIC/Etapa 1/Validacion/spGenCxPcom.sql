USE  ADMON01 
GO
/****** Crea regisro de Cuentas por pagar por IVA Bancario ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spGenCxPcom')
BEGIN
  DROP  PROCEDURE spGenCxPcom
END
GO
--exec spGenCxPcom  'CU', 'MLOPEZ', '201903', 1,144,' ', ' '
CREATE PROCEDURE  dbo.spGenCxPcom 
(
 @pCveEmpresa    varchar(4),
 @pCodigoUsuario varchar(8),
 @pAnoMes        varchar(6),
 @pIdProceso     numeric(9),
 @pIdTarea       numeric(9),
 @pError         varchar(80) OUT,
 @pMsgError      varchar(400) OUT )

AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @cve_chequera      varchar(6),
           @imp_comision      numeric(16,2),
		   @imp_iva           numeric(16,2),
		   @tipo_cambio       numeric(16,2),
		   @num_folio         int,
   		   @num_folio_c       int,
		   @f_operacion       date,
		   @rfc               varchar(15)

  DECLARE  @k_comision        varchar(2) = 'CO',
           @k_iva             varchar(2) = 'IV',
		   @k_activo          varchar(1) = 'A',
		   @k_error           varchar(1) = 'E',
		   @k_fol_cxp         varchar(4) = 'FCOM',
		   @k_fol_conc        varchar(4) = 'CCOM',
		   @k_tipo_movto      varchar(6) = 'CXP',
		   @k_dia_uno         varchar(2) = '01',
		   @k_pesos           varchar(1) = 'P',
		   @k_dolar           varchar(1) = 'D',
		   @k_activa          varchar(2) = 'A',
		   @k_no_procesada    varchar(2) = 'NP',
		   @k_pago_total      varchar(1) = 'T',
		   @k_com_bancaria    varchar(2) = '07',
		   @k_verdadero       bit        = 1,
		   @k_falso           bit        = 0

  DECLARE  @TCheqComis       TABLE
		  (RowID             int  identity(1,1),
		   CVE_CHEQUERA      varchar(6),
		   IMP_COMISION      numeric(16,2),
		   IMP_IVA           numeric(16,2))

  DECLARE  @TCheqIva         TABLE
		  (CVE_CHEQUERA      varchar(6),
		   IMP_IVA           numeric(16,2))

  BEGIN TRY

  DELETE  CI_ITEM_C_X_P   WHERE CVE_EMPRESA + CONVERT(VARCHAR(10),ID_CXP) IN
  (SELECT  CVE_EMPRESA + CONVERT(VARCHAR(10),ID_CXP) FROM  CI_CUENTA_X_PAGAR  WHERE TX_NOTA = 'COMISIONES E IVA BANCARIOS*'  AND
   dbo.fnArmaAnoMes (YEAR(F_CAPTURA), MONTH(F_CAPTURA))  = @pAnoMes)

  DELETE FROM  CI_CUENTA_X_PAGAR  WHERE TX_NOTA = 'COMISIONES E IVA BANCARIOS*'  AND
   dbo.fnArmaAnoMes (YEAR(F_CAPTURA), MONTH(F_CAPTURA))  = @pAnoMes

  INSERT @TCheqComis 
  SELECT ch.CVE_CHEQUERA, SUM(IMP_TRANSACCION), 0 
  FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch 
  WHERE m.ANO_MES             = @pAnoMes          AND
        m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO  AND
        m.CVE_CHEQUERA        = ch.CVE_CHEQUERA   AND
		m.SIT_MOVTO           = @k_activo         AND
        t.CVE_TIPO_CONT      IN (@k_comision)     GROUP BY ch.CVE_CHEQUERA
		HAVING SUM(IMP_TRANSACCION) <> 0

  INSERT @TCheqIva
  SELECT ch.CVE_CHEQUERA, SUM(IMP_TRANSACCION) 
  FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch 
  WHERE m.ANO_MES             = @pAnoMes          AND
        m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO  AND
        m.CVE_CHEQUERA        = ch.CVE_CHEQUERA   AND
		m.SIT_MOVTO           = @k_activo         AND
        t.CVE_TIPO_CONT      IN (@k_iva)     GROUP BY ch.CVE_CHEQUERA
		HAVING SUM(IMP_TRANSACCION) <> 0

  MERGE @TCheqComis AS TARGET
  USING (
	     SELECT CVE_CHEQUERA, IMP_IVA FROM  @TCheqIva
	    )  AS SOURCE 
          ON TARGET.CVE_CHEQUERA    = SOURCE.CVE_CHEQUERA  

  WHEN MATCHED THEN
       UPDATE 
          SET TARGET.IMP_IVA  = SOURCE.IMP_IVA;

  SET @NunRegistros =  (SELECT COUNT(*) FROM  @TCheqComis)

  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_chequera  =  CVE_CHEQUERA,
           @imp_comision  =  IMP_COMISION,
		   @imp_iva       =  IMP_IVA
	FROM   @TCheqComis  WHERE  RowID = @RowCount

  UPDATE  CI_FOLIO SET  NUM_FOLIO =  NUM_FOLIO + 1 WHERE CVE_FOLIO = @k_fol_cxp
  SELECT  @num_folio = NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_cxp

  UPDATE  CI_FOLIO SET  NUM_FOLIO =  NUM_FOLIO + 1 WHERE CVE_FOLIO = @k_fol_conc
  SELECT  @num_folio_c = NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_conc

  SET @f_operacion  =  SUBSTRING(@pAnoMes,1,4) + '-' + SUBSTRING(@pAnoMes,5,6) + '-' + @k_dia_uno 

  IF  (SELECT CVE_MONEDA FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera)  =  @k_dolar
  BEGIN
    SET  @tipo_cambio  =  dbo.fnObtTipoCamb(@f_operacion)
  END
  ELSE
  BEGIN
    SET  @tipo_cambio = 0 
  END
 
  INSERT INTO CI_CUENTA_X_PAGAR
         (CVE_EMPRESA, 
          ID_CXP,
          ID_PROVEEDOR, 
          CVE_CHEQUERA, 
          CVE_TIPO_MOVTO, 
          F_CAPTURA, 
          F_PAGO, 
          IMP_BRUTO, 
          IMP_IVA, 
          IMP_RET_IVA, 
          IMP_RET_ISR, 
          IMP_NETO, 
          IMP_RESCATE, 
          CVE_MONEDA, 
          TIPO_CAMBIO, 
          CVE_FORMA_PAGO, 
          NUM_CHEQUE, 
          NUM_DOCTO_REF, 
          REFER_PAGO, 
          TX_NOTA, 
          NUM_DOCTOS_ASOC, 
          NOMBRE_DOCTO_PDF, 
          NOMBRE_DOCTO_XML, 
          FIRMA, 
          B_SOLIC_TRANSF, 
          ID_CONCILIA_CXP, 
          SIT_CONCILIA_CXP, 
          SIT_C_X_P, 
          F_CANCELACION, 
          B_EMP_SERVICIO, 
          B_FACTURA, 
          CVE_MOT_CONCIL)
     VALUES
         (@pCveEmpresa,
          @num_folio, 
         (SELECT ID_PROVEEDOR FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera),
          @cve_chequera,
          @k_tipo_movto,
          @f_operacion,
          NULL,
          @imp_comision,
          @imp_iva,
          0,
          0,
          @imp_comision + @imp_iva,
          0,
         (SELECT CVE_MONEDA FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera),
          @tipo_cambio,
          @k_pago_total,
          NULL,
          NULL,
          NULL,
          'COMISIONES E IVA BANCARIOS*', -- NO CAMBIAR LEYENDA, AFECTA AL FUNCIONAMIENTO DEL PROGRAMA
          NULL,
		  NULL,
		  NULL,
		  NULL,
		  @k_falso,
          @num_folio_c,
          @k_no_procesada,
          @k_activa,
          NULL,
          @k_falso,
          @k_falso,
          NULL)

    SET  @rfc = (SELECT RFC FROM CI_PROVEEDOR WHERE  ID_PROVEEDOR  =
		        (SELECT ID_PROVEEDOR FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera))

    INSERT INTO CI_ITEM_C_X_P
        (CVE_EMPRESA,
         ID_CXP,
         ID_CXP_DET,
         CVE_OPERACION,
         IMP_BRUTO,
         TX_NOTA,
         IVA,
         RFC,
         B_FACTURA)
     VALUES
        (@pCveEmpresa,
         @num_folio,
         1,
         @k_com_bancaria,
         @imp_comision,
         'COMISIONES E IVA BANCARIOS',
         @imp_iva,
         @rfc,
         @k_verdadero)

    SET @RowCount     = @RowCount + 1
  END

  END TRY

  BEGIN CATCH	
    SET  @pError    =  'Error ' + '(P) ' + ERROR_PROCEDURE() 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    SELECT   @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

