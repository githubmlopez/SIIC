 CREATE FUNCTION fnArmaAnoMes (@pano int, @pMes int)
RETURNS varchar(6)
-- WITH EXECUTE AS CALLER
AS
BEGIN
   return(CONVERT(varchar(4),@pAno) +  replicate ('0',(02 - len(@pMes))) + convert(varchar, @pMes))
END


