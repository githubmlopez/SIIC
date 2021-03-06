USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spValFOperCxc]    Script Date: 26/01/2022 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec spValFOperCxc 'EGG', '20210801', 0, ' ', ' '
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spValFOperCxc')
BEGIN
  DROP  PROCEDURE spValFOperCxc
END
GO
CREATE PROCEDURE [dbo].[spValFOperCxc]  
@pCveEmpresa    varchar(4),
@pFOperacion    date,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  
  DECLARE   @ano_mes     varchar(6)

  DECLARE   @k_verdadero bit  =  1,
            @k_falso     bit  =  0,
			@k_cerrado   varchar(1)  =  'C'

  SET  @ano_mes  =  dbo.fnObtAnoMesFec(@pFOperacion)

  SET  @pBError  =  @k_falso

  IF  (SELECT SIT_PERIODO FROM  CI_PERIODO_CONTA  WHERE CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @ano_mes) =  @k_cerrado
  BEGIN
      SET  @pBError   =  @k_verdadero
      SET  @pError    =  'El periodo Contable se encuentra Cerrado' 
	  SET  @pMsgError = @pError
  END

END    
  
  
