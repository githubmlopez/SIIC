SELECT 
s.DESC_SUBPRODUCTO, COUNT(*) FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p 
WHERE
f.CVE_EMPRESA = i.CVE_EMPRESA         and
f.SERIE       = i.SERIE               and
f.ID_CXC      = i.ID_CXC              and
f.SIT_TRANSACCION = 'A'               and
f.SERIE <> 'LEGACY'                   and
p.CVE_PRODUCTO = 'PO'                 and
i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO and
s.CVE_PRODUCTO = p.CVE_PRODUCTO       and
(i.F_FIN  >                           '2017-12-31' OR
 i.F_FIN  IS NULL)  
GROUP BY s.DESC_SUBPRODUCTO  

SELECT
CONVERT(varchar(4),YEAR(i.F_INICIO)) +  replicate ('0',(02 - len(MONTH(i.F_INICIO)))) + 
convert(varchar, MONTH(i.F_INICIO)) as 'Año/mes',
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
i.ID_ITEM 'Id. Item', f.F_OPERACION as 'F. Operacion', c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', s.DESC_SUBPRODUCTO as 'Producto', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', i.IMP_BRUTO_ITEM as 'Imp. B. Item',
i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin' 
FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c  
WHERE
f.CVE_EMPRESA = i.CVE_EMPRESA         and
f.SERIE       = i.SERIE               and
f.ID_CXC      = i.ID_CXC              and
v.ID_VENTA    = f.ID_VENTA            and
v.ID_CLIENTE  = c.ID_CLIENTE          and
f.SIT_TRANSACCION = 'A'               and
f.SERIE <> 'LEGACY'                   and
p.CVE_PRODUCTO = 'PO'                 and
i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO and
s.CVE_PRODUCTO = p.CVE_PRODUCTO       and
(i.F_FIN  >                           '2017-12-31' OR
 i.F_FIN  IS NULL)  
--GROUP BY s.DESC_SUBPRODUCTO  

SELECT
CONVERT(varchar(4),YEAR(i.F_INICIO)) +  replicate ('0',(02 - len(MONTH(i.F_INICIO)))) + 
convert(varchar, MONTH(i.F_INICIO)) as 'Año/mes',
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
i.ID_ITEM 'Id. Item', f.F_OPERACION as 'F. Operacion', c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', s.DESC_SUBPRODUCTO as 'Producto', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', i.IMP_BRUTO_ITEM as 'Imp. B. Item',
i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin' 
FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c  
WHERE
f.CVE_EMPRESA = i.CVE_EMPRESA         and
f.SERIE       = i.SERIE               and
f.ID_CXC      = i.ID_CXC              and
v.ID_VENTA    = f.ID_VENTA            and
v.ID_CLIENTE  = c.ID_CLIENTE          and
f.SIT_TRANSACCION = 'A'               and
f.SERIE <> 'LEGACY'                   and
p.CVE_PRODUCTO = 'LI'                 and
i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO and
s.CVE_PRODUCTO = p.CVE_PRODUCTO       
   




