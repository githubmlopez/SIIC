USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtTipoCambioCxc')
BEGIN
  DROP  PROCEDURE spObtTipoCambioCxc
END
GO
-- CU	D	2019-05-16	19.1236
-- exec spObtTipoCambioCxc 'CU', '20220516', 'D', 0, 0, ' ', ' '
CREATE PROCEDURE [dbo].[spObtTipoCambioCxc]  
@pCveEmpresa    varchar(4),
@pFOperacion    date,
@pCveMoneda     varchar(1),
@pTipoCambio    numeric(8,4) OUT,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  
  DECLARE   @k_verdadero bit  =  1,
            @k_falso     bit  =  0,
			@k_cerrado   varchar(1)  =  'C'

  SET  @pTipoCambio  =  ISNULL(dbo.fnObtTipoCamb(@pCveEmpresa, @pFOperacion),0)
  
  SET  @pBError  =  @k_falso

  IF  @pTipoCambio = 0 
  BEGIN
      SET  @pBError   =  @k_verdadero
      SET  @pError    =  'El Tipo de cambio no existe'    
	  SET  @pMsgError =  @pError 
  END

END    
  
  
