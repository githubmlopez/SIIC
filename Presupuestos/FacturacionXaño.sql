USE ADMON01
GO

SELECT 
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
i.ID_ITEM 'Id. Item', f.F_OPERACION as 'F. Operacion',
c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', s.DESC_SUBPRODUCTO as 'Producto', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', i.IMP_BRUTO_ITEM as 'Imp. B. Item',
f.TIPO_CAMBIO_LIQ,
CASE
WHEN  CVE_F_MONEDA = 'P' THEN
dbo.fnCalculaDolares(f.F_OPERACION,i.IMP_BRUTO_ITEM,f.CVE_F_MONEDA)
WHEN  CVE_F_MONEDA = 'D' THEN
i.IMP_BRUTO_ITEM
ELSE 0
END as 'USD',
f.CVE_R_MONEDA,
dbo.fnAcumMovtosSql(f.ID_CONCILIA_CXC) AS 'Pagado Fact. USD', 
dbo.fnAcumMovtosSql(f.ID_CONCILIA_CXC)  * (i.IMP_BRUTO_ITEM / f.IMP_F_BRUTO) AS 'Pagado Item USD'
FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_VENTA v, CI_CLIENTE c, CI_SUBPRODUCTO s, CI_PRODUCTO p 
WHERE 
f.CVE_EMPRESA = i.CVE_EMPRESA         and
f.SERIE       = i.SERIE               and
f.ID_CXC      = i.ID_CXC              and
v.ID_VENTA    = f.ID_VENTA            and
v.ID_CLIENTE  = c.ID_CLIENTE          and
i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO and
s.CVE_PRODUCTO = p.CVE_PRODUCTO       and
f.SIT_TRANSACCION = 'A'               and
f.SERIE <> 'LEGACY'                   and
--i.CVE_VENDEDOR1  =  'DAFU'          and
YEAR(f.F_OPERACION) IN (2017)         and 
s.CVE_PRODUCTO IN ('PO','PE')   
order by f.F_OPERACION

--SELECT cp.ID_PROVEEDOR, p.NOM_PROVEEDOR, cp.TX_NOTA, cp.CVE_MONEDA,
--cp.IMP_BRUTO, cp.IMP_IVA, cp.IMP_NETO,
--CASE
--WHEN  cp.CVE_MONEDA = 'D' THEN
--dbo.fnCalculaPesos(cp.F_CAPTURA,cp.IMP_BRUTO,cp.CVE_MONEDA)
--WHEN  cp.CVE_MONEDA = 'P' THEN
--cp.IMP_BRUTO
--ELSE 0
--END as 'Pesos'
--FROM CI_CUENTA_X_PAGAR cp, CI_PROVEEDOR p
--WHERE cp.SIT_C_X_P = 'A'  AND
--cp.ID_PROVEEDOR  = p.ID_PROVEEDOR  AND
--p.CVE_CLASIF_PROV = 'A'  AND
--YEAR(cp.F_CAPTURA) IN (2018) 

--select * from CI_PRODUCTO




