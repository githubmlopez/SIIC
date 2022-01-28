USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCalculaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spRepRenovacion')
DROP PROCEDURE [dbo].[spRepRenovacion]
GO
--EXEC spRepRenovacion 'CU', '201910'	
CREATE PROCEDURE [dbo].[spRepRenovacion]
(
@pCveEmpresa     varchar(4),
@pAnoPeriodo     varchar(6)
) 
AS
BEGIN
  DECLARE  @k_verdadero  varchar(1)  = 1,
           @k_legado     varchar(6)  = 'LEGACY',
		   @k_activa     varchar(1)  = 'A',
		   @k_uno_n      varchar(3)  = '1-N',
		   @k_n_1        varchar(3)  = 'N-1'

  DECLARE  @NunRegistros  int = 0, 
		   @RowCount      int = 0,
           @ano   varchar(4),
           @folio int

  DECLARE  @serie             varchar(6),
           @id_cxc            int,
		   @id_item           int,
		   @f_inicio          date,
		   @f_fin             date,
		   @imp_bruto_item    numeric(16,2),
		   @subproducto       varchar(6)

  
  SET @ano = SUBSTRING(@pAnoPeriodo,1,4)

  DECLARE @TItem TABLE
 (
  RowID                int IDENTITY(1,1),  
  FOLIO                int,
  SUBFOLIO             int,
  F_OPERACION          varchar(10),
  CVE_EMPRESA          varchar(4),
  SERIE                varchar(6),
  ID_CXC               varchar(6),
  ID_ITEM              varchar(6),
  F_INICIO             date,
  F_FIN                date,
  ID_CLIENTE           varchar(10),
  NOM_CLIENTE          varchar(100),
  DESC_SUBPRODUCTO     varchar(100),
  CVE_VENDEDOR         varchar(4),
  CVE_MONEDA           varchar(1),
  IMP_BRUTO_ITEM       varchar(15)
 )

   DECLARE @TItemN_N TABLE
 (
  RowID                int IDENTITY(1,1),  
  FOLIO                int,
  SUBFOLIO             int,
  F_OPERACION          varchar(10),
  CVE_EMPRESA          varchar(4),
  SERIE                varchar(6),
  ID_CXC               varchar(6),
  ID_ITEM              varchar(6),
  F_INICIO             date,
  F_FIN                date,
  ID_CLIENTE           varchar(10),
  NOM_CLIENTE          varchar(100),
  DESC_SUBPRODUCTO     varchar(100),
  CVE_VENDEDOR         varchar(4),
  CVE_MONEDA           varchar(1),
  IMP_BRUTO_ITEM       varchar(15),
  CVE_EMPRESA_R        varchar(4),
  SERIE_R              varchar(6),
  ID_CXC_R             varchar(6),
  ID_ITEM_R            varchar(6)
 )

  DECLARE @TGrupoN_N TABLE
 (
  RowID                int IDENTITY(1,1),  
  FOLIO                int,
  SUBFOLIO             int,
  CVE_EMPRESA_R        varchar(4),
  SERIE_R              varchar(6),
  ID_CXC_R             varchar(6),
  ID_ITEM_R            varchar(6)
 )
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO @TItem    
  SELECT 
  FOLIO = 0,
  SUBFOLIO = 0,
  f.F_OPERACION,
  f.CVE_EMPRESA,
  F.SERIE,
  f.ID_CXC,
  i.ID_ITEM,
  i.F_INICIO,
  i.F_FIN, 
  c.ID_CLIENTE,  
  c.NOM_CLIENTE,
  s.DESC_SUBPRODUCTO, 
  dbo.fnObtVendedor(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM),
  f.CVE_F_MONEDA,
  i.IMP_BRUTO_ITEM
  FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_VENTA v, CI_CLIENTE c, CI_SUBPRODUCTO s, CI_PRODUCTO p 
  WHERE 
  f.CVE_EMPRESA = i.CVE_EMPRESA         AND
  f.SERIE       = i.SERIE               AND
  f.ID_CXC      = i.ID_CXC              AND
  v.ID_VENTA    = f.ID_VENTA            AND
  v.ID_CLIENTE  = c.ID_CLIENTE          AND
  i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO AND
  s.CVE_PRODUCTO = p.CVE_PRODUCTO       AND
  f.SIT_TRANSACCION = @k_activa         AND
  f.SERIE <> @k_legado                  AND
  YEAR(f.F_OPERACION) IN (@ano)         AND      
  p.B_MANTENIMIENTO = @k_verdadero    


  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------

  UPDATE @TItem SET FOLIO = RowID

