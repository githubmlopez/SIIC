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
--EXEC spCargaInInv 'CU','MARIO','202011',105,1,' ',' '
CREATE PROCEDURE [dbo].[spParamCarga]
(
@pAnoPeriodo   varchar(6),
@pCveEmpresa   varchar(4),
@pIdProceso    int,
@pTipoInfo     int          OUT,
@pIdBloque     int          OUT,
@pIdFormato    int          OUT,
@pCveChequera  varchar(6)   OUT,
@pBorraMovto   bit
)
AS
BEGIN
  DECLARE  @k_verdadero  bit = 1
  SELECT
  @pTipoInfo   = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @pIdBloque   = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @pIdFormato  = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
  FROM  FC_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

  SELECT @pCveChequera =  CVE_CHEQUERA  FROM CI_CHEQUERA WHERE CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6))  = @pTipoInfo  AND
                                                               CONVERT(INT,SUBSTRING(PARAM_INFORMACION,7,6))  = @pIdBloque  AND
                                                               CONVERT(INT,SUBSTRING(PARAM_INFORMACION,13,6)) = @pIdFormato

  IF  @pBorraMovto  =  @k_verdadero
  BEGIN
    DELETE  FROM  CI_MOVTO_BANCARIO  WHERE 
	CVE_EMPRESA = @pCveEmpresa  AND ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @pCveChequera 
  END
END