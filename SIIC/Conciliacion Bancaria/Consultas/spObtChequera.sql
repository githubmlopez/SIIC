USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtChequera')
BEGIN
  DROP  PROCEDURE spObtChequera
END
GO

-- EXEC spObtChequera 'CU', ' ', 0,' ',' '

--------------------------------------------------------------------------------------------
-- Obtiene las chequeras disponibles por empresa             --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spObtChequera]  
@pCveEmpresa    varchar(4),
@pChequera      varchar(6),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  DECLARE  @k_verdadero bit = 1,
           @k_falso     bit = 0

  SELECT CVE_CHEQUERA, BANCO, DESC_CHEQUERA, CVE_MONEDA FROM CI_CHEQUERA
  WHERE  CVE_EMPRESA   =   @pCveEmpresa  AND
         B_CONCILIA    =   @k_verdadero  AND
        (CVE_CHEQUERA  =   @pChequera    OR
		ISNULL(@pChequera, ' ') = ' ')
END;


