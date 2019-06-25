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
-- EXEC spCalculaISR 1,1,'MARIO',1,'CU','NOMINA','S','201901',1,2000,'MI','MS',0,0,' ',' '
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
@pImpCalIsr       numeric(16,2),
@pCveTablaIsr     varchar(2),
@pCveTablaSub     varchar(2),
@pImpIsr          numeric(16,2) OUT,
@pImpSubsidio     numeric(16,2) OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
--  SELECT 'ISR'

  DECLARE  @k_verdadero        bit            =  1,
		   @k_falso            bit            =  0
		      
  SELECT  @pImpIsr = ((@pImpCalIsr - i.IMP_LIM_INFER) * (i.PJE_S_EXCEDENTE / 100)) +
  i.IMP_CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pImpCalIsr  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLA  =  @pCveTablaIsr 

  SET @pImpIsr = ISNULL(@pImpIsr,0)

  SELECT  @pImpSubsidio = i.IMP_CUOTA_FIJA
  FROM    NO_TABLA_ISR  i WHERE
  @pImpCalIsr  BETWEEN i.IMP_LIM_INFER  AND  i.IMP_LIM_SUPER  AND
  i.CVE_TIPO_TABLA  =  @pCveTablaSub

  SET @pImpSubsidio = ISNULL(@pImpSubsidio,0)

  --SELECT 'ISR ' + CONVERT(VARCHAR(18),@pImpIsr)
  --SELECT 'SUB ' + CONVERT(VARCHAR(18),@pImpSubsidio)


END

