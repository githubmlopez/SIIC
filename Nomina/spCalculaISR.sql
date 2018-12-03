USE [ADNOMINA01]
GO
/****** Calcula ISR en base a percepciones ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalculaISR] (@pPercepciones    numeric(18,2),
                                       @pIsr             numeric(16,2) OUT,
									   @pSubsidio        numeric(16,2) OUT)
AS
BEGIN
  DECLARE  @k_isr              varchar(2)     =  'IM',
           @k_subsidio         varchar(2)     =  'SB',
           @k_verdadero        bit            =  1,
		   @k_falso            bit            =  0

  SELECT  @pIsr = ((@pPercepciones - i.IMP_LIM_INFER) * (i.PJE_S_EXCEDENTE / 100)) + i.IMP_CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLE  =  @k_isr  


  SELECT  @pSubsidio = @imp_isr - i.CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLE  =  @k_subsidio  

END

