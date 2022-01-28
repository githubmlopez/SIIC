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

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtEtapa')
BEGIN
  DROP  PROCEDURE spObtEtapa
END
GO
-- EXEC spObtEtapa 1,'EGG', 'MARIO', 'SIIC', '202109', 0,0,0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spObtEtapa]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(10),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pIdEtapa       int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  SET @pBError    =  NULL
  SET @pError     =  NULL
  SET @pMsgError  =  NULL  


  DECLARE  @k_activa       varchar(2)  =  'A'

  SELECT @pCveEmpresa AS CVE_EMPRESA, e.ID_ETAPA, e.ID_ETAPA, e.DESC_ETAPA, ep.SIT_ETAPA_PER
  FROM   FC_ETAPA e, FC_ETAPA_PERIODO ep
  WHERE  e.CVE_EMPRESA                  =  @pCveEmpresa     AND
		 e.SIT_ETAPA                    =  @k_activa        AND
		(e.ID_ETAPA                     =  @pIdEtapa        OR
		 ISNULL(@pIdEtapa,0)            =  0)               AND
		 e.CVE_EMPRESA                  =  ep.CVE_EMPRESA   AND
         e.ID_ETAPA                     =  ep.ID_ETAPA      AND
		 ep.PERIODO                     =  @pAnoPeriodo     		 
     
		 
END
 