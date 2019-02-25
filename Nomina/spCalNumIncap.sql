USE [ADNOMINA01]
GO
/****** Calcula incapacidades por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalNumIncap')
BEGIN
  DROP  PROCEDURE spCalNumIncap
END
GO
SET NOCOUNT ON
GO

-- EXEC spCalNumIncap 1,1,1,'CU','NOMINA','S','201801',1,0,' ',' '
CREATE PROCEDURE [dbo].[spCalNumIncap] 
(
@pIdProceso       int,
@pIdTarea         int,
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pDiasIncap       int OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE  @ano_per_ini   varchar(6)  =  ' ',
           @ano_per_fin   varchar(6)  =  ' ',
           @num_dias_p1   int         =  0,
		   @num_dias_pn   int         =  0,
		   @num_registros int         =  0  

  DECLARE  @k_verdadero   bit         =  1

  SELECT  @ano_per_ini  =  ANO_PERIODO_INI,
          @ano_per_fin  =  ANO_PERIODO_FIN,
          @num_dias_p1  =  NUM_DIAS_P1,
		  @num_dias_pn   = NUM_DIAS_PN
  FROM    NO_AUSENCIA_PER a, NO_MOT_AUSENCIA m
  WHERE
  a.ID_CLIENTE       = @pIdCliente      AND
  a.CVE_EMPRESA      = @pCveEmpresa     AND
  a.ID_EMPLEADO      = @pIdEmpleado     AND
  a.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  a.ID_CLIENTE       = m.ID_CLIENTE     AND
  a.CVE_EMPRESA      = m.CVE_EMPRESA    AND
  a.ID_MOTIVO        = m.ID_MOTIVO      AND
  m.B_INCAPACIDAD    = @k_verdadero     AND
  @pAnoPeriodo BETWEEN  a.ANO_PERIODO_INI AND a.ANO_PERIODO_FIN
  SET @num_registros = @@ROWCOUNT

  IF  @num_registros > 0
  BEGIN
    SET  @num_dias_p1  =  ISNULL(@num_dias_p1,0)
    SET  @num_dias_pn  =  ISNULL(@num_dias_pn,0)
    IF  @pAnoPeriodo = @ano_per_ini
    BEGIN
      SET  @pDiasIncap  =  @num_dias_p1
    END
    ELSE
    BEGIN
      IF  @pAnoPeriodo = @ano_per_fin
      BEGIN
	    SET  @pDiasIncap  =  @num_dias_pn
	  END
	  ELSE
	  BEGIN
        SET  @pDiasIncap  =  ISNULL((SELECT  p.NUM_DIAS_PERIODO  FROM  NO_PERIODO p WHERE 
	                          p.ID_CLIENTE       = @pIdCliente      AND
                              p.CVE_EMPRESA      = @pCveEmpresa     AND
                              p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
                              p.ANO_PERIODO      = @pAnoPeriodo),999999)
	  END 
    END
  END
--  SELECT CONVERT(VARCHAR(18),@pDiasIncap)
END