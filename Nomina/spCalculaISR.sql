USE [ADNOMINA01]
GO
/****** Calcula ISR en base a percepciones ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalculaISR')
BEGIN
  DROP  PROCEDURE spCalculaISR
END
GO
-- EXEC spCalculaISR 1,1,'MARIO',1,'CU','NOMINA','S','201801',1,9500,0,0,' ',' '
CREATE PROCEDURE [dbo].[spCalculaISR] 
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
@pPercepciones    numeric(16,2),
@pPercMensual     numeric(16,2),
@pIsrMensual      numeric(16,2),
@pSubMensual      numeric(16,2),
@pBFinMes         bit,
@pIsr             numeric(16,2) OUT,
@pSubsidio        numeric(16,2) OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
  SELECT 'ISR'
  DECLARE  @imp_isr_per        numeric(16,2)  =  0,
           @imp_sub_per        numeric(16,2)  =  0,
		   @imp_isr_men        numeric(16,2)  =  0,
  		   @imp_sub_men        numeric(16,2)  =  0

  DECLARE  @k_isr              varchar(2)     =  'MI',
           @k_subsidio         varchar(2)     =  'MS',
           @k_verdadero        bit            =  1,
		   @k_falso            bit            =  0

  IF  @pBFinMes  =  @k_falso
  BEGIN
   (SELECT  @imp_isr_per = ((@pPercepciones - i.IMP_LIM_INFER) * (i.PJE_S_EXCEDENTE / 100)) +
    i.IMP_CUOTA_FIJA
    FROM    NO_TABLA_ISR  i WHERE
    @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
    i.CVE_TIPO_TABLA  =  @k_isr) 
    SET @imp_isr_per = ISNULL(@pIsr,0)

    SELECT  @imp_sub_per = i.IMP_CUOTA_FIJA
    FROM    NO_TABLA_ISR  i WHERE
    @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
    i.CVE_TIPO_TABLA  =  @k_subsidio  

    SET @imp_sub_per = ISNULL(@pSubsidio,0)
  END
  ELSE
  BEGIN
   (SELECT  @imp_isr_men = ((@pPercMensual - i.IMP_LIM_INFER) * (i.PJE_S_EXCEDENTE / 100)) + i.IMP_CUOTA_FIJA
    FROM    NO_TABLA_ISR  i WHERE
    @pPercMensual  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
    i.CVE_TIPO_TABLA  =  @k_isr) 

    SET @imp_isr_men = ISNULL(@pIsr,0)

    SELECT  @imp_sub_men = i.IMP_CUOTA_FIJA
    FROM    NO_TABLA_ISR  i WHERE
    @pPercMensual  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
    i.CVE_TIPO_TABLA  =  @k_subsidio  

    SET @imp_sub_per = ISNULL(@pSubsidio,0)

-- AJUSTE MENSUAL DE IMPUESTO 

    IF  @imp_isr_men > (@pIsrMensual + @imp_isr_per)
    BEGIN
      SET  @pIsr  =  @imp_isr_men - (@pIsrMensual + @imp_isr_per)
    END
    ELSE
    BEGIN
      SET  @pIsr  =  @imp_isr_men - (@pIsrMensual + @imp_isr_per)
    END

    IF  @imp_sub_per > (@pSubMensual + @imp_sub_per)
    BEGIN
      SET  @pSubsidio  =  @imp_sub_per - (@pSubMensual + @imp_sub_per)
    END
    ELSE
    BEGIN
      SET  @pSubsidio  =  @imp_sub_per - (@pSubMensual + @imp_sub_per)
    END
  END

  UPDATE NO_INF_EMP_PER  SET IMP_PER_ISR = @pIsr, IMP_PER_SUB = @pSubsidio WHERE
  ID_CLIENTE       =  @pIdCliente      AND
  CVE_EMPRESA      =  @pCveEmpresa     AND
  CVE_TIPO_NOMINA  =  @pCveTipoNomina  AND
  ANO_PERIODO      =  @pAnoPeriodo     AND
  ID_EMPLEADO      =  @pIdEmpleado

--  SELECT CONVERT(VARCHAR(18),@pIsr)
--  SELECT CONVERT(VARCHAR(18),@pSubsidio)

END

