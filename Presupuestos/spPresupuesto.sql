USE ADMON01
GO

SELECT CONVERT(varchar(4),YEAR(i.F_INICIO)) +  replicate ('0',(02 - len(MONTH(i.F_INICIO)))) + 
convert(varchar, MONTH(i.F_INICIO)) as 'Año/Mes',
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
i.ID_ITEM 'Id. Item', f.F_OPERACION as 'F. Operacion',
Case
when exists (select 1 from CI_ITEM_C_X_C i2 where i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
                                                  i.SERIE        = i2.SERIE_RENO       AND
                                                  i.ID_CXC       = i2.ID_CXC_RENO      AND
                                                  i.ID_ITEM      = i2.ID_ITEM_RENO)
THEN  'Renovada'
ELSE  'No Renovada'                                           
END AS 'Renovada',
dbo.fnObtSitPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) as 'Sit. Poliza',
dbo.fnObtTxtPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) as 'Comentario',
dbo.fnCalculaPesos(f.F_OPERACION,i.IMP_BRUTO_ITEM,f.CVE_F_MONEDA) as 'Presupuestado',
Case
when exists (select 1 from CI_FACTURA fe, CI_ITEM_C_X_C i2 where
(i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
 i.SERIE        = i2.SERIE_RENO       AND
 i.ID_CXC       = i2.ID_CXC_RENO      AND
 i.ID_ITEM      = i2.ID_ITEM_RENO)    AND
(SELECT f2.SIT_TRANSACCION FROM CI_FACTURA f2 WHERE
 i2.CVE_EMPRESA  = f2.CVE_EMPRESA AND
 i2.SERIE        = f2.SERIE       AND
 i2.ID_CXC       = f2.ID_CXC) = 'A')    
THEN  dbo.fnCalculaPesos(
(select f2.F_OPERACION from CI_FACTURA f2, CI_ITEM_C_X_C i2  where 
 i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
 i.SERIE        = i2.SERIE_RENO       AND
 i.ID_CXC       = i2.ID_CXC_RENO      AND
 i.ID_ITEM      = i2.ID_ITEM_RENO     AND
 i2.CVE_EMPRESA = f2.CVE_EMPRESA      AND
 i2.SERIE       = f2.SERIE           AND
 i2.ID_CXC      = f2.ID_CXC          AND
 f2.SIT_TRANSACCION = 'A'),

(select i2.IMP_BRUTO_ITEM from CI_ITEM_C_X_C i2  where 
(i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
 i.SERIE        = i2.SERIE_RENO       AND
 i.ID_CXC       = i2.ID_CXC_RENO      AND
 i.ID_ITEM      = i2.ID_ITEM_RENO)    AND
(SELECT f2.SIT_TRANSACCION FROM CI_FACTURA f2 WHERE
 i2.CVE_EMPRESA  = f2.CVE_EMPRESA AND
 i2.SERIE        = f2.SERIE       AND
 i2.ID_CXC       = f2.ID_CXC) = 'A'), 
    
(select f2.CVE_F_MONEDA from CI_FACTURA f2, CI_ITEM_C_X_C i2  where 
 i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
 i.SERIE        = i2.SERIE_RENO       AND
 i.ID_CXC       = i2.ID_CXC_RENO      AND
 i.ID_ITEM      = i2.ID_ITEM_RENO     AND
 i2.CVE_EMPRESA = f2.CVE_EMPRESA      AND
 i2.SERIE       = f2.SERIE            AND
 i2.ID_CXC      = f2.ID_CXC           AND
 f2.SIT_TRANSACCION = 'A'))
ELSE  0                                           
END AS 'Facturado',
c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', s.DESC_SUBPRODUCTO as 'Producto', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', i.IMP_BRUTO_ITEM as 'Imp. B. Item',
i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin',  1 as Clave
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
p.CVE_PRODUCTO = 'PO'                 and
YEAR(i.F_INICIO)  in ('2017','2018')  and
dbo.fnObtSitPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) <> '9' -- and
--not exists (select 1 from CI_ITEM_C_X_C i2 where i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
--                                                  i.SERIE        = i2.SERIE_RENO       AND
--                                                  i.ID_CXC       = i2.ID_CXC_RENO      AND
--                                                  i.ID_ITEM      = i2.ID_ITEM_RENO)
--order by i.F_INICIO, c.ID_CLIENTE, f.ID_CXC 
union
SELECT CONVERT(varchar(4),YEAR(i.F_INICIO)) +  replicate ('0',(02 - len(MONTH(i.F_INICIO)))) + 
convert(varchar, MONTH(i.F_INICIO)) as 'Año/mes',
f.CVE_EMPRESA as 'Empresa', F.SERIE as 'Serie', f.ID_CXC as 'Id. CXC',
i.ID_ITEM 'Id. Item', f.F_OPERACION as 'F. Operacion',
--Case
--when exists (select 1 from CI_ITEM_C_X_C i2 where i.CVE_EMPRESA  = i2.CVE_EMPRESA_RENO AND
--                                                  i.SERIE        = i2.SERIE_RENO       AND
--                                                  i.ID_CXC       = i2.ID_CXC_RENO      AND
--                                                  i.ID_ITEM      = i2.ID_ITEM_RENO)
--THEN  'Renovada'
--ELSE  'No Renovada'                                           
--END AS 'Renovada',
'Nva. Poliza',
dbo.fnObtSitPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) as 'Sit. Poliza',
dbo.fnObtTxtPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) as 'Comentario',
dbo.fnCalculaPesos(f.F_OPERACION,i.IMP_BRUTO_ITEM,f.CVE_F_MONEDA) as 'Presupuestado',
dbo.fnCalculaPesos(f.F_OPERACION,i.IMP_BRUTO_ITEM,f.CVE_F_MONEDA) as 'Facturado',
c.ID_CLIENTE as 'Id. Cliente',c.NOM_CLIENTE as 'Nombre', s.DESC_SUBPRODUCTO as 'Producto', 
f.CVE_F_MONEDA as 'Moneda', f.IMP_F_BRUTO as 'Imp. Bruto', i.IMP_BRUTO_ITEM as 'Imp. B. Item',
i.F_INICIO as 'F. Inicio', i.F_FIN as 'F. Fin',  2 as Clave
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
p.CVE_PRODUCTO = 'PO'                 and
YEAR(f.F_OPERACION)  >= '2018'        and
(YEAR(i.F_INICIO)  =  '2018'          or
 i.F_INICIO is null)                   and
(i.CVE_EMPRESA_RENO is null            and
 i.SERIE_RENO       is null            and
 i.ID_CXC_RENO      is null            and
 i.ID_ITEM_RENO     is null)           and
 dbo.fnObtSitPol(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM) <> '9'
order by Clave, i.F_INICIO, c.ID_CLIENTE, f.ID_CXC 

--SELECT ID_CXC_RENO FROM CI_ITEM_C_X_C i, CI_FACTURA f
--WHERE f.CVE_EMPRESA = i.CVE_EMPRESA AND
--      f.SERIE = i.SERIE AND
--	  f.ID_CXC = i.ID_CXC AND
--	  f.SIT_TRANSACCION = 'A'
--GROUP BY ID_CXC_RENO 
--HAVING COUNT(*) > 1


