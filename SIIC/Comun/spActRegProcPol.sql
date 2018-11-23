USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

ALTER PROCEDURE spActRegProcPol  @pCveEmpresa varchar(4), @pIdProceso numeric(9,0), @pIdTarea numeric(9,0), @pAnoMes varchar(6),
                               @pCvePoliza  varchar(6) 
AS
BEGIN
  DECLARE  @num_registros  int

  DECLARE  @k_activa       varchar(1)  =  'A'
  
--  SELECT 'Entro Reg ' + CONVERT(VARCHAR (10), @pIdProceso) + ' ' +  CONVERT(VARCHAR (10), @pIdTarea) + ' ' +
--  CONVERT(VARCHAR (10), @pGpoTransaccion)

  SET  @num_registros  =  ISNULL((SELECT COUNT(*)  FROM  CI_DET_POLIZA d  WHERE 
                           d.CVE_EMPRESA      =  @pCveEmpresa  AND
						   d.ANO_MES          =  @pAnoMes      AND
						   d.CVE_POLIZA       =  @pCvePoliza   AND
						   d.SIT_DET_POLIZA   =  @k_activa),0)

  UPDATE  FC_GEN_TAREA  SET  NUM_REGISTROS =  @num_registros  WHERE 
          CVE_EMPRESA  =  @pCveEmpresa  AND
		  ID_PROCESO   =  @pIdProceso   AND
		  ID_TAREA     =  @pIdTarea   						    
    
END