USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-------------------------------------------------------------------------------------------------
-- Presenta todas las facturas sin considerar parametros para hacer match con los movimientos  --
-- Bancarios                                                                                   --
-- Opción: TODOS en la pantalla de conciliación                                                --
-------------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcP3')
BEGIN
  DROP  PROCEDURE spObtConcP3
END
GO
--EXEC spObtConcP1 3,'EGG','MARIO','SIIC','202006',203,1,1,'MDB437',0,' ',' '
--EXEC spObtConcP3 1,'CU','MARIO','SIIC','202006',203,1,1,335,0,' ',' '
CREATE PROCEDURE [dbo].[spObtConcP3]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pIdConciliaCxc int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  SET @pBError    =  NULL
  SET @pError     =  NULL
  SET @pMsgError  =  NULL  

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

-------------------------------------------------------------------------------
-- Obtiene información de todas las facturas sin validar monto ni umbral     --
-------------------------------------------------------------------------------

  SELECT @pCveEmpresa AS CVE_EMPRESA, f.SERIE_CTE, f.FOLIO_CTE, f.F_OPERACION, f.CVE_CHEQUERA, c.NOM_CLIENTE, f.IMP_F_NETO, f.TX_NOTA, CVE_F_MONEDA, ID_CONCILIA_CXC
  FROM   CI_CUENTA_X_COBRAR f, CI_CLIENTE c
  WHERE  f.ID_CLIENTE                   =  c.ID_CLIENTE     AND 
         f.CVE_EMPRESA                  =  c.CVE_EMPRESA    AND
         f.CVE_EMPRESA                  =  @pCveEmpresa     AND
		 f.SIT_CONCILIA_CXC             =  @k_no_concilia   AND
		 f.SIT_TRANSACCION             <>  @k_cancelado     AND
		 f.ID_CONCILIA_CXC             <>  @pIdConciliaCxc            

END
