SELECT 
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
f.F_OPERACION as 'F. Operacion',
c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', 
CASE
WHEN  CVE_F_MONEDA = 'D' THEN
dbo.fnCalculaPesos(f.F_OPERACION,f.IMP_F_BRUTO,f.CVE_F_MONEDA)
WHEN  CVE_F_MONEDA = 'P' THEN
f.IMP_F_BRUTO
ELSE 0
END as 'Pesos'
FROM CI_FACTURA f, CI_VENTA v, CI_CLIENTE c 
WHERE 
v.ID_VENTA    = f.ID_VENTA            and
v.ID_CLIENTE  = c.ID_CLIENTE          and
f.SIT_TRANSACCION = 'A'               and
f.SERIE <> 'LEGACY'                   and
month(f.F_OPERACION) = 12             and
year(f.F_OPERACION) = 2017            
order by f.F_OPERACION, ID_CXC