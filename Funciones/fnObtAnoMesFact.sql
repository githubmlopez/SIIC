USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtTipoCamb]    Script Date: 13/03/2019 12:14:55 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter FUNCTION [dbo].[fnObtAnoMesFact] (@pAnoMes varchar(6), @pSitTransaccion varchar(2), @fOperacion date)
RETURNS varchar(6)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @ano_mes  varchar(6)

  DECLARE  @k_cancelada  varchar(1)  =  'C'

  IF  @pSitTransaccion  =  @k_cancelada
  BEGIN
    SET @ano_mes = dbo.fnArmaAnoMes (YEAR(@fOperacion), MONTH(@fOperacion))
  END
  ELSE
  BEGIN
    SET @ano_mes =  @pAnoMes
  END
  RETURN @ano_mes
END

