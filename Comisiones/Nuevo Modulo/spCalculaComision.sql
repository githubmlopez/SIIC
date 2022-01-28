USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCalculaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCalculaComision')
DROP PROCEDURE [dbo].[spCalculaComision]
GO
 --EXEC spCalculaComision @pCveEmpresa, @pAnoPeriodo, @serie, @id_cxc, @id_item, @id_concilia_cxc, @cve_moneda, 
 --@cve_producto, @imp_bruto_item, @imp_f_factura, @imp_abono, @imp_cargo	
CREATE PROCEDURE [dbo].[spCalculaComision]
(
@pCveEmpresa     varchar(4),
@pAnoPeriodo     varchar(6),
@pSerie          varchar(6),
@pIdCxc          int,
@pIdItem         int,
@pIdConciliaCxc  int,
@pCveMoneda      varchar(1),
@pCveProducto    varchar(4), 
@pImpBrutoItem   numeric(12,2),
@pImpBrutoFact   numeric(12,2),
@pImpAbono       numeric(12,2),
@pImpCargo       numeric(12,2) 
 
) 
AS
BEGIN

--SELECT @pAnoPeriodo
--SELECT @pSerie
--SELECT CONVERT(VARCHAR(10),@pIdCxc)
--SELECT CONVERT(VARCHAR(25),@pIdItem)
--SELECT CONVERT(VARCHAR(25),@pIdConciliaCxc)
--SELECT @pCveMoneda
--SELECT @pCveProducto 
--SELECT CONVERT(VARCHAR(25),@pImpBrutoItem)
--SELECT CONVERT(VARCHAR(25),@pImpBrutoFact)
--SELECT CONVERT(VARCHAR(25),@pImpAbono)
--SELECT CONVERT(VARCHAR(25),@pImpCargo) 
--SELECT 'TERMINA PAR'

  DECLARE  @k_verdadero       bit        =  1,
           @k_falso           bit        =  0,
		   @k_dolar           varchar(1) =  'D',
		   @k_iva             varchar(4) =  'IVA' 

  DECLARE  @NunRegistros      int = 0, 
		   @RowCount          int = 0,
		   @pje_part_item     numeric(8,4),
		   @imp_part_item     numeric(12,2),
		   @imp_comis_item    numeric(12,2),
		   @imp_com_banc      numeric(12,2),
		   @pje_comision      numeric(8,4),
		   @tipo_vendedor     varchar(1),
		   @imp_comision      numeric(12,2),
		   @f_movto           date
           
  DECLARE  @serie             varchar(6),
           @id_cxc            int,
		   @id_item           int,
		   @cve_vendedor      varchar(4),
		   @cve_proceso       varchar(4),
		   @cve_especial      varchar(2),
		   @imp_descuento     numeric(12,2),
		   @imp_comis_dir     numeric(12,2),
		   @tx_nota           varchar(80)
 
  DECLARE @TComisItem  TABLE 
 (
  RowID                int IDENTITY(1,1),   
  SERIE                varchar(6),
  ID_CXC               int,
  ID_ITEM              int,
  CVE_VENDEDOR         varchar(4),
  CVE_PROCESO          varchar(4),
  CVE_ESPECIAL         varchar(2),
  IMP_DESCUENTO        numeric(12,2),
  IMP_COMIS_DIR        numeric(12,2),
  TX_NOTA              varchar(80)
 )

------------------------------------------------------------------------------------------
-- Calcula monto asignado de pago de la factura en el periodo                           --
------------------------------------------------------------------------------------------   
-- Recordar meter como indice ID_CONCILIA_CXC
  
  INSERT INTO  @TComisItem 
  SELECT SERIE, ID_CXC, ID_ITEM, CVE_VENDEDOR, CVE_PROCESO, CVE_ESPECIAL, IMP_DESCUENTO, IMP_COMIS_DIR,
         TX_NOTA
  FROM  VTA_COMIS_ITEM
  WHERE CVE_EMPRESA  =  @pCveEmpresa AND SERIE = @pSerie AND ID_CXC = @pIdCxc AND ID_ITEM = @pIdItem
  SET @NunRegistros = @@ROWCOUNT
  SELECT * FROM  @TComisItem 
  SET  @RowCount = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @serie = SERIE, @id_cxc = ID_CXC, @id_item = ID_ITEM, @cve_vendedor = CVE_VENDEDOR,
	       @cve_proceso = CVE_PROCESO, @cve_especial = CVE_ESPECIAL, @imp_descuento = ISNULL(IMP_DESCUENTO,0),
		   @imp_comis_dir = ISNULL(IMP_COMIS_DIR,0), @tx_nota = TX_NOTA
	FROM   @TComisItem WHERE  RowID = @RowCount
 --  SELECT 'subproducto***  ' +
