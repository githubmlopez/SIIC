USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spLanzaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec spLanzaComision 2017,09,0

ALTER PROCEDURE [dbo].[spLanzaComision] @pano_proc int, @pmes_proc int, @fol_pcup int out
	
AS
BEGIN

/*  Declaración de Constantes  */

declare   @k_verdadero           bit,
          @k_falso               bit,
          @k_fol_pcup            varchar(4)

         
/*  Declaración de Variables para Factura  */

Declare   @id_concilia_cxc      int


set  @k_verdadero  =  1
set  @k_falso      =  0
set  @k_fol_pcup   =  'PCUP'
       

     set @fol_pcup  =  isnull((select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_pcup),0)

     UPDATE CI_FOLIO
     SET NUM_FOLIO = @fol_pcup + 1
     WHERE  CVE_FOLIO     = @k_fol_pcup

     set @fol_pcup  =  isnull((select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_pcup),0)

--     SELECT ' Folio Proceso ** ' + CONVERT(VARCHAR(10),@fol_pcup)


/*  Declara cursor para leer Facturas a Procesar   */


  	declare factura_cursor cursor for 
 	
  	SELECT distinct(f.ID_CONCILIA_CXC)    FROM   CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_VENTA v, CI_CLIENTE ct
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


--  	SELECT distinct(f.ID_CONCILIA_CXC)    FROM   CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_VENTA v, CI_CLIENTE ct
--	                                      WHERE  f.ID_CONCILIA_CXC IN (190) 
  	
    open  factura_cursor

    FETCH factura_cursor INTO @id_concilia_cxc      
    
--    SELECT ' ID CXC ** ' + CONVERT(VARCHAR(10),@id_concilia_cxc)
  
    
    WHILE (@@fetch_status = 0 )
    BEGIN 

--      SELECT ' ENTRO A CURSOR ** ' + CONVERT(VARCHAR(10),@id_concilia_cxc)

	  EXEC spCalculaComisionDef @pano_proc, @pmes_proc, @id_concilia_cxc, @fol_pcup
      FETCH factura_cursor INTO @id_concilia_cxc

    END 

    close factura_cursor 
    deallocate factura_cursor 
END