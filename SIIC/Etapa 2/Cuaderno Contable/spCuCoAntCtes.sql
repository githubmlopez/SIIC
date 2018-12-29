USE ADMON01
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--exec spCuCoAntCtes  'CU', 'MARIO', '201804', 1, 2, ' ', ' '
ALTER PROCEDURE spCuCoAntCtes   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                   @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								   @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @k_activa         varchar(1)   =  'A',
		   @k_no_concilida   varchar(2)   =  'NC',
		   @k_error          varchar(1)   =  'E',
		   @k_cerrado        varchar(1)   =  'C',
		   @k_cxc            varchar(6)   =  'CXC'

  DECLARE  @num_reg_proc     int = 0

  BEGIN TRY

    IF  (SELECT SIT_PERIODO  FROM CI_PERIODO_CONTA WHERE ANO_MES = @pAnoMes) <> @k_cerrado
	BEGIN
      DELETE FROM CI_CUCO_MB_NO_CONC WHERE ANO_MES = @pAnoMes 
	END

    INSERT INTO CI_CUCO_MB_NO_CONC (ANO_MES, ANO_MES_M, CVE_CHEQUERA, ID_MOVTO_BANCARIO, F_OPERACION,CVE_MONEDA, 
	                                IMP_TRANSACCION,DESCRIPCION, TX_NOTA)
    SELECT @pAnoMes, m.ANO_MES, m.CVE_CHEQUERA, m.ID_MOVTO_BANCARIO, m.F_OPERACION, ch.CVE_MONEDA,m.IMP_TRANSACCION, m.DESCRIPCION, ' '
    FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch     
    WHERE m.SIT_CONCILIA_BANCO  = @k_no_concilida     AND
	      m.SIT_MOVTO           = @k_activa           AND
		  m.CVE_CHEQUERA        = ch.CVE_CHEQUERA     AND
		  m.CVE_TIPO_MOVTO      = @k_cxc              AND
		  dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION)) <=
		  @pAnoMes             
    SELECT @num_reg_proc = @@ROWCOUNT	

    EXEC  spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc

   END TRY

  BEGIN CATCH
    SET  @pError    =  'Error CUCO Pagos Ant ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

