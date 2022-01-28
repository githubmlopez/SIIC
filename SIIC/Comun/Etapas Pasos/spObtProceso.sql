USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-------------------------------------------------------------------------------------------------
-- Obtiene los procesos de la empresa/Etapa/Paso solicitada                                                 --
-------------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtProceso')
BEGIN
  DROP  PROCEDURE spObtProceso
END
GO
-- EXEC spObtProceso 1,'EGG', 'MARIO', 'SIIC', '202109', 0,0,0,1,1,1002,0,' ',' '
CREATE PROCEDURE [dbo].[spObtProceso]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(10),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pIdEtapa       int,
@pIdPaso        int,
@pIdProcPaso    numeric(9),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  SET @pBError    =  NULL
  SET @pError     =  NULL
  SET @pMsgError  =  NULL  


  DECLARE  @k_activa       varchar(2)  =  'A'

  SELECT @pCveEmpresa AS CVE_EMPRESA, p.ID_PROCESO, p.NOMBRE_PROCESO,
  dbo.fnObtSitProcExe(@pCveEmpresa, @pIdEtapa, @pIdPaso, @pAnoPeriodo, P.ID_PROCESO) AS SIT_PROCESO
  FROM   FC_PROCESO p, FC_PASO_PROCESO pe
  WHERE  pe.CVE_EMPRESA                 =  @pCveEmpresa     AND
         pe.ID_ETAPA                    =  @pIdEtapa        AND
         pe.ID_PASO                     =  @pIdPaso         AND
		 pe.SIT_PASO_PROC               =  @k_activa        AND
		(pe.ID_PROCESO                  =  @pIdProcPaso     OR
		 ISNULL(@pIdProcPaso,0)         =  0)               AND
		 pe.CVE_EMPRESA                 =  p.CVE_EMPRESA    AND
         pe.ID_PROCESO                  =  p.ID_PROCESO
		 
END
-- CREATE FUNCTION [dbo].[fnObtSitProcExe] 
--(
--@pCveEmpresa    varchar(4),
--@pIdEtapa       int,
--@pIdPaso        int,
--@pAnoPeriodo    varchar(10),
--@pIdProceso     numeric(9)