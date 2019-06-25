USE DICCIONARIO
GO

select C.BASE_DATOS, C.NOM_TABLA, c.TIPO_LLAVE, c.NOM_TABLA_REF, cc.NOM_CAMPO, cc.NOM_CAMPO_REF
from FC_CONSTRAINT c, FC_CONSTR_CAMPO cc, FC_TABLA_COLUMNA t
WHERE c.NOM_TABLA in ('CI_FACTURA', 'CI_CUENTA_X_PAGAR','CI_EMPRESA', 'CI_PROVEEDOR', 'CI_CHEQUERA', 'CI_TIPO_MOVIMIENTO', 'CI_VENTA_FACTURA', 'CI_VENTA')
AND t.BASE_DATOS = cc.BASE_DATOS 
AND t.NOM_TABLA = cc.NOM_TABLA 
AND t.NOM_CAMPO = cc.NOM_CAMPO
AND c.BASE_DATOS = cc.BASE_DATOS 
AND C.NOM_TABLA = cc.NOM_TABLA 
AND C.NOM_CONSTRAINT = CC.NOM_CONSTRAINT 
order by c.BASE_DATOS, c.NOM_TABLA, c.TIPO_LLAVE desc, t.POSICION, cc.NOM_CAMPO, c.NOM_TABLA_REF
