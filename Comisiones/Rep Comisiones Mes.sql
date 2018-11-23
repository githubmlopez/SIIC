USE [ADMON01]
/****** Object:  StoredProcedure [dbo].[spRepComsion]   ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC spRepComision '201708', 0, 'D'

ALTER PROCEDURE [dbo].[spRepComsion] @panomes varchar(6), @pfolio int, @popcion varchar(1) 
AS
BEGIN

declare  @k_fecha  varchar(1),
         @k_folio  varchar(1)

set      @k_fecha  =  'D'
set      @k_folio  =  'F'


SELECT  f.ID_CONCILIA_CXC as 'Id. Unico',
f.SERIE as 'Serie', f.ID_CXC as 'Id. CXC', f.F_OPERACION as 'F. Operacion', f.IMP_F_BRUTO as 'Imp. Bruto',
f.CVE_F_MONEDA as 'Modeda',
case 
when i.F_INICIO is null then ' ' 
when i.F_INICIO = '19000101' then ' ' 
else LEFT(CONVERT(VARCHAR, i.F_INICIO, 120), 10) 
end as 'F. Inicio', 
ct.NOM_CLIENTE as 'Nombre Cliente', s.DESC_SUBPRODUCTO as 'Desc. Subproducto', f.F_REAL_PAGO as 'F. Pago', f.IMP_R_NETO_COM as 'Imp. comisionable',
f.CVE_R_MONEDA as 'Cve. Mon. Liq.',
case 
when f.CVE_R_MONEDA = 'D' then 
dbo.fnCalculaPesos(f.F_REAL_PAGO, f.IMP_R_NETO_COM, f.CVE_R_MONEDA) 
else f.IMP_R_NETO_COM 
end as 'Imp.Co. Pesos', 
f.TIPO_CAMBIO_LIQ as 'Tipo Cam Liq',

case 
when f.CVE_F_MONEDA = 'D' then 
dbo.fnCalculaPesos(f.F_REAL_PAGO, i.IMP_BRUTO_ITEM, f.CVE_F_MONEDA) 
else i.IMP_BRUTO_ITEM 
end as 'Imp. Pesos Item',

dbo.fnCalPjeItem(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.IMP_BRUTO_ITEM) as 'Pje. Item', 
i.IMP_DESC_COMIS1 as 'Dcto. Comisión', ISNULL(i.IMP_COM_DIR1,0) AS 'Comis. Directa 1',
((dbo.fnCalculaPesos(f.F_REAL_PAGO, f.IMP_R_NETO_COM, f.CVE_R_MONEDA) *
dbo.fnCalPjeItem(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.IMP_BRUTO_ITEM) / 100) - i.IMP_DESC_COMIS1) *
(c.PJE_COMISION / 100) AS 'Comisión',

case
when p.CVE_PRODUCTO = 'PO' THEN

ROUND((((dbo.fnCalculaPesos(f.F_REAL_PAGO, f.IMP_R_NETO_COM, f.CVE_R_MONEDA) *
dbo.fnCalPjeItem(i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.IMP_BRUTO_ITEM) / 100) - i.IMP_DESC_COMIS1) *
(c.PJE_COMISION / 100) /12),2) 
else 0
end as 'Doceavo',

c.CVE_VENDEDOR as 'Vendedor', c.CVE_PROCESO as 'Proceso', c.PJE_COMISION as 'Pje. Comis.',
SUBSTRING(c.ANO_MES,1,4) + '/' + SUBSTRING(c.ANO_MES,5,6) AS 'Año/Mes', c.IMP_CUPON as 'Cupón', c.TX_NOTA as 'Nota'
FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_CUPON_COMISION c, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_CLIENTE ct  WHERE    
												   ((c.ANO_MES     = @panomes and @popcion  =  @k_fecha) or 
												    (c.FOL_PROCESO = @pfolio and @popcion   =  @k_folio)) and
                                                   f.CVE_EMPRESA = i.CVE_EMPRESA and
                                                   f.SERIE = i.SERIE and
                                                   f.ID_CXC = i.ID_CXC AND
                                                   i.CVE_EMPRESA = c.CVE_EMPRESA and
                                                   i.SERIE = c.SERIE and
                                                   i.ID_CXC = c.ID_CXC and
                                                   i.ID_ITEM = c.ID_ITEM and
                                                   i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO  AND
                                                   s.CVE_PRODUCTO = p.CVE_PRODUCTO  AND 
                                                   f.SERIE <> 'LEGACY'  AND
                                                   f.ID_VENTA = v.ID_VENTA and
                                                   v.ID_CLIENTE = ct.ID_CLIENTE   and 
                                                   c.FOL_PROCESO = @pfolio 
                                                   order by S.CVE_PRODUCTO, f.ID_CONCILIA_CXC, c.CVE_VENDEDOR, c.ANO_MES, i.F_INICIO
END
