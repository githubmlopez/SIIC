USE [ADMON01]
GO

--exec spIngIdentBan 'CU', 'MARIO', '201804', 1, 2, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--exec spRepPagRecib 'CU', '201804'
ALTER PROCEDURE spRepPagRecib @pCveEmpresa varchar(4), @pAnoMes  varchar(6)
AS
BEGIN
  DECLARE  @k_cxc             varchar(3)   =  'CXC',
           @k_falso           bit          =  0

  DECLARE  @TPagosRecib TABLE
  (ID_MOVTO_BANCARIO      int NOT NULL)

  INSERT  @TPagosRecib  (ID_MOVTO_BANCARIO)
  SELECT  DISTINCT(ID_MOVTO_BANCARIO)
  FROM    CI_CONCILIA_C_X_C
  WHERE   ANOMES_PROCESO     = @pAnoMes
                       
  SELECT  m.ANO_MES, m.ID_MOVTO_BANCARIO, m.F_OPERACION, m.IMP_TRANSACCION, m.CVE_TIPO_MOVTO, m.DESCRIPCION,
  dbo.fnAcredIva (@pCveEmpresa, m.ID_MOVTO_BANCARIO) AS ACREDITA
  FROM  CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t, CI_CHEQUERA ch, @TPagosRecib cc 
  WHERE cc.ID_MOVTO_BANCARIO  = m.ID_MOVTO_BANCARIO  AND
        m.CVE_TIPO_MOVTO      = t.CVE_TIPO_MOVTO     AND
        m.CVE_CHEQUERA        = ch.CVE_CHEQUERA      AND
	    m.CVE_TIPO_MOVTO      = @k_cxc               AND
		dbo.fnAcredIva (@pCveEmpresa, m.ID_MOVTO_BANCARIO) = @k_falso              
END