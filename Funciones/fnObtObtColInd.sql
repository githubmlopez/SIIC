USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnobtObtColInd')
BEGIN
  DROP  FUNCTION fnobtObtColInd
END
GO
CREATE FUNCTION [dbo].[fnobtObtColInd] 
(
@pIdCliente  int,
@pCveEmpresa varchar(4),
@pTipoInfo   int,
@pIdFormato  int,
@pIdBloque   int,
@pAnoPeriodo varchar(6),
@pSecuencia  int
)
RETURNS varchar(max)						  
AS
BEGIN
  RETURN 
  (SELECT c.VAL_DATO 
  FROM CARGADOR.dbo.FC_CARGA_IND_DATO c
  WHERE
  ID_CLIENTE       = @pIdCliente    AND
  CVE_EMPRESA      = @pCveEmpresa   AND
  TIPO_INFORMACION = @pTipoInfo     AND
  ID_FORMATO       = @pIdFormato    AND
  PERIODO          = @pAnoPeriodo   AND
  SECUENCIA        = @pSecuencia)
END

