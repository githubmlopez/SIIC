USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spValidaPeriodo')
BEGIN
  DROP  PROCEDURE spValidaPeriodo
END
GO

-- EXEC spValidaPeriodo 2,'EGG','MARIO','SIIC','201812',202,0,1,0,' ', ' ', 0,' ',' '  
CREATE OR ALTER PROCEDURE [dbo].[spValidaPeriodo]
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pCodigoUsuario   varchar(20),
  @pCveAplicacion   varchar(10),
  @pAnoPeriodo      varchar(6),
  @pIdProceso       numeric(9),
  @pIdTarea         numeric(9),
  @pFolioExe        int,
  @pBError          bit          OUT,
  @pError           varchar(80)  OUT,

  @pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @k_verdadero  bit        = 1,
          @k_falso      bit        = 0,
          @k_error      varchar(1) = 'E',
          @k_abierto    varchar(1) = 'A'

  DECLARE @sit_periodo  varchar(1)

  BEGIN TRY

    SET @sit_periodo  = ' '

    IF EXISTS (
       SELECT SIT_PERIODO
       FROM CI_PERIODO_CONTA
       WHERE CVE_EMPRESA    =  @pCveEmpresa
       AND ANO_MES        =  @pAnoPeriodo)
    BEGIN
      SELECT @sit_periodo   = SIT_PERIODO
      FROM CI_PERIODO_CONTA
      WHERE CVE_EMPRESA    =  @pCveEmpresa
      AND ANO_MES        =  @pAnoPeriodo
    END

    IF  @sit_periodo  <>  @k_abierto
    OR  NOT EXISTS (SELECT 1
                    FROM CI_PERIODO_ISR
                    WHERE CVE_EMPRESA    =  @pCveEmpresa
                    AND ANO_MES        =  @pAnoPeriodo)  
    BEGIN
      SET @pError    =  '(E) Periodo Contable no existe, cerrado o no existe periodo ISR ' + @pAnoPeriodo
      SET @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
      SET  @pBError  =  @k_verdadero
    END
  END TRY

  BEGIN CATCH
    SET @pError    =  '(E) Error al validar periodo ; ' + @pAnoPeriodo
    SET @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET @pBError   =  @k_verdadero
  END CATCH
END
GO