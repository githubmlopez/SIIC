USE [ADMON01]

declare  @ano_proc  int,
         @mes_proc  int

set  @ano_proc = 2017
set  @mes_proc = 01

SELECT fp.ID_CONCILIA_CXC as 'Id. Concilia', fp.SERIE as 'Serie', fp.ID_CXC as 'Id. CXC', fp.F_OPERACION as 'F. Operacion', fp.IMP_F_BRUTO as 'Imp. F Bruto', fp.CVE_F_MONEDA as 'Cve Moneda',
       ct.NOM_CLIENTE as 'Nombre Cliente', s.DESC_SUBPRODUCTO as 'Desc Subproducto', fp.F_REAL_PAGO as 'F Pago', fp.IMP_R_NETO_COM as 'Imp Comisión', fp.CVE_R_MONEDA as 'Cve Mon Liq', fp.TIPO_CAMBIO_LIQ as 'Tipo Camb Liq',
       case 
       when i.F_INICIO is null then ' ' 
       when i.F_INICIO = '19000101' then ' ' 
       else LEFT(CONVERT(VARCHAR, i.F_INICIO, 120), 10) 
       end as 'F. Inicio', 
       case 
       when i.F_FIN is null then ' ' 
       when i.F_FIN = '19000101' then ' ' 
       else LEFT(CONVERT(VARCHAR, i.F_INICIO, 120), 10) 
       end as 'F. Fin', 
       i.IMP_BRUTO_ITEM as 'Imp. Item',    
  	   i.CVE_VENDEDOR1 as 'Vendedor 1', i.CVE_PROCESO1 as ' Proceso 1', i.CVE_ESPECIAL1 as 'Especial 1', dbo.fnCalComisVen(i.CVE_SUBPRODUCTO, i.CVE_PROCESO1, i.CVE_VENDEDOR1, i.CVE_ESPECIAL1)  as Comision1,  i.IMP_COM_DIR1 as 'Com Dir 1', i.IMP_DESC_COMIS1 as 'Imp Desc Com1', isnull(i.CVE_VENDEDOR2, ' ') as 'Vendedor 2', isnull(i.CVE_PROCESO2, ' ') as 'Proceso 2', isnull(i.CVE_ESPECIAL2,' ') as 'Especial 2', 
  	   dbo.fnCalComisVen(i.CVE_SUBPRODUCTO, i.CVE_PROCESO2, i.CVE_VENDEDOR2, i.CVE_ESPECIAL2)  as Comision2, i.IMP_COM_DIR2 as 'Com Dir 2', i.IMP_DESC_COMIS2 as 'Imp Desc Com2'
  	                                      FROM   CI_FACTURA fp, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_VENTA v, CI_CLIENTE ct
  	                                      WHERE   
--                                        join Factura - Item
          	                                      fp.CVE_EMPRESA      = i.CVE_EMPRESA                            AND 
                                                  fp.SERIE            = i.SERIE                                  AND
                                                  fp.ID_CXC           = i.ID_CXC                                 AND
--                                        join con  Subproducto
                                                  i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO                          AND
--                                        join con  Ventas y Clientes
                                                  fp.ID_VENTA        = v.ID_VENTA                                AND
                                                  v.ID_CLIENTE      = ct.ID_CLIENTE                              AND
--                                        Verifica que clave especial esto se utilizará solo para cierto items                                                   
                                                   fp.SIT_TRANSACCION  = 'A'                                     AND
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
--                                        Verifica que el vendedor sea válido      
                                                   i.CVE_VENDEDOR1 NOT IN ('GNCO','INFI','NOAN','VESC')          AND
--                                        Verifica que no sean Pólizas LEGACY      
                                                   fp.SERIE <> 'LEGACY'                                          AND 
--                                        Verifica que esten conciliadas las facturas                                                   
                                                   fp.SIT_CONCILIA_CXC IN ('CC','CE')                            AND
--                                        Verifica que clave especial esto se utilizará solo para cierto items                                                   
                                                  (i.IMP_COM_DIR2 <> 99999                                       OR
                                                   i.IMP_COM_DIR2 IS NULL)                                       AND
not exists
(SELECT f.ID_CONCILIA_CXC 
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
                                                   f.SIT_TRANSACCION  = 'A')
                                                   order by fp.ID_CONCILIA_CXC, s.DESC_SUBPRODUCTO
