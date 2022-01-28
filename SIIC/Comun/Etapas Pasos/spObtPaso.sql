USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-------------------------------------------------------------------------------------------------
-- Obtiene los pasos de la empresa/Etapa solicitada                                                 --
-------------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtPaso')
BEGIN
  DROP  PROCEDURE spObtPaso
END
GO
-- EXEC spObtPaso 1,'EGG', 'MARIO', 'SIIC', '202109', 0,0,0,1,0,0,' ',' '
CREATE PROCEDURE [dbo].[spObtPaso]  
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
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  SET @pBError    =  NULL
  SET @pError     =  NULL
  SET @pMsgError  =  NULL  


  DECLARE  @k_activa       varchar(2)  =  'A'

  SELECT @pCveEmpresa AS CVE_EMPRESA, p.ID_ETAPA, p.ID_PASO, p.DESC_PASO, pp.SIT_PASO_PER
  FROM   FC_PASO p, FC_PASO_PERIODO pp
  WHERE  p.CVE_EMPRESA                  =  @pCveEmpresa     AND
         p.ID_ETAPA                     =  @pIdEtapa        AND
		 p.SIT_PASO                     =  @k_activa        AND
		(p.ID_PASO                      =  @pIdPaso         OR
		 ISNULL(@pIdPaso,0)             =  0)               AND
		 p.CVE_EMPRESA                  =  pp.CVE_EMPRESA   AND
         p.ID_ETAPA                     =  pp.ID_ETAPA      AND
		 P.ID_PASO                      =  PP.ID_PASO       AND
		 pp.PERIODO                     =  @pAnoPeriodo     		 
     
		 
END
