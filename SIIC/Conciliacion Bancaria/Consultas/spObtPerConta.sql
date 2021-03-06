USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtPerConta')
BEGIN
  DROP  PROCEDURE spObtPerConta
END
GO

-- EXEC spObtPerConta 'CU', ' ', 'A', 0,' ',' '

--------------------------------------------------------------------------------------------
-- Obtiene los periodos contables, dependiendo del parametro Abierto/Cerrado              --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spObtPerConta]  
@pCveEmpresa    varchar(4),
@pAnoPeriodo    varchar(6),
@pSitPeriodo    varchar(1),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  SELECT ANO_MES, F_INICIAL, F_FINAL, SIT_PERIODO  FROM CI_PERIODO_CONTA
  WHERE  CVE_EMPRESA   =   @pCveEmpresa  AND
        (ANO_MES       =   @pAnoPeriodo  OR
		(ISNULL(@pAnoPeriodo, ' ') = ' ') AND
		(SIT_PERIODO   =   @pSitPeriodo  OR
		ISNULL(@pSitPeriodo, ' ') = ' '))   
END