--	(SELECT CVE_SUBPRODUCTO FROM CI_ITEM_C_X_C WHERE id_cxc = @id_cxc AND id_item = @id_item) 
    SELECT @tipo_vendedor = ISNULL(CVE_TIPO_VENDEDOR,0) 
    FROM  VTA_VENDEDOR
    WHERE CVE_EMPRESA = @pCveEmpresa AND CVE_VENDEDOR = @cve_vendedor
--    SELECT '@tipo_vendedor ' + CONVERT(VARCHAR(25), @tipo_vendedor )
	--SELECT '@tipo_vendedor ' + @cve_vendedor 
	--SELECT '@imp_comis_dir' + CONVERT(VARCHAR(25),  @imp_comis_dir )
    IF  @imp_comis_dir = 0
	BEGIN
------------------------------------------------------------------------------------------
-- Calcula participación del item en la factura y el porcentaje de pago que le corresponde
-- en base a lo que se pago en la factura
------------------------------------------------------------------------------------------ 	
 
 
    --SELECT '@pImpAbono ' + CONVERT(VARCHAR(25), @pImpAbono )
    SET  @pImpAbono  =  @pImpAbono / 
	                   (1 + ((SELECT VALOR_NUMERICO FROM CI_PARAMETRO  WHERE CVE_PARAMETRO = @k_iva) / 100))
 
 --   SELECT '@pImpBrutoItem ' + CONVERT(VARCHAR(25), @pImpBrutoItem )
	--SELECT '@pImpBrutoFact  ' + CONVERT(VARCHAR(25), @pImpBrutoFact  )   
    SET @pje_part_item  =  @pImpBrutoItem / @pImpBrutoFact      
    --SELECT '@pje_part_item ' + CONVERT(VARCHAR(25), @pje_part_item )

    --SELECT '@pImpAbono SI ' + CONVERT(VARCHAR(25), @pImpAbono )

	SET @imp_part_item  =  @pImpAbono * @pje_part_item
    --SELECT '@imp_part_item ' + CONVERT(VARCHAR(25), @imp_part_item )

	IF  @pCveMoneda  =  @k_dolar AND  @pImpCargo <> 0
	BEGIN
      SET  @f_movto     =  
	 (SELECT MAX(m.F_OPERACION) FROM CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m 
	  WHERE 
	  c.ID_CONCILIA_CXC    = @pIdConciliaCxc       AND
	  c.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO)

	  SET  @pImpCargo =  @pImpCargo * 
	       ISNULL(dbo.fnObtTipoCamb(@f_movto),0) * @pje_part_item
      --select '@pImpCargo ' + CONVERT(VARCHAR, @pImpCargo)

	END  

	SET @imp_com_banc  =  @pImpCargo * @pje_part_item	

------------------------------------------------------------------------------------------
-- Calcula porcentaje de comision y comision que le corresponde al vendedor
------------------------------------------------------------------------------------------    
 --   SELECT '@pCveProducto ' + @pCveProducto
	--SELECT '@cve_proceso ' + @cve_proceso
	--SELECT '@cve_especial  ' + @cve_especial 
    SELECT @pje_comision = ISNULL(PJE_COMISION,0) 
    FROM  VTA_PJE_COMISION 
    WHERE CVE_EMPRESA = @pCveEmpresa AND CVE_TIPO_VENDEDOR = @tipo_vendedor AND  CVE_PRODUCTO = @pCveProducto AND
	      CVE_PROCESO  =  @cve_proceso  AND CVE_ESPECIAL = @cve_especial   
    --SELECT '@pje_comision ' + CONVERT(VARCHAR(25), @pje_comision )
	SET  @imp_comision  =  @imp_part_item * @pje_comision /100

	END
	ELSE
	BEGIN
	  SET   @imp_comision  =  @imp_comis_dir 
	END
   
    SET  @imp_comision  =  @imp_comision -  @imp_descuento -  @imp_com_banc
------------------------------------------------------------------------------------------
-- Crea registro de cupón correpondiente a la comision
------------------------------------------------------------------------------------------    
 --   SELECT '@imp_comision ***  ' + CONVERT(VARCHAR(25), @imp_comision)
    IF  @imp_comision  >  0
	BEGIN
      INSERT INTO VTA_CUPON_COMISION
	 (
      ANO_MES,
	  CVE_EMPRESA,
      SERIE,
      ID_CXC,
      ID_ITEM,
      CVE_VENDEDOR,
      CVE_PROCESO,
	  CVE_ESPECIAL,
      PJE_COMISION,
      IMP_BASE_PAGADO,
	  IMP_CUPON,
	  IMP_COM_BANC,
      TX_NOTA
	 )
	  VALUES
	 (
	  @pAnoPeriodo,
	  @pCveEmpresa,
	  @serie,
	  @id_cxc,
	  @id_item,
	  @cve_vendedor,
	  @cve_proceso,
	  @cve_especial,
	  @pje_comision,
      @imp_part_item,
	  @imp_comision,
	  @imp_com_banc,
      ' '  
	 )
	END

	SET @RowCount  =  @RowCount  +  1 

  END 

END     

