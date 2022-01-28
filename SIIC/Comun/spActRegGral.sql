USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActRegGral')
BEGIN
  DROP  PROCEDURE spActRegGral
END
GO

CREATE PROCEDURE spActRegGral  @pCveEmpresa varchar(4), @pIdProceso numeric(9,0), @pFolioExe int, @pIdTarea numeric(9,0), @pNumReg  int 
AS
BEGIN
  DECLARE  @num_registros  int

  DECLARE  @k_activa       varchar(1)  =  'A'
  
--  SELECT 'Entro Reg ' + CONVERT(VARCHAR (10), @pIdProceso) + ' ' +  CONVERT(VARCHAR (10), @pIdTarea) + ' ' +
--  CONVERT(VARCHAR (10), @pGpoTransaccion)

  UPDATE  FC_TAREA  SET  NUM_REGISTROS =  @pNumReg  WHERE 
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso   AND
		  FOLIO_EXEC   =  @pFolioExe    AND
		  ID_TAREA     =  @pIdTarea   						    
    
END