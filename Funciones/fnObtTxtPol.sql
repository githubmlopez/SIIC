ALTER FUNCTION fnObtTxtPol (@pCveEmpresa varchar(4), @pSerie varchar(6), @pIdCxC int, @pIdItem int)
RETURNS varchar(200)
-- WITH EXECUTE AS CALLER
AS
BEGIN

  DECLARE @txt_item  VARCHAR(200)

  IF EXISTS (SELECT 1 FROM CI_SEG_RENOVACION i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                     i.ID_CXC  =  @pIdCxC and  i.ID_ITEM     = @pIdItem)
  BEGIN
      SET @txt_item = (SELECT TX_NOTA FROM CI_SEG_RENOVACION i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                          i.ID_CXC  =  @pIdCxC and  i.ID_ITEM     = @pIdItem)
  END
  ELSE
  BEGIN
      SET @txt_item = ' '     
  END                                                
  RETURN @txt_item
END

