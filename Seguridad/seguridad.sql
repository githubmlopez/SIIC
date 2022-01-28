USE [SEGURIDAD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-- exec spInfSegu 'efren.garcia@cerouno.com.mx', 'SECU'
ALTER PROCEDURE [dbo].[spInfSegu]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10)
AS
BEGIN

DECLARE  @cve_perfil    varchar(20)

DECLARE  @k_falso       varchar(1)  = '0'

SELECT @cve_perfil = CVE_PERFIL FROM FC_SEG_APLIC_USUARIO_PERFIL p
WHERE  CVE_USUARIO = @pCveUsuario  AND  CVE_APLICACION = @pCveAplicacion

--SELECT @cve_perfil

-------------------------------------------------------------------------------
-- Descripción de Tabla de Formas permitidas de Acceso
-------------------------------------------------------------------------------

  DECLARE  @TForma          TABLE
          (RowID            int  identity(1,1),
		   CVE_APLICACION   varchar(20),
		   CVE_MENU         varchar(20),
		   CVE_CAPACIDAD    varchar(50)
		   
-----------------------------------------------------------------------------------------------------
-- Extracción de las formas 
-----------------------------------------------------------------------------------------------------
  INSERT @TForma  (CVE_APLICACION, CVE_MENU, CVE_CAPACIDAD)  
  SELECT f.CVE_APLICACION, mf.CVE_MENU, f.CVE_FORMA, tc.CVE_CAPACIDAD
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
         mf.CVE_FORMA       =  f.CVE_FORMA      
  UNION
  SELECT f.CVE_APLICACION, mf.CVE_MENU, f.CVE_FORMA, NULL, NULL, f.URL  
  FROM   FC_SEG_FORMA f, FC_SEG_PERFIL_FORMA pf, FC_SEG_PERFIL p, FC_SEG_MENU_FORMA mf
  WHERE  pf.CVE_APLICACION  =  @pCveAplicacion  AND
         pf.CVE_PERFIL      =  @cve_perfil      AND
		 pf.B_BLOQUEADO     =  @k_falso         AND
         f.CVE_APLICACION   =  @pCveAplicacion  AND
         f.CVE_FORMA        =  pf.CVE_FORMA     AND
		 f.B_BLOQUEADO      =  @k_falso         AND
		 p.CVE_APLICACION   =  @pCveAplicacion  AND
         p.CVE_PERFIL       =  @cve_perfil      AND
		 p.B_BLOQUEADO      =  @k_falso         AND
 		 mf.CVE_APLICACION  =  @pCveAplicacion  AND
         mf.CVE_FORMA       =  f.CVE_FORMA;      

--SELECT 	* FROM @TForma;
	 
WITH CteMenu (CVE_APLICACION, CVE_MENU, CVE_MENU_P, Level)
AS
(
-- Definición de Miembro Ancla
    SELECT m.CVE_APLICACION, m.CVE_MENU, CVE_MENU_P , 0 AS Level
    FROM FC_SEG_MENU  m
    WHERE  m.CVE_APLICACION = @pCveAplicacion AND m.CVE_MENU_P IS NULL
    UNION ALL
-- Definición de Miembro Recursivo
    SELECT m.CVE_APLICACION, m.CVE_MENU, m.CVE_MENU_P, Level + 1
    FROM FC_SEG_MENU  m
    INNER JOIN CteMenu cte
    ON m.CVE_APLICACION = cte.CVE_APLICACION  AND
	   m.CVE_MENU_P = cte.CVE_MENU 
      
)
-- Instrucción que ejecuta el CTE

SELECT cte.CVE_APLICACION, cte.CVE_MENU, CVE_MENU_P, CVE_FORMA, CVE_CAPACIDAD, CVE_TIPO_CAP, URL, cte.Level,
case 
when (select count(*) from CteMenu es where cte.CVE_MENU = es.CVE_MENU_P) = 0
then '1'
else '0'
end as 'ultimo'
FROM CteMenu cte, @TForma f
WHERE  cte.CVE_APLICACION  =  f.CVE_APLICACION  AND
       cte.CVE_MENU        =  f.CVE_MENU  ORDER BY cte.Level
OPTION (MAXRECURSION 500);
END