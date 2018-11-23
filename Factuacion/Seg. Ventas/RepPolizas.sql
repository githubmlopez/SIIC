select f.CVE_EMPRESA, f.SERIE, f.ID_CXC, c.ID_CLIENTE, c.NOM_CLIENTE, s.DESC_SUBPRODUCTO, i.F_INICIO, i.F_FIN, DATEDIFF(DAY, i.F_INICIO, i.F_FIN), 
case 
when DATEDIFF(DAY, i.F_INICIO, i.F_FIN) not in (364,365) then '*' 
else ' ' 
end , 
DATEDIFF(DAY, GETDATE(),i.F_FIN), i.IMP_BRUTO_ITEM
from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c WHERE
f.CVE_EMPRESA        =  i.CVE_EMPRESA     AND
f.SERIE              =  i.SERIE           AND
f.ID_CXC             =  i.ID_CXC          AND
i.CVE_SUBPRODUCTO    =  s.CVE_SUBPRODUCTO AND
s.CVE_PRODUCTO       =  p.CVE_PRODUCTO    AND
p.CVE_PRODUCTO       =  'PO'              AND
f.ID_VENTA           =  v.ID_VENTA        AND
v.ID_CLIENTE         =  c.ID_CLIENTE      AND
f.SIT_TRANSACCION    =  'A'               AND
(DATEDIFF(DAY, GETDATE(),i.F_FIN) > 0     OR
i.F_INICIO             IS NULL            OR
i.F_INICIO           = '1900-01-01')      AND
f.SERIE              <> 'LEGACY' order by ID_CLIENTE

