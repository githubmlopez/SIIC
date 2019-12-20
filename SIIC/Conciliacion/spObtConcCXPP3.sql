USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcCXPP3')
BEGIN
  DROP  PROCEDURE spObtConcCXPP3
END
GO

--EXEC  spObtConcP3 'CU','MARIO','201903',135,1,'CUM','335',' ',' '
CREATE PROCEDURE [dbo].[spObtConcCXPP3]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pSerie           varchar(6),
@pIdCxP           int,
@pIdPago          int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @umbral            numeric(16,2)

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA'

  DECLARE  @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion         date,
		   @cve_chequera        varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2)
  
  SELECT @pCveEmpresa, c.SERIE_PROV, c.ID_FOLIO_PROV, c.F_CAPTURA, c.CVE_CHEQUERA, p.NOM_PROVEEDOR, c.IMP_NETO, c.TX_NOTA
  FROM   CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p
  WHERE  c.ID_PROVEEDOR                =   p.ID_PROVEEDOR   AND  
		 c.SIT_CONCILIA_CXP            =   @k_no_concilia   AND
		 c.SIT_C_X_P                  <>   @k_cancelado     AND
		 c.ANOMES_CONT                 =   @pAnoPeriodo     AND
         c.ID_CXP                     <>   @pIdCxP           
  UNION
  SELECT @pCveEmpresa, ' ', ' ', p.F_PAGO, p.CVE_CHEQUERA, p.BENEF_PAGO, p.IMP_NETO, p.TX_NOTA
  FROM   CI_PAGO p
  WHERE  p.ID_PAGO                    <>   @pIdPago         AND
		 p.ANOMES_CONT                =    @pAnoPeriodo  
END
