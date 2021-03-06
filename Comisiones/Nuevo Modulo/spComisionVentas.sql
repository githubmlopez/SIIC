USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spLanzaComision]    Script Date: 06/11/2020 02:19:06 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spComisionVentas')
DROP PROCEDURE [dbo].[spComisionVentas]
GO
-- Exec spComisionVentas 'CU', 'MARIO, '202010', 0, 0,' ' ' '

CREATE PROCEDURE [dbo].[spComisionVentas] 
(
@pCveEmpresa varchar(4),
@pCveUsuario varchar(8),
@pAnoPeriodo varchar(6),
@pIdProceso  numeric(9),
@pIdTarea    numeric(9),
@pError      varchar(80) OUT,
@pMsgError   varchar(400) OUT
)
	
AS
BEGIN

/*  Declaración de Constantes  */

  DECLARE  @k_verdadero       bit        =  1,
           @k_falso           bit        =  0,
		   @k_poliza          varchar(4) = 'PO',
		   @k_f_default       date       = '1900-01-01',
		   @k_legado          varchar(6) = 'LEGACY',
		   @k_conciliado      varchar(2) = 'CC',
		   @k_error           varchar(1) = 'E',
		   @k_activo          varchar(2) = 'A',   
		   @k_abono           varchar(1) = 'A'   

         
  DECLARE  @NunRegistros  int = 0, 
		   @RowCount      int = 0,
		   @cve_producto  varchar(4),
		   @imp_abono     numeric(12,2),
           @imp_cargo     numeric(12,2)

  DECLARE  @serie             varchar(6),
           @id_cxc            int,
		   @id_item           int,
           @id_concilia_cxc   int,
		   @imp_bruto_item    numeric(12,2),
		   @imp_f_factura     numeric(12,2),
		   @cve_moneda        varchar(1),
		   @cve_subproducto   varchar(8) 

  DECLARE @TItem  TABLE 
 (
  RowID                     int IDENTITY(1,1),   
  SERIE                     varchar(6),
  ID_CXC                    int,
  ID_ITEM                   int,
  ID_CONCILIA_CXC           int,
  IMP_BRUTO_ITEM            numeric(12,2),
  IMP_F_BRUTO               numeric(12,2),
  CVE_SUBPRODUCTO           varchar(8),
  CVE_F_MONEDA              varchar(1)
 )        
 -----------------------------------------------------------------------------------------------------
-- Inicializa Tablas de actualización 
-----------------------------------------------------------------------------------------------------

DELETE VTA_CUPON_COMISION  WHERE CVE_EMPRESA = @pCveEmpresa  AND  ANO_MES  =  @pAnoPeriodo
 
DELETE VTA_FACT_PAGO       WHERE CVE_EMPRESA = @pCveEmpresa  AND  ANO_MES  =  @pAnoPeriodo

-----------------------------------------------------------------------------------------------------
-- Prepara información para proceso 
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Prorratea Pagos entre facturas (esto se hace por los casos en que existe mas de un pago para la 
-- factura) 
-----------------------------------------------------------------------------------------------------
  EXEC spProrrateaPago @pCveEmpresa, @pAnoPeriodo
-----------------------------------------------------------------------------------------------------
-- Obtiene las facturas que tienen pagos en el periodo (también se incluyen los cargos) 
-----------------------------------------------------------------------------------------------------
  EXEC spCalculaCargoAbono @pCveEmpresa, @pAnoPeriodo 
-----------------------------------------------------------------------------------------------------
		   
  DECLARE @TFactura  TABLE 
 (
  RowID                     int IDENTITY(1,1),   
  SERIE                     varchar(6),
  ID_CXC                    int,
  ID_CONCILIA_CXC           int,
  IMP_F_BRUTO               numeric(12,2),
  CVE_F_MONEDA              varchar(1)
 )   

  BEGIN TRY

  INSERT INTO @TFactura
 (SERIE, ID_CXC, ID_CONCILIA_CXC, IMP_F_BRUTO,CVE_F_MONEDA)
  SELECT  v.SERIE, v.ID_CXC, f.ID_CONCILIA_CXC, IMP_F_BRUTO, f.CVE_F_MONEDA
  FROM VTA_FACT_PAGO v, CI_FACTURA f
  WHERE 
  v.ANO_MES           =  @pAnoPeriodo        AND
  v.CVE_EMPRESA       =  @pCveEmpresa        AND
  v.CVE_EMPRESA       =  f.CVE_EMPRESA       AND 
  v.SERIE             =  f.SERIE             AND
  v.ID_CXC            =  f.ID_CXC            AND
  v.CVE_CARGO_ABONO   =  @k_abono
