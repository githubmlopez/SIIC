USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcP3')
BEGIN
  DROP  PROCEDURE spObtConcP3
END
GO

--EXEC  spObtConcP3 'CU','MARIO','201903',135,1,'CUM','335',' ',' '
CREATE PROCEDURE [dbo].[spObtConcP3]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pSerie           varchar(6),
@pIdCxC           int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @umbral            numeric(16,2)

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA'

DECLARE    @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion         date,
		   @cve_chequera        varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2)
  
  SELECT @pCveEmpresa, f.SERIE, f.ID_CXC, f.F_OPERACION, f.CVE_CHEQUERA, c.NOM_CLIENTE, f.IMP_F_NETO, f.TX_NOTA
  FROM   CI_FACTURA f, CI_VENTA v, CI_CLIENTE c
  WHERE  f.ID_VENTA                     =  v.ID_VENTA       AND
         v.ID_CLIENTE                   =  c.ID_CLIENTE     AND  
		 f.SIT_CONCILIA_CXC             =  @k_no_concilia   AND
		 f.SIT_TRANSACCION             <>  @k_cancelado     AND
		 f.serie  + CONVERT(varchar(10), f.id_cxc)  <>
         @pSerie  + CONVERT(varchar(10), @pIdCxC)           

END
