USE [SEGURIDAD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM SEGURIDAD.sys.procedures WHERE Name =  'spInfMenu')
BEGIN
  DROP  PROCEDURE spInfMenu
END
GO

-- exec spInfMenu 'efren.garcia@cerouno.com.mx', 'SECU' --, 'MN_r-4'
CREATE PROCEDURE [dbo].[spInfMenu]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10) -- , @pCveMenu varchar(20)
AS
BEGIN

DECLARE  @cve_perfil    varchar(20)

DECLARE  @k_falso       bit  = '0'

SELECT @cve_perfil = CVE_PERFIL FROM FC_SEG_APLIC_USUARIO_PERFIL p
WHERE  CVE_USUARIO = @pCveUsuario  AND  CVE_APLICACION = @pCveAplicacion;

--SELECT @cve_perfil

	 
WITH CteMenu (CVE_APLICACION, CVE_MENU, CVE_MENU_P, DESC_MENU, URL,  Level, ICONO_CLS)
AS
(
-- Definición de Miembro Ancla
    SELECT m.CVE_APLICACION, m.CVE_MENU, m.CVE_MENU_P , m.DESC_MENU, m.URL, 0 AS Level, m.ICONO_CLS
    FROM FC_SEG_MENU  m
    WHERE  m.CVE_APLICACION = @pCveAplicacion AND CVE_MENU_P IS NULL
    UNION ALL
-- Definición de Miembro Recursivo
    SELECT m.CVE_APLICACION, m.CVE_MENU, m.CVE_MENU_P , m.DESC_MENU, m.URL, Level + 1, m.ICONO_CLS
    FROM FC_SEG_MENU  m
    INNER JOIN CteMenu cte
    ON m.CVE_APLICACION = cte.CVE_APLICACION  AND
	   m.CVE_MENU_P = cte.CVE_MENU 
)
-- Instrucción que ejecuta el CTE

SELECT cte.CVE_APLICACION, cte.CVE_MENU, cte.CVE_MENU_P, cte.DESC_MENU, cte.URL, cte.Level, cte.ICONO_CLS,
case 
when (select count(*) from CteMenu es where cte.CVE_MENU = es.CVE_MENU_P) = 0
then '1'
else '0'
end as 'ultimo'
FROM CteMenu cte ORDER BY cte.Level, cte.CVE_MENU_P
OPTION (MAXRECURSION 500);
END