--  SELECT * FROM  @TFactura
----------------------------------------------------------------------------------------------------
-- Genera los colección de registros ITEMS que pagarán comisión 
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TItem
  SELECT i.SERIE, i.ID_CXC, i.ID_ITEM, ID_CONCILIA_CXC, i.IMP_BRUTO_ITEM, f.IMP_F_BRUTO, i.CVE_SUBPRODUCTO,
         f.CVE_F_MONEDA
  FROM   @TFactura f, CI_ITEM_C_X_C i
  WHERE   
--  join Factura - Item
  i.CVE_EMPRESA      = @pCveEmpresa                                        AND 
  i.SERIE            = f.SERIE                                             AND
  i.ID_CXC           = f.ID_CXC                                            AND
--  Verifica que el producto paga comision o mantenimiento
  EXISTS      (SELECT 1 FROM CI_SUBPRODUCTO s, CI_PRODUCTO p WHERE        
  i.CVE_SUBPRODUCTO  =  s.CVE_SUBPRODUCTO                                  AND
  s.CVE_PRODUCTO     =  p.CVE_PRODUCTO                                     AND
 (p.B_PAGA_COMISION  =  @k_verdadero or p.B_MANTENIMIENTO = @k_verdadero)) AND
--  Verifica que el vendedor del subproducto este habilitado para el pago de comisión  
  EXISTS(SELECT 1 FROM VTA_COMIS_ITEM vi, VTA_VENDEDOR v, VTA_TIPO_VENDEDOR t WHERE  
  i.CVE_EMPRESA        =  vi.CVE_EMPRESA                                   AND
  i.SERIE              =  vi.SERIE                                         AND
  i.ID_CXC             =  vi.ID_CXC                                        AND
  i.ID_ITEM            =  vi.ID_ITEM                                       AND
  vi.CVE_EMPRESA       =  v.CVE_EMPRESA                                    AND
  vi.CVE_VENDEDOR      =  v.CVE_VENDEDOR                                   AND
  v.CVE_EMPRESA        =  t.CVE_EMPRESA                                    AND
  v.CVE_TIPO_VENDEDOR  =  t.CVE_TIPO_VENDEDOR                              AND
  t.B_PAGA_COMISION    =  @k_verdadero)                                 --   AND
--  f.ID_CONCILIA_CXC = 1166   

  SET @NunRegistros = @@ROWCOUNT
--  SELECT * FROM @TItem
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- Prorratea los pagos entre las facturas (Cuando hay mas pagos para una factura o viceversa 
-----------------------------------------------------------------------------------------------------

  SET @RowCount     = 1 	
  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT
	@serie   =  SERIE,
	@id_cxc  =  ID_CXC,
	@id_item          =  ID_ITEM,
	@id_concilia_cxc  =  ID_CONCILIA_CXC,
	@imp_bruto_item   =  IMP_BRUTO_ITEM,
	@imp_f_factura    =  IMP_F_BRUTO,
	@cve_subproducto  =  CVE_SUBPRODUCTO,
	@cve_moneda       =  CVE_F_MONEDA
	FROM   @TItem WHERE  RowID = @RowCount
 

    SELECT  @cve_producto  =  (SELECT CVE_PRODUCTO FROM CI_SUBPRODUCTO  WHERE 
	                           CVE_SUBPRODUCTO = @cve_subproducto)

-----------------------------------------------------------------------------------------------------
--  Calcula el total de cargos y bonos asognados a la factura  
-----------------------------------------------------------------------------------------------------
    SET  @imp_abono  =
   (SELECT ISNULL(SUM(IMP_TRANSACCION),0)  FROM VTA_FACT_PAGO
    WHERE  CVE_EMPRESA = @pCveEmpresa AND SERIE = @serie AND ID_CXC = @id_cxc AND 
	       CVE_CARGO_ABONO  =  @k_abono)       

    SET  @imp_cargo  =
   (SELECT ISNULL(SUM(IMP_TRANSACCION),0)  FROM VTA_FACT_PAGO
    WHERE  CVE_EMPRESA = @pCveEmpresa AND SERIE = @serie AND ID_CXC = @id_cxc AND 
	       CVE_CARGO_ABONO  <>  @k_abono)       

 --   SELECT CONVERT(varchar(15), @imp_abono)
	--SELECT CONVERT(varchar(15), @imp_cargo)

	EXEC spCalculaComision @pCveEmpresa, @pAnoPeriodo, @serie, @id_cxc, @id_item, @id_concilia_cxc, @cve_moneda,
	                       @cve_producto, @imp_bruto_item, @imp_f_factura, @imp_abono, @imp_cargo

	SET @RowCount  =  @RowCount  +  1 

  END 

  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error en Calculo de Comisiones ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT '(E) Consulte tabla FC_TAREA_EVENTO ' + CONVERT(VARCHAR(10), @pIdProceso) + ' ' + CONVERT(VARCHAR(10), @pIdProceso)
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END

