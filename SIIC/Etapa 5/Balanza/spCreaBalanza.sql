USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
--exec spCreaBalanza 'CU', 'MARIO', '201804', 12, 361, ' ', ' '

ALTER PROCEDURE [dbo].[spCreaBalanza]   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT


AS
BEGIN

  DECLARE  @TSdosCtas     TABLE
 (CVE_EMPRESA             varchar(4)           not null,
  ANO_MES                 varchar(6)           not null,
  CTA_CONTABLE            varchar(30)          not null,
  IMP_CARGO_C             numeric(16,2)        null,
  IMP_ABONO_C             numeric(16,2)        null)

  DECLARE @cta_contable    varchar(13),
		  @sdo_final       numeric(16,2),
		  @val_umb_min     numeric(16,2),
		  @val_umb_max     numeric(16,2)

  DECLARE @NunRegistros      int, 
          @RowCount          int

  DECLARE @k_error        varchar(1) = 'E',
          @k_enero        int        = 1,
		  @k_diciembre    int        = 12,
		  @k_no_ult_nivel varchar(2) = '00',
		  @k_no_identif   varchar(2) = 'NI',
		  @k_pendiente    varchar(1) = 'P',
		  @k_no_aplica    varchar(2) = 'NA',
		  @k_verdadero    bit        = 1

  DECLARE @ano            int,
          @mes            int,
		  @ano_mes_ant    varchar(6),
		  @num_reg_proc   int = 0

-- Copia los saldos iniciales de cierre de año a la tabla CI_BALANZA_OPERATIVA
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  DELETE  CI_BALANZA_OPER_CALC  WHERE CVE_EMPRESA = @pCveEmpresa  AND
                                      ANO_MES     = @pAnoMes

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
--  SELECT  ' Año Mes Anterior ', @ano_mes_ant
  
  BEGIN  TRY

  INSERT  CI_BALANZA_OPER_CALC (ANO_MES, CVE_EMPRESA, CTA_CONTABLE, SDO_INICIAL, IMP_CARGO, IMP_ABONO, SDO_FINAL)
  SELECT  @pAnoMes, @pCveEmpresa, CTA_CONTABLE, SDO_FINAL, 0, 0, SDO_FINAL
  FROM CI_BALANZA_OPERATIVA b
  WHERE b.CVE_EMPRESA  =  @pCveEmpresa  AND
        b.ANO_MES  =  @ano_mes_ant      AND  
       (SELECT B_AFECTACION FROM  CI_CAT_CTA_CONT WHERE CI_CAT_CTA_CONT.CVE_EMPRESA  = @pCveEmpresa AND
								                        CI_CAT_CTA_CONT.CTA_CONTABLE = b.CTA_CONTABLE) = @k_verdadero
--   SELECT  ' INSERTE LOS SALDOS INICIALES '

  INSERT	INTO  @TSdosCtas 	
  SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, SUM(IMP_DEBE), SUM(IMP_HABER)  FROM CI_DET_POLIZA
  WHERE ANO_MES  =   @pAnoMes
  GROUP BY CVE_EMPRESA, ANO_MES, CTA_CONTABLE

  MERGE CI_CAT_CTA_CONT AS TARGET
       USING (
	          SELECT CVE_EMPRESA, CTA_CONTABLE FROM  @TSdosCtas
			 )  AS SOURCE 
          ON TARGET.CVE_EMPRESA     = SOURCE.CVE_EMPRESA  AND
		     TARGET.CTA_CONTABLE    = SOURCE.CTA_CONTABLE   

  WHEN NOT MATCHED BY TARGET THEN 
       INSERT (CVE_EMPRESA,
               CTA_CONTABLE,
			   DESC_CTA_CONT,
			   CVE_REFERENCIA,
			   SIT_CUENTA)
       VALUES
              (SOURCE.CVE_EMPRESA,
		       SOURCE.CTA_CONTABLE,
               '*Pendiente de Definir*',
	           @k_no_identif,
		       @k_pendiente);

  MERGE CI_BALANZA_OPER_CALC AS TARGET
       USING (
	          SELECT CVE_EMPRESA, ANO_MES, CTA_CONTABLE, IMP_CARGO_C, IMP_ABONO_C  FROM  @TSdosCtas
			 )  AS SOURCE 
          ON TARGET.CVE_EMPRESA     = SOURCE.CVE_EMPRESA  AND
             TARGET.ANO_MES         = SOURCE.ANO_MES      AND
		     TARGET.CTA_CONTABLE    = SOURCE.CTA_CONTABLE   

  WHEN MATCHED THEN
       UPDATE 
          SET IMP_CARGO  = SOURCE.IMP_CARGO_C,
		      IMP_ABONO  = SOURCE.IMP_ABONO_C,
			  SDO_FINAL  = SDO_INICIAL  + SOURCE.IMP_CARGO_C - SOURCE.IMP_ABONO_C

  WHEN NOT MATCHED BY TARGET THEN 
       INSERT (CVE_EMPRESA,
               ANO_MES,
               CTA_CONTABLE,
		       SDO_INICIAL,
		       IMP_CARGO,
               IMP_ABONO,
               SDO_FINAL)
       VALUES
              (SOURCE.CVE_EMPRESA,
		       @pAnoMes,
		       SOURCE.CTA_CONTABLE,
               0,
		       SOURCE.IMP_CARGO_C,
		       SOURCE.IMP_ABONO_C,
		       SOURCE.IMP_ABONO_C -  SOURCE.IMP_CARGO_C);

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Act Sdos Balanza'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
--    RAISERROR(@pMsgError,16,1)
  END CATCH
  SET @num_reg_proc = ISNULL((SELECT COUNT(*) FROM CI_BALANZA_OPER_CALC WHERE ANO_MES = @pAnoMes),0)
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc

-------------------------------------------------------------------------------
-- Verificación de Cuentas con Umbrales
-------------------------------------------------------------------------------

  DECLARE  @TCtasSdos       TABLE
          (RowID            int  identity(1,1),
		   CTA_CONTABLE     varchar(13),
		   SDO_FINAL        numeric(16,2),
		   VAL_UMB_MIN      numeric(16,2),
		   VAL_UMB_MAX      numeric(16,2))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TCtasSdos  (CTA_CONTABLE, SDO_FINAL, VAL_UMB_MIN, VAL_UMB_MAX)  
  SELECT b.CTA_CONTABLE, b.SDO_FINAL, c.VAL_UMB_MIN, c.VAL_UMB_MAX  FROM CI_BALANZA_OPER_CALC b, CI_CAT_CTA_CONT c
  WHERE  b.CVE_EMPRESA      =  @pCveEmpresa   AND
         b.ANO_MES          =  @pAnoMes       AND
		 b.CVE_EMPRESA      =  c.CVE_EMPRESA  AND
		 b.CTA_CONTABLE     =  c.CTA_CONTABLE AND
		 c.CVE_UMBRAL      <>  @k_no_aplica
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cta_contable = CTA_CONTABLE, @sdo_final = SDO_FINAL, @val_umb_min = VAL_UMB_MIN, @val_umb_max = VAL_UMB_MAX
	FROM @TCtasSdos
	WHERE  RowID  =  @RowCount

	IF  @sdo_final > @val_umb_max OR @sdo_final < @val_umb_min
	BEGIN
	  SET  @pError    =  'Cta. ' + @cta_contable + ' rebasa los umbrales especificados'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
--      RAISERROR(@pMsgError,16,1)
	END

	SET @RowCount     =   @RowCount  + 1
  END

END
