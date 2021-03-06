USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtTipoCamb]    Script Date: 12/03/2018 03:55:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnObtError] (@pNumError int, @pIdioma varchar(1))
RETURNS varchar(80)						  
AS
BEGIN
  RETURN(SELECT DESC_ERROR FROM FC_MSG_ERROR WHERE NUM_ERROR  = @pNumError  AND
                                                   CVE_IDIOMA = @pIdioma)
END

