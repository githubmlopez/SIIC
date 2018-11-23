CREATE FUNCTION fnObtSitPol (@pCveEmpresa varchr(4), @pCveSerie varchar(6), @pId_CxC int, @pIdItem int)
RETURNS varchar(1)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  IF EXISTS (SELECT 1 FROM CI_ITEM_C_X_C i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                 i.ID_CXC  =  i.pIdCxC and  i.ID_ITEM     = @pIdItem)
  BEGIN
      RETURN (SELECT 1 FROM CI_ITEM_C_X_C i WHERE i.CVE_EMPRESA = @pCveEmpresa and i.SERIE = @pSerie and
                                                  i.ID_CXC  =  i.pIdCxC and  i.ID_ITEM     = @pIdItem)
  BEGIN
  ELSE
  BEGIN
      RETURN ' '     
  END                                                
END

