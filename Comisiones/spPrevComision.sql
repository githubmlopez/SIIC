USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spPrevComision]    Script Date: 29/08/2017 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC spPrevComision 2017,08
ALTER PROCEDURE [dbo].[spPrevComision] @pano_proc int, @pmes_proc int
AS
BEGIN


-- SELECT CONVERT(varchar(4),@pano_proc) +  replicate ('0',(02 - len(@pmes_proc))) + convert(varchar, @pmes_proc) 
-- SELECT CONVERT(varchar(4),YEAR('2017-02-01')) +  replicate ('0',(02 - len(MONTH('2017-02-01')))) + convert(varchar, MONTH('2017-02-01')) 


SELECT f.ID_CONCILIA_CXC as 'Id. Concilia', f.SERIE as 'Serie', f.ID_CXC as 'Id. CXC', f.F_OPERACION as 'F. Operacion', f.IMP_F_BRUTO as 'Imp. F Bruto', f.CVE_F_MONEDA as 'Cve Moneda',
       ct.NOM_CLIENTE as 'Nombre Cliente', s.DESC_SUBPRODUCTO as 'Desc Subproducto', f.F_REAL_PAGO as 'F Pago', f.IMP_R_NETO_COM as 'Imp Comisión', f.CVE_R_MONEDA as 'Cve Mon Liq', f.TIPO_CAMBIO_LIQ as 'Tipo Camb Liq',
       case 
       when i.F_INICIO is null then ' ' 
       when i.F_INICIO = '19000101' then ' ' 
       else LEFT(CONVERT(VARCHAR, i.F_INICIO, 120), 10) 
       end as 'F. Inicio', 
       case 
       when i.F_FIN is null then ' ' 
       when i.F_FIN = '19000101' then ' ' 
       else LEFT(CONVERT(VARCHAR, i.F_FIN, 120), 10) 
       end as 'F. Fin', 
       i.IMP_BRUTO_ITEM as 'Imp. Item',    
  	   i.CVE_VENDEDOR1 as 'Vendedor 1', i.CVE_PROCESO1 as ' Proceso 1', i.CVE_ESPECIAL1 as 'Especial 1', dbo.fnCalComisVen(i.CVE_SUBPRODUCTO, i.CVE_PROCESO1, i.CVE_VENDEDOR1, i.CVE_ESPECIAL1)  as Comision1,  i.IMP_COM_DIR1 as 'Com Dir 1', i.IMP_DESC_COMIS1 as 'Imp Desc Com1', isnull(i.CVE_VENDEDOR2, ' ') as 'Vendedor 2', isnull(i.CVE_PROCESO2, ' ') as 'Proceso 2', isnull(i.CVE_ESPECIAL2,' ') as 'Especial 2', 
  	   dbo.fnCalComisVen(i.CVE_SUBPRODUCTO, i.CVE_PROCESO2, i.CVE_VENDEDOR2, i.CVE_ESPECIAL2)  as Comision2, i.IMP_COM_DIR2 as 'Com Dir 2', i.IMP_DESC_COMIS2 as 'Imp Desc Com2'
  	                                      FROM   CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_VENTA v, CI_CLIENTE ct
  	                                      WHERE   
--                                        join Factura - Item
          	                                      f.CVE_EMPRESA      = i.CVE_EMPRESA                             AND 
                                                  f.SERIE            = i.SERIE                                   AND
                                                  f.ID_CXC           = i.ID_CXC                                  AND
--                                        join con  Subproducto
                                                  i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO                          AND
--                                        join con  Ventas y Clientes
                                                  f.ID_VENTA        = v.ID_VENTA                                 AND
                                                  v.ID_CLIENTE      = ct.ID_CLIENTE                              AND
--                                        Verifica que no tenga cupones ya pagados
                                                  NOT EXISTS  (SELECT 1 FROM CI_CUPON_COMISION c WHERE 
															   i.CVE_EMPRESA  = c.CVE_EMPRESA                    AND
															   i.SERIE        = c.SERIE                          AND
                                                               i.ID_CXC       = c.ID_CXC                         AND
                                                               i.ID_ITEM      = c.ID_ITEM)                       AND
--                                        Verifica que el producto paga comision o mantenimiento
                                                   EXISTS      (SELECT 1 FROM CI_SUBPRODUCTO s, CI_PRODUCTO p WHERE        
                                                               i.CVE_SUBPRODUCTO  =  s.CVE_SUBPRODUCTO           AND
                                                               s.CVE_PRODUCTO     =  p.CVE_PRODUCTO              AND
                                                              (p.B_PAGA_COMISION  = 1 or p.B_MANTENIMIENTO =1))  AND
--                                        Verifica que la fecha de inicio sea valida 
                                                 ((i.F_INICIO IS NOT NULL)                                       OR
                                                  (i.F_INICIO IS NULL AND s.CVE_PRODUCTO <>  'PO')               OR
                                                  (i.F_INICIO = '1900-01-01' AND s.CVE_PRODUCTO <>  'PO'))       AND
--                                        Verifica que el vendedor sea válido      
                                                   i.CVE_VENDEDOR1 NOT IN ('GNCO','INFI','NOAN','VESC')          AND
--                                        Verifica que no sean Pólizas LEGACY      
                                                   f.SERIE <> 'LEGACY'                                           AND 
--                                        Verifica que esten conciliadas las facturas                                                   
                                                   f.SIT_CONCILIA_CXC IN ('CC','CE')                             AND
--                                        Verifica que clave especial esto se utilizará solo para cierto items                                                   
                                                  (i.IMP_COM_DIR2 <> 99999                                       OR
                                                   i.IMP_COM_DIR2 IS NULL)                                       AND
--                                        Verifica que clave especial esto se utilizará solo para cierto items                                                   
                                                   f.SIT_TRANSACCION  = 'A'                                      AND
                                                   CONVERT(varchar(4),@pano_proc) +  replicate ('0',(02 - len(@pmes_proc))) + convert(varchar, @pmes_proc) >=
                                                   CONVERT(varchar(4),YEAR(f.F_REAL_PAGO)) +  replicate ('0',(02 - len(MONTH(f.F_REAL_PAGO)))) + convert(varchar, MONTH(f.F_REAL_PAGO)) 
                                                   order by f.ID_CONCILIA_CXC, s.DESC_SUBPRODUCTO
END
                                                   
