Declare @ano int,
        @mes int
        
set @ano = 2016
set @mes = 11

select f.ID_CONCILIA_CXC from CI_FACTURA f WHERE MONTH(f.F_REAL_PAGO) = @mes and YEAR(f.F_REAL_PAGO) = @ano and
                                                 f.ID_CONCILIA_CXC not in

(SELECT distinct(f.ID_CONCILIA_CXC) 
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
                                                   CVE_VENDEDOR1 NOT IN ('GNCO','INFI','NOAN','VESC')            AND
--                                        Verifica que no sean Pólizas LEGACY      
                                                   f.SERIE <> 'LEGACY'                                           AND 
--                                        Verifica que esten conciliadas las facturas                                                   
                                                   f.SIT_CONCILIA_CXC IN ('CC','CE')                             AND
--                                        Verifica que clave especial esto se utilizará solo para cierto items                                                   
                                                   i.IMP_COM_DIR2 <> 99999                                       AND
                                                   MONTH(f.F_REAL_PAGO) = 11 and YEAR(f.F_REAL_PAGO) = 2016)
