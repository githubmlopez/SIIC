USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
--------------------------------------------------------------------------------------------
-- Se obtiene información referente a otras posibles opciones de facturas para conciliar  --
-- el movimiento bancario, por umbral o monto exacto sin importar la chequera             --
-- Opción : OTROS en la pantalla de conciliación                                          --
--------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcP2')
BEGIN
  DROP  PROCEDURE spObtConcP2
END
GO

--EXEC spObtConcP2 1,'CU','MARIO','SIIC','202006',203,1,1,21924.00,10001,' ',0,' ',' '
CREATE PROCEDURE [dbo].[spObtConcP2]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),																												
@pFolioExe      int,
@pIdTarea       numeric(9),
@pImporte       numeric(16,2),
@pIdConciliaCxc int,
@pRefEmpresa    varchar(50),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  SET  @pBError    =  NULL
  SET  @pError     =  NULL      
  SET  @pMsgError  =  NULL   
  

  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @umbral            numeric(16,2)

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_umbral          varchar(10) =  'UMBFACT',
		   @k_pref_ref        varchar(3)  =  'PR:'

DECLARE    @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion         date,
		   @cve_chequera        varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2)
  
SET  @umbral  =  (SELECT VALOR_NUMERICO  FROM  CI_PARAMETRO  WHERE
     CVE_EMPRESA    =  @pCveEmpresa  AND
	 CVE_PARAMETRO  =  @k_umbral)	   
 
---------------------------------------------------------------------------------------
--  Obtiene las facturas candidatas en base al umbral definido                       --
---------------------------------------------------------------------------------------

  SELECT @pCveEmpresa AS CVE_EMPRESA, f.SERIE_CTE, f.FOLIO_CTE, f.F_OPERACION, f.CVE_CHEQUERA, c.NOM_CLIENTE, f.IMP_F_NETO, f.TX_NOTA, @pRefEmpresa AS REF_EMPRESA, ID_CONCILIA_CXC
  FROM   CI_CUENTA_X_COBRAR f, CI_CLIENTE c
  WHERE  f.ID_CLIENTE                   =  c.ID_CLIENTE     AND  
		 f.CVE_EMPRESA                  =  c.CVE_EMPRESA    AND
		 f.CVE_EMPRESA                  =  @pCveEmpresa     AND
		 f.SIT_CONCILIA_CXC             =  @k_no_concilia   AND
		 f.SIT_TRANSACCION             <>  @k_cancelado     AND
		 f.ID_CONCILIA_CXC             <>  @pIdConciliaCxc  AND
	   ((ABS(f.IMP_F_NETO - @pImporte) <=  @umbral)         OR
		(@k_pref_ref + f.SERIE_CTE  + CONVERT(varchar(10), f.FOLIO_CTE)  =   
		 @pRefEmpresa))         

END
