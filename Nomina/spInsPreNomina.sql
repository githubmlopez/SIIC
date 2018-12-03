USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spInsPreNomina] (@pAnoPeriodo     varchar(6),
                                         @pIdCliente      int,
                                         @pCveEmpresa     varchar(4),
                                         @pCveTipoNomina  varchar(2) ,
                                         @pIdEmpleado     int,
                                         @pCveConcepto    varchar(4) ,
                                         @pImpConcepto    numeric(16,2),
                                         @pImpAjuste      numeric(16,2),
                                         @pDiasAjuste     int ,
                                         @pGpoTransaccion int ,
                                         @pTxtNota        varchar(200))  

AS
BEGIN

  INSERT INTO NO_PRE_NOMINA 
 (ANO_PERIODO,
  ID_CLIENTE,
  CVE_EMPRESA,
  CVE_TIPO_NOMINA,
  ID_EMPLEADO,
  CVE_CONCEPTO,
  IMP_CONCEPTO,
  IMP_AJUSTE,
  DIAS_AJUSTE,
  GPO_TRANSACCION,
  TXT_NOTA)  VALUES
 (@pAnoPeriodo,
  @pIdCliente,
  @pCveEmpresa,
  @pCveTipoNomina,
  @pIdEmpleado,
  @pCveConcepto,
  @pImpConcepto,
  @pImpAjuste,
  @pDiasAjuste,
  @pGpoTransaccion,
  @pTxtNota)  

END