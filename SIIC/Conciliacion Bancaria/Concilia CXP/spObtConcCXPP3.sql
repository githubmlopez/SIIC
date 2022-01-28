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

--EXEC spObtConcCXPP3 1,'CU','MARIO','SIIC','201903',203,1,1,43,1,0,' ',' '
CREATE PROCEDURE [dbo].[spObtConcCXPP3]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pIdCxP         int,
@pIdPago        int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @umbral            numeric(16,2)

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_pago_l          varchar(4)  =  'PAGO',
           @k_pago            varchar(1)  =  'P'

  DECLARE  @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion         date,
		   @cve_chequera        varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2)
  
  SELECT @pCveEmpresa, SUBSTRING(c.SERIE_PROV + '-' +  FOLIO_PROV,1,20), c.F_CAPTURA, c.CVE_CHEQUERA, p.NOM_PROVEEDOR, c.IMP_NETO,
         c.TX_NOTA, ' ', C.ID_CXP
  FROM   CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p
  WHERE  c.ID_PROVEEDOR                =   p.ID_PROVEEDOR   AND  
		 c.SIT_CONCILIA_CXP            =   @k_no_concilia   AND
		 c.SIT_C_X_P                  <>   @k_cancelado     AND
--		 c.ANOMES_CONT                 =   @pAnoPeriodo     AND
 		 c.ID_CXP                     <>   @pIdCxP          AND
		 NOT EXISTS(
  SELECT 1
  FROM   CI_PAGO p, CI_PAGO_CXP pc
  WHERE  p.CVE_EMPRESA                =    @pCveEmpresa     AND
         p.ANOMES_CONT                =    @pAnoPeriodo     AND
         p.CVE_EMPRESA                =    pc.CVE_EMPRESA   AND
		 p.ID_PAGO                    =    pc.ID_PAGO       AND
		 pc.ID_CXP                    =    @pIdCxP)   
  UNION
  SELECT @pCveEmpresa, @k_pago_l, p.F_PAGO, p.CVE_CHEQUERA, p.BENEF_PAGO, p.IMP_NETO, p.TX_NOTA, @k_pago, P.ID_PAGO
  FROM   CI_PAGO p		WHERE
		 p.ID_PAGO                    <>   @pIdPago         AND
		 p.ANOMES_CONT                =    @pAnoPeriodo     
END
