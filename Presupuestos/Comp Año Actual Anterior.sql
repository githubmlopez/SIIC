USE [ADMON01]

select MONTH(f.F_OPERACION) as Mes, f.CVE_EMPRESA as Empresa, f.SERIE as serie, f.ID_CXC as 'Id. Fact', f.F_OPERACION as 'F.Operacion',
c.ID_CLIENTE as 'Id. Cliente', c.NOM_CLIENTE as Nombre, s.DESC_SUBPRODUCTO as Producto, f.CVE_F_MONEDA as 'Mon. Factura', f.CVE_R_MONEDA as 'Mon. Liquida',  
dbo.fnObtTipoCamb(f.F_operacion) as 'Tipo Cambio', i.IMP_BRUTO_ITEM as 'Imp. Bruto',
case f.CVE_F_MONEDA
when 'D' then i.IMP_BRUTO_ITEM
else  i.IMP_BRUTO_ITEM / dbo.fnObtTipoCamb(f.F_operacion)
END as 'Imp. Dolares'
from CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE c WHERE
f.CVE_EMPRESA        =  i.CVE_EMPRESA     AND
f.SERIE              =  i.SERIE           AND
f.ID_CXC             =  i.ID_CXC          AND
i.CVE_SUBPRODUCTO    =  s.CVE_SUBPRODUCTO AND
s.CVE_PRODUCTO       =  p.CVE_PRODUCTO    AND
f.ID_VENTA           =  v.ID_VENTA        AND
v.ID_CLIENTE         =  c.ID_CLIENTE      AND
f.SIT_TRANSACCION    =  'A'               AND  
F_OPERACION          >= '20170101'        AND
F_OPERACION          <= '20170731'        AND
f.SERIE              <> 'LEGACY' order by f.F_OPERACION, f.CVE_F_MONEDA


SELECT MONTH(c.F_PAGO)as 'Mes', c.CVE_EMPRESA as 'Empresa', c.ID_CXP as 'Id. CXC' , c.F_PAGO as 'F. Pago',
p.NOM_PROVEEDOR as 'Proveedor', 
o.DESC_OPERACION as 'Operación', c.CVE_MONEDA as 'Moneda', 
dbo.fnObtTipoCamb(c.F_PAGO) as 'Tipo Cambio',
c.IMP_BRUTO as 'Imp. Bruto',
case c.CVE_MONEDA
when 'D' then c.IMP_BRUTO
else  c.IMP_BRUTO / dbo.fnObtTipoCamb(c.F_PAGO) 
END as 'Importe USD'
FROM CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p, CI_OPERACION_CXP o 
where p.B_ASOCIADO = 1                     AND
      c.ID_PROVEEDOR = p.ID_PROVEEDOR      AND
      c.F_PAGO          >= '20160101'        AND
      c.F_PAGO          <= '20160731'        AND
      c.CVE_OPERACION  =  o.CVE_OPERACION    AND
      c.SIT_C_X_P = 'A'  order by c.F_PAGO         

