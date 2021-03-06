USE [ADMON01]
GO
/******  Obtiene folio de instancia de ejecucion de proceso ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'P') AND Name =  'spObtFolInstExe')
BEGIN
  DROP  PROCEDURE spObtFolInstExe
END
GO

CREATE PROCEDURE [dbo].[spObtFolInstExe] 
(
@pIdCliente  int,
@pCveEmpresa varchar(4),
@pIdProceso  int,
@pFolioExe   int OUT
)
AS
BEGIN

  DECLARE @TFolio    TABLE(
          FOLIO_EXEC int NOT NULL
  )

  UPDATE FC_PROCESO SET FOLIO_EXEC = FOLIO_EXEC + 1  OUTPUT inserted.FOLIO_EXEC  INTO  @TFolio
  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
        ID_PROCESO   =  @pIdProceso

  SET @pFolioExe = ISNULL((SELECT FOLIO_EXEC FROM @TFolio),0)

END