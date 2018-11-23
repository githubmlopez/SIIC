USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
-- EXEC spEstatMonInd  'CU', '201804', 'MLOPEZ'

CREATE PROCEDURE [dbo].[spEstatMonInd] (@pCveEmpresa varchar(4), @pAnoMes varchar(6),  @pCveUsuario varchar(20))
AS                                        
BEGIN

  DECLARE @k_falso         bit  =  0,
          @k_verdadero     bit  =  1,
		  @k_correcta      varchar(2)  =  'CO',
		  @k_error_proc    varchar(2)  =  'ER'

  DECLARE @TMonitorIndica TABLE (
          RowID           int IDENTITY(1,1) NOT NULL,
          CVE_EMPRESA     varchar(4),
          CVE_INDICADOR   varchar(10),
          DESC_INDICADOR  varchar (50),
          CODIGO_USUARIO  varchar(20),
          IMP_PIVOTE      numeric(16,2),
          IMP_SECUNDARIO  numeric(16,2),
          SIT_PROCESO     varchar(2))
   
  INSERT  @TMonitorIndica (CVE_EMPRESA, CVE_INDICADOR, DESC_INDICADOR, CODIGO_USUARIO, IMP_PIVOTE, IMP_SECUNDARIO, SIT_PROCESO)
  SELECT  @pCveEmpresa, i.CVE_INDICADOR, i.DESC_INDICADOR, @pCveUsuario, ip.IMP_PIVOTE, ip.IMP_SECUNDARIO,
  CASE
  WHEN    ip.IMP_PIVOTE <> ip.IMP_SECUNDARIO
  THEN    @k_error_proc
  ELSE    @k_correcta
  END        
  FROM    CI_INDICADOR i, CI_INDICA_PERIODO ip
  WHERE   ip.CVE_EMPRESA   =  @pCveEmpresa    AND
          ip.ANO_MES       =  @pAnoMes        AND
		  ip.CVE_INDICADOR = i.CVE_INDICADOR		         

  SELECT * FROM @TMonitorIndica
END