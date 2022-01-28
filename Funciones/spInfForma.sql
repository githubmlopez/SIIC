USE [INFRA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM INFRA.sys.procedures WHERE Name =  'spInfDetForma')
BEGIN
  DROP  PROCEDURE spInfDetForma
END
GO
-- exec spInfDetForma 'efren.garcia@cerouno.com.mx', 'INFRA', 'CI_CXC', ' '
CREATE PROCEDURE [dbo].[spInfDetForma]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10), @pCveForma varchar(20), @pPerfil varchar(20)
AS
BEGIN
  
  DECLARE  @cve_perfil  varchar(20)

  DECLARE   @k_verdadero bit  =  1,
            @k_falso     bit  =  0,
			@k_activo    varchar(2) = 'AC'

-- Se obtiene el perfil de la forma dentro de la aplicación
  IF  ISNULL(@pPerfil, ' ') = ' ' 
  BEGIN 
    SET @cve_perfil = (SELECT CVE_PERFIL FROM FC_SEG_APLIC_USUARIO_PERFIL  WHERE
    CVE_USUARIO    =  @pCveUsuario     AND
    CVE_APLICACION =  @pCveAplicacion)
  END
  ELSE
  BEGIN
    SET  @cve_perfil  =  @pPerfil
  END

  IF  (SELECT B_ACTIVA FROM FC_SEG_PERFIL WHERE CVE_APLICACION = @pCveAplicacion  AND  CVE_PERFIL = @cve_perfil)  =  @k_verdadero
  BEGIN
    SELECT pf.CVE_FORMA as CVE_FORMA, pf.NOM_CAMPO as CVE_CAMPO, pf.CVE_CAPACIDAD as CVE_CAPACIDAD 
    FROM   INF_FORMA f, FC_SEG_PERFIL_CAMPO pf
    WHERE  f.CVE_APLICACION   =  @pCveAplicacion  AND
           f.CVE_FORMA        =  @pCveForma       AND
		   pf.CVE_APLICACION  =  f.CVE_APLICACION AND
           pf.CVE_FORMA       =  f.CVE_FORMA      AND
		   pf.CVE_PERFIL      =  @cve_perfil      
  END
END