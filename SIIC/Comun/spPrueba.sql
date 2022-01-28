USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spPrueba')
BEGIN
  DROP  PROCEDURE spPrueba
END
GO
--EXEC spPrueba 1,'CU','MARIO','SIIC','202001',1,1,0,'spPrueba',' ',' '
CREATE PROCEDURE [dbo].[spPrueba]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(6),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       bit,
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT 							 
) 
AS
BEGIN
  SELECT 'EJECUCION CORRECTA'  
END
