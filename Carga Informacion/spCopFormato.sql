USE [CARGADOR]
GO
/****** Copia Formato de Carga ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCopFormato')
BEGIN
  DROP  PROCEDURE spCopFormato
END
GO
--EXEC spCopFormato 1,1,'MARIO',1,'CU','NOMINA',30,20,'SAT CXC','SATCXC',' ',' '
CREATE PROCEDURE [dbo].[spCopFormato]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pIdFormato       int,
@pFormNvo         int,
@pDescArchivo     varchar(50),
@pNomArchivo      varchar(20),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
 DELETE FROM FC_CARGA_IND  WHERE
 ID_CLIENTE  = @pIdCliente  AND
 CVE_EMPRESA = @pCveEmpresa AND
 ID_FORMATO  = @pFormNvo

 DELETE FROM FC_CARGA_POSIC WHERE
 ID_CLIENTE  = @pIdCliente  AND
 CVE_EMPRESA = @pCveEmpresa AND
 ID_FORMATO  = @pFormNvo

 DELETE FROM FC_CARGA_RENG_ENCA WHERE
 ID_CLIENTE  = @pIdCliente  AND
 CVE_EMPRESA = @pCveEmpresa AND
 ID_FORMATO  = @pFormNvo

 DELETE FROM FC_FORMATO WHERE
 ID_CLIENTE  = @pIdCliente  AND
 CVE_EMPRESA = @pCveEmpresa AND
 ID_FORMATO  = @pFormNvo

 INSERT FC_FORMATO
 (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  CVE_TIPO_ARCHIVO,
  DESC_ARCHIVO,
  NOM_ARCHIVO,
  CVE_TIPO_PERIODO,
  PATHS,
  B_SEPARADOR,
  CAR_SEPARA
 )  
 SELECT
 ID_CLIENTE,
 CVE_EMPRESA,
 @pFormNvo,
 CVE_TIPO_ARCHIVO,
 @pDescArchivo,
 @pNomArchivo,
 CVE_TIPO_PERIODO,
 PATHS,
 B_SEPARADOR,
 CAR_SEPARA
 FROM FC_FORMATO WHERE
 ID_CLIENTE  = @pIdCliente  AND
 CVE_EMPRESA = @pCveEmpresa AND
 ID_FORMATO  = @pIdFormato

 INSERT FC_CARGA_RENG_ENCA
 (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  ID_BLOQUE,
  NUM_RENG_INI,
  NUM_RENG_FIN,
  NUM_CAMPOS,
  CADENA_FIN,
  CVE_TIPO_BLOQUE,
  NUM_RENG_D_CAD,
  CADENA_ENCA
 )  
  SELECT
  ID_CLIENTE,
  CVE_EMPRESA,
  @pFormNvo,
  ID_BLOQUE,
  NUM_RENG_INI,
  NUM_RENG_FIN,
  NUM_CAMPOS,
  CADENA_FIN,
  CVE_TIPO_BLOQUE,
  NUM_RENG_D_CAD,
  CADENA_ENCA
  FROM FC_CARGA_RENG_ENCA WHERE
  ID_CLIENTE  = @pIdCliente  AND
  CVE_EMPRESA = @pCveEmpresa AND
  ID_FORMATO  = @pIdFormato

  INSERT FC_CARGA_POSIC
 (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  ID_BLOQUE,
  NUM_COLUMNA,
  POS_INICIAL,
  POS_FINAL,
  DESC_CAMPO,
  CVE_TIPO_CAMPO
 )  
  SELECT
  ID_CLIENTE,
  CVE_EMPRESA,
  @pFormNvo,
  ID_BLOQUE,
  NUM_COLUMNA,
  POS_INICIAL,
  POS_FINAL,
  DESC_CAMPO,
  CVE_TIPO_CAMPO
  FROM FC_CARGA_POSIC WHERE
  ID_CLIENTE  = @pIdCliente  AND
  CVE_EMPRESA = @pCveEmpresa AND
  ID_FORMATO  = @pIdFormato

  INSERT FC_CARGA_IND
 (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  SECUENCIA,
  NUM_COLUMNA,
  POS_INICIAL,
  POS_FINAL,
  DESC_CAMPO,
  NUM_RENG_D_CAD,
  CADENA_ENCA,
  CVE_TIPO_BLOQUE,
  CVE_TIPO_CAMPO
 )  
  SELECT
  ID_CLIENTE,
  CVE_EMPRESA,
  @pFormNvo,
  SECUENCIA,
  NUM_COLUMNA,
  POS_INICIAL,
  POS_FINAL,
  DESC_CAMPO,
  NUM_RENG_D_CAD,
  CADENA_ENCA,
  CVE_TIPO_BLOQUE,
  CVE_TIPO_CAMPO
  FROM FC_CARGA_IND WHERE
  ID_CLIENTE  = @pIdCliente  AND
  CVE_EMPRESA = @pCveEmpresa AND
  ID_FORMATO  = @pIdFormato

END