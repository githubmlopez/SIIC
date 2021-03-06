USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnobtFolio')
BEGIN
  DROP  FUNCTION fnobtFolio
END
GO
CREATE FUNCTION [dbo].[fnobtFolio] 
(
@pCveFolio     varchar(4)
)
RETURNS int						  
AS
BEGIN

  DECLARE  @folio            int

  SET @folio = (SELECT NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @pCveFolio )

  EXEC spIncFolio @pCveFolio

  RETURN(@folio)
END

