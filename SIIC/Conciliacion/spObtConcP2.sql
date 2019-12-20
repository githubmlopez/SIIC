USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcP2')
BEGIN
  DROP  PROCEDURE spObtConcP2
END
GO

--EXEC spObtConcP2 'CU','MARIO','201903',135,1, 
CREATE PROCEDURE [dbo].[spObtConcP2]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pImporte         numeric(16,2),
@pSerie           varchar(6),
@pIdCxC           int,
@pRefEmpresa      varchar(50),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
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

  
  SET  @umbral  =  (SELECT VALOR_NUMERICO  FROM  CI_PARAMETRO  WHERE  CVE_PARAMETRO  =  @k_umbral)	   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
--  INSERT @TFactura  (CVE_EMPRESA, SERIE, ID_CXC, F_OPERACION, CVE_CHEQUERA, NOM_CLIENTE, IMP_F_NETO)  
  SELECT @pCveEmpresa, f.SERIE, f.ID_CXC, f.F_OPERACION, f.CVE_CHEQUERA, c.NOM_CLIENTE, f.IMP_F_NETO, f.TX_NOTA
  FROM   CI_FACTURA f, CI_VENTA v, CI_CLIENTE c
  WHERE  f.ID_VENTA                     =  v.ID_VENTA       AND
         v.ID_CLIENTE                   =  c.ID_CLIENTE     AND  
		 f.SIT_CONCILIA_CXC             =  @k_no_concilia   AND
		 f.SIT_TRANSACCION             <>  @k_cancelado     AND
		 f.serie  + CONVERT(varchar(10), f.id_cxc)  <>
         @pSerie  + CONVERT(varchar(10), @pIdCxC)           AND
	   ((ABS(f.IMP_F_NETO - @pImporte) <=  @umbral)         OR
		(@k_pref_ref + f.serie  + CONVERT(varchar(10), f.id_cxc)  <>    
		 @pRefEmpresa))         

END
