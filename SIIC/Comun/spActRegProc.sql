USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

ALTER PROCEDURE spActRegProc  @pCveEmpresa varchar(4), @pIdProceso numeric(9,0), @pIdTarea numeric(9,0), @pGpoTransaccion  int 
AS
BEGIN
  DECLARE  @num_registros  int

  DECLARE  @k_activa       varchar(1)  =  'A'
  
--  SELECT 'Entro Reg ' + CONVERT(VARCHAR (10), @pIdProceso) + ' ' +  CONVERT(VARCHAR (10), @pIdTarea) + ' ' +
--  CONVERT(VARCHAR (10), @pGpoTransaccion)

  SET  @num_registros  =  ISNULL((SELECT COUNT(*)  FROM  CI_TRANSACCION_CONT t  WHERE 
                           t.GPO_TRANSACCION  =  @pGpoTransaccion  AND
						   t.SIT_TRANSACCION  =  @k_activa),0)

  UPDATE  FC_GEN_TAREA  SET  NUM_REGISTROS =  @num_registros  WHERE 
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso   AND
		  ID_TAREA     =  @pIdTarea   						    
    
END