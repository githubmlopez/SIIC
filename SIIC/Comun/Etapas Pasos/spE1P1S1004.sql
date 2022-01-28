USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spE1P1S1004')
BEGIN
  DROP  PROCEDURE spE1P1S1004
END
GO

-- EXEC  spE1P1S1003 1, 'EGG', 'MARIO', 'PASOS', '202106', 0,0,0,0, ' ', ' '

--------------------------------------------------------------------------------------------
-- Verifica el estatus de un proceso que se ejecuta en una ETPA/PASO                      --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spE1P1S1004]  
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pCodigoUsuario   varchar(20),
  @pCveAplicacion   varchar(10),
  @pAnoPeriodo      varchar(6),
  @pIdProceso       numeric(9),
  @pFolioExe        int          OUT,
  @pIdTarea         bit,
  @pBError          bit          OUT,
  @pError           varchar(80)  OUT,
  @pMsgError        varchar(400) OUT
)

AS
BEGIN
  SELECT '*************************************'
  SET  @pFolioExe  = 1004
  SET  @pBError = 0
  SELECT 'El proceso 1004 se ejecuto correctamente'
END