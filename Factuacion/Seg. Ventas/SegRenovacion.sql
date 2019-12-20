declare @f_referencia  date,
        @f_referencia2 date

set @f_referencia  = '2016-01-01' -- GETDATE()
set @f_referencia2 = '2015-01-01' -- GETDATE()

-- Cuenta cuantas pólizas están activas tomando como base la fecha de referencia

--select count(*)
select f.CVE_EMPRESA as 'Cve. Empresa', f.SERIE as 'Serie', f.ID_CXC as 'Id. CXC', i.ID_ITEM as 'Id. Item', c.ID_CLIENTE as 'Id. Cliente',
c.NOM_CLIENTE as 'Nom. Cliente', s.DESC_SUBPRODUCTO as 'Desc. Producto', i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin',
DATEPART(MONTH, F_FIN) as 'Mes Final', DATEDIFF(DAY, i.F_INICIO, i.F_FIN) as 'Disas Pol.', 
case 
when DATEDIFF(DAY, i.F_INICIO, i.F_FIN) not in (364,365) then '*' 
else ' ' 
end as 'Observ.', 
DATEDIFF(DAY, GETDATE(),i.F_FIN) as 'Dias Vig', i.IMP_BRUTO_ITEM as 'Imp. Bruto', s.PRECIO_LISTA as 'Precio', i.CVE_RENOVACION
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
--(DATEDIFF(DAY, @f_referencia,i.F_FIN) > 0 OR
--i.F_INICIO             IS NULL            OR
--i.F_INICIO           = '1900-01-01')      AND
f.SERIE              <> 'LEGACY' order by f.ID_CXC

-- Informa de las pólizas objetivo a renovar considerando la fecha de referencia

select f.CVE_EMPRESA as 'Cve. Empresa', f.SERIE as 'Serie', f.ID_CXC as 'Id. CXC', c.ID_CLIENTE as 'Id. Cliente',
c.NOM_CLIENTE as 'Nom. Cliente', s.DESC_SUBPRODUCTO as 'Desc. Producto', i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin',
DATEPART(MONTH, F_FIN) as 'Mes Final', DATEDIFF(DAY, i.F_INICIO, i.F_FIN) as 'Dias Pol.', 
case 
when DATEDIFF(DAY, i.F_INICIO, i.F_FIN) not in (364,365) then '*' 
else ' ' 
end as 'Observ.', 
DATEDIFF(DAY, GETDATE(),i.F_FIN) as 'Dias Vig', i.IMP_BRUTO_ITEM as 'Imp. Bruto', s.PRECIO_LISTA as 'Precio'
from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c WHERE
f.CVE_EMPRESA        =  i.CVE_EMPRESA        AND
f.SERIE              =  i.SERIE              AND
f.ID_CXC             =  i.ID_CXC             AND
i.CVE_SUBPRODUCTO    =  s.CVE_SUBPRODUCTO    AND
s.CVE_PRODUCTO       =  p.CVE_PRODUCTO       AND
p.CVE_PRODUCTO       =  'PO'                 AND
f.ID_VENTA           =  v.ID_VENTA           AND
v.ID_CLIENTE         =  c.ID_CLIENTE         AND
f.SIT_TRANSACCION    =  'A'                  AND
--DATEDIFF(DAY, @f_referencia2,i.F_FIN) > 0    AND
i.F_INICIO           IS NOT NULL             AND
i.F_INICIO           <> '1900-01-01'         AND
f.SERIE              <> 'LEGACY'             AND
DATEPART(YEAR, F_INICIO) IN (2019)           AND
NOT EXISTS
(SELECT 1  
FROM CI_VENTA vs, CI_FACTURA f2, CI_ITEM_C_X_C i2, CI_SUBPRODUCTO s2, CI_PRODUCTO p2, CI_VENTA v2, CI_CLIENTE c2 
WHERE 
f2.CVE_EMPRESA       = i2.CVE_EMPRESA     AND
f2.SERIE             = i2.SERIE           AND
f2.ID_CXC            = i2.ID_CXC          AND
f2.SIT_TRANSACCION   = 'A'                AND
i2.CVE_SUBPRODUCTO   = s2.CVE_SUBPRODUCTO AND
s2.CVE_PRODUCTO      = p2.CVE_PRODUCTO    AND
p2.CVE_PRODUCTO      = 'PO'               AND
f2.ID_VENTA          = v2.ID_VENTA        AND
v2.ID_CLIENTE        = c2.ID_CLIENTE      AND
c.ID_CLIENTE         = c2.ID_CLIENTE      AND
i.F_FIN             <= i2.F_INICIO) order by i.F_FIN

-- Informa de las pólizas renovadas considerando la fecha de referencia

select f.CVE_EMPRESA, f.SERIE, f.ID_CXC, c.ID_CLIENTE, c.NOM_CLIENTE, s.DESC_SUBPRODUCTO, i.F_INICIO, i.F_FIN, DATEDIFF(DAY, i.F_INICIO, i.F_FIN), 
case 
when DATEDIFF(DAY, i.F_INICIO, i.F_FIN) not in (364,365) then '*' 
else ' ' 
end , 
DATEDIFF(DAY, GETDATE(),i.F_FIN), i.IMP_BRUTO_ITEM
from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c WHERE
f.CVE_EMPRESA        =  i.CVE_EMPRESA        AND
f.SERIE              =  i.SERIE              AND
f.ID_CXC             =  i.ID_CXC             AND
i.CVE_SUBPRODUCTO    =  s.CVE_SUBPRODUCTO    AND
s.CVE_PRODUCTO       =  p.CVE_PRODUCTO       AND
p.CVE_PRODUCTO       =  'PO'                 AND
f.ID_VENTA           =  v.ID_VENTA           AND
v.ID_CLIENTE         =  c.ID_CLIENTE         AND
f.SIT_TRANSACCION    =  'A'                  AND
DATEDIFF(DAY, @f_referencia2,i.F_FIN) <= 0   AND
i.F_INICIO           IS NOT NULL             AND
i.F_INICIO           <> '1900-01-01'         AND
f.SERIE              <> 'LEGACY' 
AND EXISTS
(SELECT 1  
FROM CI_VENTA vs, CI_FACTURA f2, CI_ITEM_C_X_C i2, CI_SUBPRODUCTO s2, CI_PRODUCTO p2, CI_VENTA v2, CI_CLIENTE c2
WHERE 
f2.CVE_EMPRESA       = i2.CVE_EMPRESA     AND
f2.SERIE             = i2.SERIE           AND
f2.ID_CXC            = i2.ID_CXC          AND
f2.SIT_TRANSACCION   = 'A'                AND
i2.CVE_SUBPRODUCTO   = s2.CVE_SUBPRODUCTO AND
s2.CVE_PRODUCTO      = p2.CVE_PRODUCTO    AND
p2.CVE_PRODUCTO      = 'PO'               AND
f2.ID_VENTA          = v2.ID_VENTA        AND
v2.ID_CLIENTE        = c2.ID_CLIENTE      AND
c.ID_CLIENTE         = c2.ID_CLIENTE      AND
i.SERIE              = i2.SERIE           AND
i.ID_CXC             = i2.ID_CXC          AND
i.ID_ITEM            = i2.ID_ITEM         AND
i.F_FIN             <= i2.F_INICIO)	