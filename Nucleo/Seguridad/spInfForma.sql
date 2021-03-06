USE [INFRA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM INFRA.sys.procedures WHERE Name =  'spInfForma')
BEGIN
  DROP  PROCEDURE spInfForma
END
GO
-- exec spInfForma 'efren.garcia@cerouno.com.mx', 'INFRA', 'CI_CXC', ' '
CREATE PROCEDURE [dbo].[spInfForma]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10), @pCveForma varchar(20), @pPerfil varchar(20)
AS
BEGIN
  
  DECLARE  @cve_perfil  varchar(20)

  DECLARE   @k_verdadero bit  =  1,
            @k_falso     bit  =  0,
			@k_forma     varchar(1) = 'F',
			@k_Detalle   varchar(1) = 'D'

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
  
    SELECT 
    gpo.CVE_APLICACION AS CVE_APLICACION_G,
    gpo.CVE_FORMA AS CVE_FORMA_G, 
    gpo.CVE_GPO AS CVE_GPO_G,
    gpo.NUM_ORDEN AS NUM_ORDEN_G,   
    gpo.CVE_ETIQUETA AS CVE_ETIQUETA_G,
    gpo.TX_ETIQUETA AS TX_ETIQUETA_G, 
    gpo.ICONO_CLS,
--------------------------------------------------------------------
    fmt.CVE_APLICACION AS CVE_APLICACION_F,
    fmt.CVE_FORMA AS CVE_FORMA_F,
    fmt.CVE_TITULO_FORMA,
    fmt.TX_TITULO_FORMA,
    fmt.URL_API_FORMA,
    fmt.DESC_FORMA,
    fmt.CVE_TIPO_FORMA,
    fmt.CVE_TIPO_LAYOUT,
    fmt.NUM_COLUMNAS,
    fmt.NOM_VALIDACION,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_GRID', fmt.B_GRID, @k_forma, null) AS B_GRID_F,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_FILTRA', fmt.B_FILTRA, @k_forma, null) AS B_FILTRA_F,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_REPORTA', fmt.B_REPORTA, @k_forma, null) AS B_REPORTA_F,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_CREA', fmt.B_CREA, @k_forma, null) AS B_CREA_F,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_EDITA', fmt.B_EDITA, @k_forma, null) AS B_EDITA_F,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_BORRA', fmt.B_BORRA, @k_forma, null) AS B_BORRA,
    fmt.CVE_CATEGORIA,
    fmt.NOM_TABLA_DB,
----------------------------------------------------------------------------
    det.CVE_APLICACION AS CVE_APLICACION_D,
    det.CVE_FORMA  AS CVE_FORMA_D,
    det.NOM_CAMPO,
    det.NOM_CAMPO_DB,
    det.NUM_ORDEN AS NUM_ORDEN_D,
    det.NUM_FILA,
    det.NUM_COLUMNA,
    det.CVE_ETIQUETA AS CVE_ETIQUETA_D,
    det.TX_ETIQUETA AS TX_ETIQUETA,
    det.CVE_TIPO_CAMPO,
    det.CVE_TIPO_COMPONENTE,
    det.CVE_TAMANO_CAMPO,
    det.CVE_AYUDA,
    det.TX_AYUDA,
    det.B_PK,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_CREA', det.B_CREA, @k_Detalle,		det.NOM_CAMPO) AS B_CREA_D,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_EDITA', det.B_EDITA, @k_Detalle, det.NOM_CAMPO) AS B_EDITA_D,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_REQUERIDO', det.B_REQUERIDO, @k_Detalle, det.NOM_CAMPO) AS B_REQUERIDO,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_GRID', det.B_GRID, @k_Detalle, det.NOM_CAMPO) AS B_GRID_D,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_FILTRA', det.B_FILTRA, @k_Detalle, det.NOM_CAMPO) AS B_FILTRA_D,
    dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_REPORTA', det.B_REPORTA, @k_Detalle, det.NOM_CAMPO) AS B_REPORTA_D,
    det.NOM_VALIDACION,
    det.VALOR_INICIAL,
    det.NUM_LONG_MIN,
    det.NUM_LONG_MAX,
    det.TX_REGEX,
    det.NUM_ENTEROS,
    det.NUM_DECIMALES,
    det.URL_API,
    det.NOM_CAMPO_VALOR,
    det.NOM_CAMPO_ETIQUETA,
    det.CVE_TIPO_RELACION,
    det.CVE_FORMA_RELACION,
    det.NOM_CAMPO_DEPENDE,
    det.CVE_GPO AS CVE_GPO_D,
    det.FN_MUESTRA,
    det.FN_OBTEN_VALOR,
    det.FN_VALIDA	
    FROM INFRA.dbo.INF_FORMA  fmt
    JOIN INFRA.dbo.INF_FORMA_DET det      ON  fmt.CVE_APLICACION  = det.CVE_APLICACION
                                          AND fmt.CVE_FORMA       = det.CVE_FORMA
    LEFT JOIN INFRA.dbo.INF_FORMA_GPO gpo ON  det.CVE_APLICACION  = gpo.CVE_APLICACION
                                          AND det.CVE_FORMA       = gpo.CVE_FORMA
                                          AND det.CVE_GPO         = gpo.CVE_GPO
    WHERE fmt.CVE_APLICACION = @pCveAplicacion AND fmt.CVE_FORMA = @pCveForma 
  END

END    
  
  
