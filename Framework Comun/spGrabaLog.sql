USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
--SELECT OBJECT_NAME(@@PROCID)
--EXEC sp_set_session_context 'language', 'English';
--SELECT SESSION_CONTEXT(N'language');

-- EXEC spGrabaLog 'CU','OTRA PRUEBA DE EVENTO'
CREATE PROCEDURE spGrabaLog @pCveEmpresa varchar(4), @pMsgEvento varchar(400)
AS
BEGIN
  DECLARE @txt_evento  varchar(200),
          @retorno     int

  DECLARE @path varchar(100)

  DECLARE @k_path varchar(100) = 'C:\LOG\'

  SET @path = @k_path + @pCveEmpresa + 'LOG.TXT'
--  SELECT @path

  SET @txt_evento = LTRIM('echo ' + CONVERT(VARCHAR(24),GETDATE(),113)  + '-' + @pMsgEvento + ' >> ' + @path)
  SET @txt_evento = REPLACE(@txt_evento,'==>',' : ')
  exec @retorno = master..xp_cmdshell @txt_evento,no_output
END