--  SELECT * FROM @TItem

  SET @RowCount     = 1 	
  
  WHILE @RowCount <= @NunRegistros
  BEGIN 
    SELECT
    @folio          = FOLIO,
	@serie          = SERIE,
	@id_cxc         = ID_CXC,
	@id_item        = ID_ITEM,
	@f_inicio       = F_INICIO,
	@f_fin          = F_FIN,
	@imp_bruto_item = IMP_BRUTO_ITEM,
	@subproducto    = DESC_SUBPRODUCTO
    FROM   @TItem WHERE  RowID = @RowCount

    INSERT INTO @TItem    
    SELECT 
    @folio,
    SUBFOLIO = 1,
    f.F_OPERACION,
    f.CVE_EMPRESA,
    f.SERIE,
    f.ID_CXC,
    i.ID_ITEM,
    i.F_INICIO,
    i.F_FIN, 
    c.ID_CLIENTE,  
    c.NOM_CLIENTE,
    s.DESC_SUBPRODUCTO, 
    dbo.fnObtVendedor(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM),
    f.CVE_F_MONEDA,
    I.IMP_BRUTO_ITEM
    FROM  VTA_RENOVACION_POLIZA r, CI_ITEM_C_X_C i, CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_SUBPRODUCTO s
    WHERE 
    r.CVE_EMPRESA_R   =  @pCveEmpresa      AND
    r.SERIE_R         =  @serie            AND
    r.ID_CXC_R        =  @id_cxc           AND
    r.ID_ITEM_R       =  @id_item          AND
    i.CVE_EMPRESA     =  @pCveEmpresa      AND
    i.SERIE           =  r.SERIE           AND
    i.ID_CXC          =  r.ID_CXC          AND
    i.ID_ITEM         =  r.ID_ITEM         AND
    i.CVE_EMPRESA     =  f.CVE_EMPRESA     AND
	i.SERIE           =  f.SERIE           AND
    i.ID_CXC          =  f.ID_CXC          AND
    v.ID_VENTA        =  f.ID_VENTA        AND
    v.ID_CLIENTE      =  c.ID_CLIENTE      AND
    s.CVE_SUBPRODUCTO =  i.CVE_SUBPRODUCTO AND
	f.SIT_TRANSACCION =  @k_activa         AND
    f.SERIE           <> @k_legado         AND
	r.CARDINALIDAD    =  @k_uno_n          

    SET @RowCount  =  @RowCount  +  1 

  END

  SET @NunRegistros = (SELECT COUNT(*) FROM @TItem)

  SET @RowCount     = 1 	
  
  WHILE @RowCount <= @NunRegistros
  BEGIN 
    SELECT
    @folio          = FOLIO,
	@serie          = SERIE,
	@id_cxc         = ID_CXC,
	@id_item        = ID_ITEM,
	@f_inicio       = F_INICIO,
	@f_fin          = F_FIN,
	@imp_bruto_item = IMP_BRUTO_ITEM,
	@subproducto    = DESC_SUBPRODUCTO
    FROM   @TItem WHERE  RowID = @RowCount  AND SUBFOLIO = 0

    IF  @id_cxc = 698
	BEGIN
    SELECT  @pCveEmpresa      
    SELECT @serie            
    SELECT  @id_cxc           
    SELECT @id_item          
	END

    INSERT INTO @TItem    
    SELECT 
    @folio,
    SUBFOLIO = 1,
    f.F_OPERACION,
    f.CVE_EMPRESA,
    f.SERIE,
    f.ID_CXC,
    i.ID_ITEM,
    i.F_INICIO,
    i.F_FIN, 
    c.ID_CLIENTE,  
    c.NOM_CLIENTE,
    s.DESC_SUBPRODUCTO, 
    dbo.fnObtVendedor(@pCveEmpresa, i.SERIE, i.ID_CXC, i.ID_ITEM),
    f.CVE_F_MONEDA,
    I.IMP_BRUTO_ITEM
    FROM  VTA_RENOVACION_POLIZA r, CI_ITEM_C_X_C i, CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_SUBPRODUCTO s
    WHERE 
    r.CVE_EMPRESA     =  @pCveEmpresa      AND
    r.SERIE           =  @serie            AND
    r.ID_CXC          =  @id_cxc           AND
    r.ID_ITEM         =  @id_item          AND
    i.CVE_EMPRESA     =  @pCveEmpresa      AND
    i.SERIE           =  r.SERIE_R         AND
    i.ID_CXC          =  r.ID_CXC_R        AND
    i.ID_ITEM         =  r.ID_ITEM_R       AND
    i.CVE_EMPRESA     =  f.CVE_EMPRESA     AND
	i.SERIE           =  f.SERIE           AND
    i.ID_CXC          =  f.ID_CXC          AND
    v.ID_VENTA        =  f.ID_VENTA        AND
    v.ID_CLIENTE      =  c.ID_CLIENTE      AND
    s.CVE_SUBPRODUCTO =  i.CVE_SUBPRODUCTO AND
	f.SIT_TRANSACCION =  @k_activa         AND
	r.CARDINALIDAD    =  @k_n_1            AND
    f.SERIE <> @k_legado                  
	
    SET @RowCount  =  @RowCount  +  1 

  END          
   
  SELECT 
  FOLIO as 'Folio',
  SUBFOLIO as 'Subfolio',
  F_OPERACION as 'F. Operacion',
  CVE_EMPRESA as 'Empresa',
  SERIE as 'Serie',
  ID_CXC as 'Id. CXC',
  ID_ITEM as 'Id. Item',
  F_INICIO as 'F. Inicio',
  F_FIN as 'F. Fin', 
  ID_CLIENTE as 'Id. Cliente',
  NOM_CLIENTE as 'Nombre',
  DESC_SUBPRODUCTO as 'sub Producto', 
  CVE_VENDEDOR as 'Cve Vendedror',
  CVE_MONEDA as 'Cve Moneda',
  IMP_BRUTO_ITEM as 'Imp. B. Item'
  FROM @TItem ORDER BY FOLIO, SUBFOLIO
END
