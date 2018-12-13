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
@pCveUsuario      varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pPercepciones    numeric(18,2),
@pIsr             numeric(16,2) OUT,
@pSubsidio        numeric(16,2) OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
  DECLARE  @k_isr              varchar(2)     =  'MI',
           @k_subsidio         varchar(2)     =  'MS',
           @k_verdadero        bit            =  1,
		   @k_falso            bit            =  0

  (SELECT  @pIsr = ((@pPercepciones - i.IMP_LIM_INFER) * (i.PJE_S_EXCEDENTE / 100)) + i.IMP_CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLA  =  @k_isr) 

  SET @pIsr = ISNULL(@pIsr,0)

  SELECT  @pSubsidio = i.IMP_CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pPercepciones  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLA  =  @k_subsidio  

  SET @pSubsidio = ISNULL(@pSubsidio,0)

--  SELECT CONVERT(VARCHAR(18),@pIsr)
--  SELECT CONVERT(VARCHAR(18),@pSubsidio)

END

