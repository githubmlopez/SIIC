USE ADNOMINA01
GO

CREATE FUNCTION fnObtAnoPerAnt 
(@pAnoMes varchar(6))
RETURNS varchar(6)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @ano               int,
		   @periodo           int

  SET  @ano      =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @periodo  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2) - 1)
 
  RETURN dbo.fnArmaAnoMes (@ano, @periodo)
END

