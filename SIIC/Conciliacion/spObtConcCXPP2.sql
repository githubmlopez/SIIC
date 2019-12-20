USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcCXPP2')
BEGIN
  DROP  PROCEDURE spObtConcCXPP2
END
GO

--EXEC spObtConcCXPP2 'CU','MARIO','201903',135,1, 
CREATE PROCEDURE [dbo].[spObtConcCXPP2]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pImporte         numeric(16,2),
@pIdCxP           int,
@pIdPago          int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @umbral            numeric(16,2)

  DECLARE  @k_normal          varchar(1)  =  'N',
           @k_pago            varchar(1)  =  'P',
           @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_umbral          varchar(10) =  'UMBCXP'

DECLARE    @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion         date,
		   @cve_chequera        varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2)

  
  SET  @umbral  =  (SELECT VALOR_NUMERICO  FROM  CI_PARAMETRO  WHERE  CVE_PARAMETRO  =  @k_umbral)	   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  SELECT @pCveEmpresa, c.SERIE_PROV, c.ID_FOLIO_PROV, c.F_CAPTURA, c.CVE_CHEQUERA, p.NOM_PROVEEDOR, c.IMP_NETO, c.TX_NOTA
  FROM   CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p
  WHERE  c.ID_PROVEEDOR                =   p.ID_PROVEEDOR   AND  
		 c.SIT_CONCILIA_CXP            =   @k_no_concilia   AND
		 c.SIT_C_X_P                  <>   @k_cancelado     AND
		 c.ANOMES_CONT                 =   @pAnoPeriodo     AND
         c.ID_CXP                     <>   @pIdCxP          AND 
	     ABS(c.IMP_NETO - @pImporte)  <=   @umbral          AND
		 c.ID_CXP                     <>   @id_cxc          AND
		 NOT EXISTS(
  SELECT 1
  FROM   CI_PAGO p, CI_PAGO_CXP pc
  WHERE  p.ANOMES_CONT                =    @pAnoPeriodo     AND
         p.CVE_EMPRESA                =    pc.CVE_EMPRESA   AND
		 p.ID_PAGO                    =    pc.ID_PAGO       AND
		 pc.ID_CXP                   <>   c.ID_CXP)   
  UNION
  SELECT @pCveEmpresa, ' ', ' ', p.F_PAGO, p.CVE_CHEQUERA, p.BENEF_PAGO, p.IMP_NETO, p.TX_NOTA
  FROM   CI_PAGO p
  WHERE  ABS(p.IMP_NETO - @pImporte)  <=   @umbral          AND
		 p.ID_PAGO                    <>   @pIdPago         AND
		 p.ANOMES_CONT                =    @pAnoPeriodo     
END
