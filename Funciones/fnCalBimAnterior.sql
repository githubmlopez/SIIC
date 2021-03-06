USE [ADNOMINA01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnCalBimAnterior')
BEGIN
  DROP  FUNCTION fnCalBimAnterior
END
GO
CREATE FUNCTION [dbo].[fnCalBimAnterior] 
(
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pCveTipoNomina  varchar(2),
@pAnoPeriodo     varchar(6)
)
RETURNS varchar (6)						  
AS
BEGIN
  DECLARE  @ano_bimestre       varchar(4)     =  ' ',
           @num_bimestre       varchar(2)     =  ' ',
           @cve_bim_ant        varchar(6)     =  ' '

  DECLARE  @k_prim_bim         varchar(2)     =  '01',
           @k_ult_bim          varchar(2)     =  '06'

  SELECT @ano_bimestre = SUBSTRING(p.CVE_BIMESTRE,1,4),@num_bimestre = SUBSTRING(p.CVE_BIMESTRE,5,2)
  FROM NO_PERIODO p  WHERE 
  p.ID_CLIENTE      = @pIdCliente      AND
  p.CVE_EMPRESA     = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  p.ANO_PERIODO     = @pAnoPeriodo      

  IF  @num_bimestre  =  @k_prim_bim
  BEGIN
    SET  @cve_bim_ant  =  CONVERT(VARCHAR(4),CONVERT(INT,@ano_bimestre) - 1)  +
	                      @k_ult_bim
  END
  ELSE
  BEGIN
    SET  @cve_bim_ant  =  @ano_bimestre  +
	replicate ('0',(02 - len(CONVERT(INT,@num_bimestre) -1))) + convert(varchar, CONVERT(INT,@num_bimestre -1))
  END
  RETURN(@cve_bim_ant)
END

