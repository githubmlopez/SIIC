USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spParamCarga')
BEGIN
  DROP  PROCEDURE spParamCarga
END
GO
--EXEC spCargaInInv 'CU','MARIO','201906',105,1,' ',' '
CREATE PROCEDURE [dbo].[spParamCarga]
(
@pAnoPeriodo   varchar(6),
@pCveEmpresa   varchar(4),
@pIdProceso    int,
@pIdCliente    int          OUT,
@pTipoInfo     int          OUT,
@pIdBloque     int          OUT,
@pIdFormato    int          OUT,
@pCveChequera  varchar(6)   OUT
)
AS
BEGIN
  SELECT
  @pIdCliente  = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pTipoInfo   = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdBloque   = CONVERT(INT,SUBSTRING(PARAMETRO,13,6)),
  @pIdFormato  = CONVERT(INT,SUBSTRING(PARAMETRO,19,6))
  FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  SELECT @pCveChequera =  CVE_CHEQUERA  FROM CI_CHEQUERA WHERE CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6)) = @pTipoInfo  AND
                                                               CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6)) = @pIdFormato

  DELETE  FROM  CI_MOVTO_BANCARIO  WHERE ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @pCveChequera 
  
END