USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCreaProcExePaso')
BEGIN
  DROP  PROCEDURE spCreaProcExePaso
END
GO

-- EXEC  spCreaProcExePaso 'EGG', 1,1,'202106', 1002, 1, 'C', 0, ' ',' '

--------------------------------------------------------------------------------------------
-- Crea registro de bitacora de ejecucion por periodo                                     --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spCreaProcExePaso]  
@pCveEmpresa    varchar(4),
@pIdEtapa       int,
@pIdPaso        int,
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,     
@pSitProceso    varchar(2),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

   DECLARE  @k_verdadero  bit  =  1,
	        @k_falso      bit  =  0

   SET  @pBError    =  @k_falso
   BEGIN TRY
     INSERT  FC_PASO_PROC_EXEC (PERIODO, CVE_EMPRESA, ID_ETAPA, ID_PASO, ID_PROCESO, FOLIO_EXEC, SIT_PROCESO) VALUES
    (@pAnoPeriodo, @pCveEmpresa, @pIdEtapa, @pIdPaso, @pIdProceso, @pFolioExe, @pSitProceso)
  END TRY
  BEGIN CATCH
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) No fue posible insertar Ejecucion Periodo' + ';' 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
  END CATCH
END