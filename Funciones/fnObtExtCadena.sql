USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnobtExtCadena')
BEGIN
  DROP  FUNCTION fnobExtCadena
END
GO
CREATE FUNCTION [dbo].[fnobtExtCadena] 
(

@pCadena     varchar(250),
@pValor      varchar(30),
@pPosMas     int,
@pNumPosic   int
)
RETURNS varchar(250)						  
AS
BEGIN
  RETURN 
  SUBSTRING(@pCadena,
  CHARINDEX(LTRIM(RTRIM(@pValor)),@pCadena) + LEN(@pValor)  + @pPosMas,
  @pNumPosic)
END

