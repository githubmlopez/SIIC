USE [CARGADOR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

CREATE PROCEDURE spActRegGral  @pCveEmpresa varchar(4), @pIdProceso numeric(9,0), @pIdTarea numeric(9,0), @pNumReg  int 
AS
BEGIN
  DECLARE  @num_registros  int

  DECLARE  @k_activa       varchar(1)  =  'A'
  
--  SELECT 'Entro Reg ' + CONVERT(VARCHAR (10), @pIdProceso) + ' ' +  CONVERT(VARCHAR (10), @pIdTarea) + ' ' +
--  CONVERT(VARCHAR (10), @pGpoTransaccion)

  UPDATE  FC_GEN_TAREA  SET  NUM_REGISTROS =  @pNumReg  WHERE 
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso   AND
		  ID_TAREA     =  @pIdTarea   						    
    
END