USE [ADMON01]
GO
/****** Calcula faltas por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spGenCxPcom')
BEGIN
  DROP  PROCEDURE spGenCxPcom
END
GO
--EXEC spGenCxPcom 1,1,1,'CU','NOMINA','S','201801',1,0,' ',' '
CREATE PROCEDURE [dbo].[spGenCxPcom]
(
 @pCveEmpresa varchar(4),
 @pCodigoUsuario varchar(8),
 @pAnoMes     varchar(6),
 @pIdProceso  numeric(9),
 @pIdTarea    numeric(9),
 @pError      varchar(80) OUT,
 @pMsgError   varchar(400) OUT )
AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_comision        varchar(2) = 'CO',
           @k_iva             varchar(2) = 'IV',
		   @k_activo          varchar(1) = 'A',
		   @k_error           varchar(1) = 'E'

  DECLARE  @TCheqComis       TABLE
		  (CVE_CHEQUERA      int,
		   IMP_COMISION      numeric(16,2),
		   IMP_IVA           numeric(16,2))

  DECLARE  @TCheqIva         TABLE
		  (CVE_CHEQUERA      int,
		   IMP_IVA           numeric(16,2))

  BEGIN TRY

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
          SET TARGET.IMP_IVA  = SOURCE.IMP_IVA

  WHEN NOT MATCHED BY TARGET THEN 
       UPDATE 
          SET TARGET.IMP_IVA  = 0;
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error ' + '(P) ' + ERROR_PROCEDURE() 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

  IF  EXISTS(SELECT 1 FROM @TCheqComis WHERE IMP_IVA = 0)
  BEGIN
  END

END

