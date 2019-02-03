USE ADMON01
GO

CREATE FUNCTION fnObtAnoMesAnt 
(@pAnoMes varchar(6))
RETURNS varchar(6)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @ano               int,
		   @mes               int

  DECLARE  @k_diciembre       int         =  12,
           @k_enero           int         =  01,
           @k_falso           bit         =  0,
           @k_verdadero       bit         =  1,
		   @k_error           varchar(1)  =  'E'

  SET  @ano  =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @mes  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2))

  IF  @mes  <>  @k_enero
  BEGIN
    SET  @mes  =  @mes - 1
  END
  ELSE
  BEGIN
    SET  @ano  =  @ano  -  1
	SET  @mes  =  @k_diciembre
  END
  RETURN dbo.fnArmaAnoMes (@ano, @mes)
END

