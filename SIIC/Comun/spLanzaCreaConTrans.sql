USE [ADMON01]
GO

--exec spTranFacturacion 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spLanzaCreaConTrans
  @pIdProceso         numeric(9),
  @pIdTarea           numeric(9),
  @pCveEmpresa        varchar(4),  
  @pAnoMes            varchar(6),
  @pIdTransaccion     int,
  @pCveOperCont       varchar(4),
  @pImbPrutoP         numeric(16,2),
  @pImpIvaP           numeric(16,2),
  @pImpNetoP          numeric(16,2),
  @pImpCompP          numeric(16,2),
  @pIMBPrutoD         numeric(16,2),
  @pIimpIvaD          numeric(16,2),
  @pImpNetoD          numeric(16,2),
  @pCtaContable       varchar(30),
  @pCtaContableComp   varchar(30),
  @pCtaContableIng    varchar(30),
  @pCtaContableIva    varchar(30),
  @pTipoCambio        numeric(8,4),
  @pDepartamento      varchar(50),
  @pProyecto          varchar(50),
  @pConc_movimiento   varchar(400),
  @pError             varchar(100) OUT,
  @pMsgError          varchar(400) OUT

AS
BEGIN
  DECLARE   
  @vector_cpto        varchar(20)
  DECLARE             
  @k_verdadero        varchar(1) =  1,
  @k_falso            varchar(1) =  0,
  @k_imp_bruto_p      varchar(4) =  'IMBP',
  @k_imp_iva_p        varchar(4) =  'IMIP',
  @k_imp_neto_p       varchar(4) =  'IMNP',
  @k_imp_comp_p       varchar(4) =  'IMCP',
  @k_imp_bruto_d      varchar(4) =  'IMBD',
  @k_imp_iva_d        varchar(4) =  'IMID',
  @k_imp_neto_d       varchar(4) =  'IMND',
  @k_cta_contable     varchar(4) =  'CTCO',
  @k_cta_cont_comp    varchar(4) =  'CTCM',
  @k_cta_cont_ing     varchar(4) =  'CTIN',
  @k_cta_cont_iva     varchar(4) =  'CTIV',
  @k_tipo_cambio      varchar(4) =  'TCAM',
  @k_departamento     varchar(4) =  'DPTO',
  @k_proyecto         varchar(4) =  'PROY',
  @k_concep_movto     varchar(4) =  'CPTO'

  SELECT  @vector_cpto = VECTOR_CPTO  FROM CI_CAT_TRANSACCION WHERE CVE_EMPRESA    =  @pCveEmpresa  AND
                                                                    CVE_OPER_CONT  =  @pCveOperCont

  IF  SUBSTRING(@vector_cpto,1,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_bruto_p, @pImbPrutoP, ' ', @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,2,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont,@k_imp_iva_p, @pImpIvaP, ' ', @pError, @pMsgError 
  END

  IF  SUBSTRING(@vector_cpto,3,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_neto_p, @pImpNetoP, ' ', @pError, @pMsgError 
  END

  IF  SUBSTRING(@vector_cpto,4,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_comp_p, @pImpCompP, ' ', @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,5,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_bruto_d, @pImbPrutoD, ' ', @pError, @pMsgError 
  END

  IF  SUBSTRING(@vector_cpto,6,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_iva_d , @pIimpIvaD, ' ', @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,7,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_imp_neto_d , @pImpNetoD, ' ', @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,8,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_cta_contable, 0, @pCtaContable, @pError, @pMsgError 
  END

  IF  SUBSTRING(@vector_cpto,9,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_cta_cont_comp, 0, @pCtaContableComp, @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,10,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_cta_cont_ing, 0, @pCtaContableIng, @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,11,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_cta_cont_iva, 0, @pCtaContableIva, @pError, @pMsgError 
  END

  IF  SUBSTRING(@vector_cpto,12,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_tipo_cambio, @pTipoCambio, ' ', @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,13,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_departamento, 0, @pDepartamento, @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,14,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_proyecto, 0, @pProyecto, @pError, @pMsgError
  END

  IF  SUBSTRING(@vector_cpto,15,1)  =  @k_verdadero
  BEGIN
    EXEC spCreaConcepTrans @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @pIdTransaccion,
	                       @pCveOperCont, @k_concep_movto, 0, @pConc_movimiento, @pError, @pMsgError
  END
END