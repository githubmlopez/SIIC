USE [ADNOMINA01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnVerMesCont')
BEGIN
  DROP  FUNCTION fnVerMesCont
END
GO
CREATE FUNCTION [dbo].[fnVerMesCont] 
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveTipoNomina varchar(2),
@pAnoPeriodoI   varchar(6),
@pAnoPeriodo    varchar(6)
)
RETURNS bit						  
AS
BEGIN
  DECLARE  @mes_i        varchar(6)  =  ' ',
           @mes_p        varchar(6)  =  ' ',
		   @mes_valido   bit         =  0
  
  DECLARE  @k_verdadero  bit  =  '1',
           @k_falso      bit  =  '0'

  SELECT   @mes_i =  CVE_MES  FROM  NO_PERIODO  WHERE
           ID_CLIENTE       =  @pIdCliente     AND
		   CVE_EMPRESA      =  @pCveEmpresa    AND
		   CVE_TIPO_NOMINA  =  @pCveTipoNomina AND
		   ANO_PERIODO      =  @pAnoPeriodoI

  SELECT   @mes_p =  CVE_MES  FROM  NO_PERIODO  WHERE
           ID_CLIENTE       =  @pIdCliente     AND
		   CVE_EMPRESA      =  @pCveEmpresa    AND
		   CVE_TIPO_NOMINA  =  @pCveTipoNomina AND
		   ANO_PERIODO      =  @pAnoPeriodo
		   
  IF  @mes_i  =  @mes_p
  BEGIN
    SET  @mes_valido  =  @k_verdadero
  END

  RETURN(@mes_valido) 
END

