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
CREATE PROCEDURE [dbo].[spInfDetForma]  @pCveUsuario varchar(100), @pCveAplicacion varchar(10), @pCveForma varchar(20), 
@pPerfil varchar(20)
AS
BEGIN
  
  DECLARE  @cve_perfil  varchar(20)

  DECLARE   @k_verdadero bit  =  1,
            @k_falso     bit  =  0,
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
	CVE_APLICACION,
	CVE_FORMA,
	NOM_CAMPO,
	NOM_CAMPO_DB,
	NUM_ORDEN
	NUM_FILA,
	NUM_COLUMNA,
	CVE_ETIQUETA,
	TX_ETIQUETA,
	CVE_TIPO_CAMPO,
	CVE_TIPO_COMPONENTE,
	CVE_TAMANO_CAMPO,
	CVE_AYUDA,
	TX_AYUDA,
	B_PK,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_CREA', B_CREA, @k_Detalle, NOM_CAMPO) AS B_CREA,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_EDITA', B_EDITA, @k_Detalle, NOM_CAMPO) AS B_EDITA,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_REQUERIDO', B_REQUERIDO, @k_Detalle, NOM_CAMPO) AS B_REQUERIDO,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_GRID', B_GRID, @k_Detalle, NOM_CAMPO) AS B_GRID,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_FILTRA', B_FILTRA, @k_Detalle, NOM_CAMPO) AS B_FILTRA,
	dbo.fnDefCapacidad(@pCveAplicacion, @pCveForma, @cve_perfil, 'B_REPORTA', B_REPORTA, @k_Detalle, NOM_CAMPO) AS B_REPORTA,
	NOM_VALIDACION,
	VALOR_INICIAL,
	NUM_LONG_MIN,
	NUM_LONG_MAX,
	TX_REGEX,
	NUM_ENTEROS,
	NUM_DECIMALES,
	URL_API,
	NOM_CAMPO_VALOR,
	NOM_CAMPO_ETIQUETA,
	CVE_TIPO_RELACION,
	CVE_FORMA_RELACION,
	NOM_CAMPO_DEPENDE,
	CVE_GPO,
	FN_MUESTRA,
	FN_OBTEN_VALOR,
	FN_VALIDA	
	FROM INF_FORMA_DET d
	WHERE d.CVE_APLICACION = @pCveAplicacion AND d.CVE_FORMA = @pCveForma 
  END

END    
  
  
