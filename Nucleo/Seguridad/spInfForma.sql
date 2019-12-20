USE [SEGURIDAD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM SEGURIDAD.sys.procedures WHERE Name =  'spInfForma')
BEGIN
  DROP  PROCEDURE spInfForma
END
GO
-- exec spInfForma 'efren.garcia@cerouno.com.mx', 'SECU', 'MN_r-1-1'
CREATE PROCEDURE [dbo].[spInfForma]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10), @pCveMenu varchar(20)
AS
BEGIN
  
  DECLARE  @cve_perfil  varchar(20)

  DECLARE  @k_falso     bit  =  0

  SELECT @cve_perfil = CVE_PERFIL FROM FC_SEG_APLIC_USUARIO_PERFIL  WHERE
  CVE_USUARIO    =  @pCveUsuario     AND
  CVE_APLICACION =  @pCveAplicacion  

  SELECT f.CVE_FORMA, tc.CVE_CAPACIDAD, tc.CVE_TIPO_CAP 
  FROM   FC_SEG_FORMA f, FC_SEG_PERFIL_FORMA pf, FC_SEG_PERFIL p, FC_SEG_CAP_TIPO tc, FC_SEG_MENU_FORMA mf
  WHERE  pf.CVE_APLICACION  =  @pCveAplicacion  AND
         pf.CVE_PERFIL      =  @cve_perfil      AND
		 pf.B_BLOQUEADO     =  @k_falso         AND
         f.CVE_APLICACION   =  @pCveAplicacion  AND
         f.CVE_FORMA        =  pf.CVE_FORMA     AND
		 f.B_BLOQUEADO      =  @k_falso         AND
		 p.CVE_APLICACION   =  @pCveAplicacion  AND
         p.CVE_PERFIL       =  @cve_perfil      AND
		 p.B_BLOQUEADO      =  @k_falso         AND
		 tc.CVE_APLICACION  =  @pCveAplicacion  AND
         tc.CVE_FORMA       =  f.CVE_FORMA      AND
 		 mf.CVE_APLICACION  =  @pCveAplicacion  AND
         mf.CVE_MENU        =  @pCveMenu        
END