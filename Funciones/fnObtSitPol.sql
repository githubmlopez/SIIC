USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtSitPol]    Script Date: 24/01/2019 02:08:59 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnObtSitPol] (@pCveEmpresa varchar(4), @pSerie varchar(6), @pIdCxC int, @pIdItem int)
RETURNS varchar(1)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  DECLARE @sit_item  VARCHAR(1)

  IF EXISTS (SELECT 1 FROM CI_SEG_RENOVACION i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                     i.ID_CXC  =  @pIdCxC and  i.ID_ITEM     = @pIdItem)
  BEGIN
      SET @sit_item = (SELECT CVE_SITUACION FROM CI_SEG_RENOVACION i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                          i.ID_CXC  =  @pIdCxC and  i.ID_ITEM     = @pIdItem)
  END
  ELSE
  BEGIN
      SET @sit_item = ' '     
  END                                                
  RETURN @sit_item
END

