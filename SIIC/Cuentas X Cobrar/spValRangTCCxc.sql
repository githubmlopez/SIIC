USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spValRangTCCxc')
BEGIN
  DROP  PROCEDURE spValRangTCCxc
END
GO
-- exec spValRangTCCxc 'EGG', '20190516', 'D', 18, 0, ' ', ' '
CREATE PROCEDURE [dbo].[spValRangTCCxc]  
@pCveEmpresa    varchar(4),
@pFOperacion    date,
@pCveMoneda     varchar(1),
@pTipoCambio    numeric(8,4),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  
  DECLARE   @tipo_cambio numeric(8,4),
            @umbral      numeric(8,4)
  
  DECLARE   @k_verdadero   bit  =  1,
            @k_falso       bit  =  0,
			@k_cerrado     varchar(1)  =  'C',
			@k_cve_umbral  varchar(4)  = 'UMMD'

  SET  @tipo_cambio  =  ISNULL(dbo.fnObtTipoCamb(@pCveEmpresa, @pFOperacion),0)
  
  SET  @pBError  =  @k_falso

  IF  ABS(@pTipoCambio - @tipo_cambio) > (SELECT VALOR_NUMERICO FROM CI_PARAMETRO  WHERE  CVE_EMPRESA = @pCveEmpresa  AND  CVE_PARAMETRO  =  'UMMD')
  BEGIN
      SET  @pBError    =  @k_verdadero
      SET  @pError     =  'Tipo Cambio fuera de rango' 
	  SET  @pMsgError  =  'Tipo Cambio fuera de rango'    
  END

END    
  
  
