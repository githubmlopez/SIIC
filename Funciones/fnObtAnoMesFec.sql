USE ADMON01
GO

CREATE FUNCTION fnObtAnoMesFec 
(@pFecha date)
RETURNS varchar(6)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @ano               int,
		   @mes               int

  SET  @ano  =  YEAR(@pFecha)
  SET  @mes  =  MONTH(@pFecha)

  RETURN dbo.fnArmaAnoMes (@ano, @mes)
END

