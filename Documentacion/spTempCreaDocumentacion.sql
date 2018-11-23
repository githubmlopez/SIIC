/*

delete from CI_DOCUM_ITEM
select count(*) from CI_DOCUM_ITEM
exec spTempCreaDocumentacion
SELECT  i.CVE_EMPRESA, i.SERIE, i.ID_CXC, i.ID_ITEM, c.NOM_CLIENTE, ve.NOM_VENDEDOR, t.DESC_DOCUMENTO,
s.DESC_SUBPRODUCTO, d.SITUACION
FROM CI_DOCUM_ITEM d, CI_ITEM_C_X_C i, CI_FACTURA f, CI_SUBPRODUCTO s, CI_TIPO_DOCUMENTO t, CI_VENDEDOR ve,
CI_VENTA v, CI_CLIENTE c
where d.CVE_EMPRESA = i.CVE_EMPRESA AND
d.SERIE = i.SERIE AND
d.ID_CXC = i.ID_CXC AND
d.ID_ITEM = i.ID_ITEM and
d.CVE_EMPRESA = f.CVE_EMPRESA AND
d.SERIE = f.SERIE AND
d.ID_CXC = f.ID_CXC AND
i.CVE_SUBPRODUCTO = s.CVE_SUBPRODUCTO AND
d.CVE_TIPO_DOCUM = t.CVE_TIPO_DOCUM AND
f.ID_VENTA = v.ID_VENTA and
v.ID_CLIENTE = c.ID_CLIENTE and
i.CVE_VENDEDOR1 = ve.CVE_VENDEDOR ORDER BY i.CVE_VENDEDOR1, c.ID_CLIENTE, f. SERIE, f.ID_CXC 
 

*/

USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure [dbo].[spTempCreaDocumentacion] 
AS

BEGIN

declare
   @cve_empresa       varchar(4),
   @serie             varchar(6),
   @id_cxc            int,
   @id_item           int,
   @cve_subproducto   varchar(8),
   @imp_bruto_item    numeric(12,2),
   @f_inicio          date,
   @f_fin             date,
   @imp_est_cxp       numeric(12,2),
   @imp_real_cxp      numeric(12,2),
   @cve_proceso1      varchar(4),
   @cve_vendedor1     varchar(4),
   @cve_especial1     varchar(2),
   @imp_desc_comis1   numeric(12,2),
   @imp_com_dir1      numeric(12,2),
   @cve_proceso2      varchar(4),
   @cve_vendedor2     varchar(4),
   @cve_especial2     varchar(2),
   @imp_desc_comis2   numeric(12,2),
   @imp_com_dir2      numeric(12,2),
   @sit_item_cxc      varchar(2),
   @tx_nota           varchar(400),
   @f_fin_instalacion varchar(2),
   @cve_renovacion    int,
   @cve_empresa_reno  varchar(4),
   @serie_reno        varchar(6),
   @id_cxc_reno       int,
   @id_item_reno      int;


declare 
   
    @cve_producto_i   varcHAR(4),
    @cve_tipo_docum   varchar(2)
    

declare @cve_producto varchar(4)

-- CREA REGISTROS PARA CONTROL DE DOCUMENTACION

declare item_cursor cursor for SELECT 
           [CVE_EMPRESA]
           ,[SERIE]
           ,[ID_CXC]
           ,[ID_ITEM]
           ,[CVE_SUBPRODUCTO]
           ,[IMP_BRUTO_ITEM]
           ,[F_INICIO]
           ,[F_FIN]
           ,[IMP_EST_CXP]
           ,[IMP_REAL_CXP]
           ,[CVE_PROCESO1]
           ,[CVE_VENDEDOR1]
           ,[CVE_ESPECIAL1]
           ,[IMP_DESC_COMIS1]
           ,[IMP_COM_DIR1]
           ,[CVE_PROCESO2]
           ,[CVE_VENDEDOR2]
           ,[CVE_ESPECIAL2]
           ,[IMP_DESC_COMIS2]
           ,[IMP_COM_DIR2]
           ,[SIT_ITEM_CXC]
           ,[TX_NOTA]
           ,[F_FIN_INSTALACION]
           ,[CVE_RENOVACION]
           ,[CVE_EMPRESA_RENO]
           ,[SERIE_RENO]
           ,[ID_CXC_RENO]
           ,[ID_ITEM_RENO] FROM CI_ITEM_C_X_C  WHERE SERIE <> 'LEGACY'     and
                                                    (F_FIN = '1900-01-01'  or
                                                     F_FIN is null         or
                                                    (F_FIN >= '2017-05-03'    and
                                                     SUBSTRING(CVE_SUBPRODUCTO,1,1) = 'P')) 
           
open  item_cursor

FETCH item_cursor INTO
   @cve_empresa,
   @serie,
   @id_cxc,
   @id_item,
   @cve_subproducto,
   @imp_bruto_item,
   @f_inicio,
   @f_fin,
   @imp_est_cxp,
   @imp_real_cxp,
   @cve_proceso1,
   @cve_vendedor1,
   @cve_especial1,
   @imp_desc_comis1,
   @imp_com_dir1,
   @cve_proceso2,
   @cve_vendedor2,
   @cve_especial2,
   @imp_desc_comis2,
   @imp_com_dir2,
   @sit_item_cxc,
   @tx_nota,
   @f_fin_instalacion,
   @cve_renovacion,
   @cve_empresa_reno,
   @serie_reno,
   @id_cxc_reno,
   @id_item_reno  

WHILE (@@fetch_status = 0 )
BEGIN
    IF  @id_cxc = 522
    BEGIN
      SELECT 'ENTRA 1'
    END
    
    set  @cve_producto  =  (SELECT CVE_PRODUCTO FROM CI_SUBPRODUCTO WHERE  CVE_SUBPRODUCTO  =  @cve_subproducto)	

    IF  @id_cxc = 522
    BEGIN
      SELECT 'ENTRA 1 ' + @cve_producto
    END

    IF EXISTS (SELECT 1 FROM CI_DOCUM_PRODUCTO  WHERE CVE_PRODUCTO = @cve_producto) and
       (select SIT_TRANSACCION FROM CI_FACTURA WHERE CVE_EMPRESA =  @cve_empresa AND SERIE = @serie and
                                                     ID_CXC = @id_cxc) = 'A'            
       
    BEGIN
 
     IF  @id_cxc = 522
    BEGIN
      SELECT 'ENTRA 2' 
    END
     
      declare docum_cursor cursor for SELECT CVE_PRODUCTO, CVE_TIPO_DOCUM FROM CI_DOCUM_PRODUCTO
                                      WHERE CVE_PRODUCTO = @cve_producto 
      open  docum_cursor

      FETCH docum_cursor INTO  @cve_producto_i, @cve_tipo_docum  
    
      WHILE (@@fetch_status = 0 )
      BEGIN 
        Insert into CI_DOCUM_ITEM
                   (CVE_EMPRESA,
                    SERIE,
                    ID_CXC,
                    ID_ITEM,
                    CVE_TIPO_DOCUM,
                    SITUACION, 
                    NOMBRE_DOCTO_PDF)
               values     
                   (@cve_empresa,
                    @serie,
                    @id_cxc,
                    @id_item,
                    @cve_tipo_docum,
                    'P',
                    ' ')     

        FETCH docum_cursor INTO  @cve_producto_i, @cve_tipo_docum  

      END
      CLOSE docum_cursor 
      deallocate docum_cursor 
   
    END

FETCH item_cursor INTO
   @cve_empresa,
   @serie,
   @id_cxc,
   @id_item,
   @cve_subproducto,
   @imp_bruto_item,
   @f_inicio,
   @f_fin,
   @imp_est_cxp,
   @imp_real_cxp,
   @cve_proceso1,
   @cve_vendedor1,
   @cve_especial1,
   @imp_desc_comis1,
   @imp_com_dir1,
   @cve_proceso2,
   @cve_vendedor2,
   @cve_especial2,
   @imp_desc_comis2,
   @imp_com_dir2,
   @sit_item_cxc,
   @tx_nota,
   @f_fin_instalacion,
   @cve_renovacion,
   @cve_empresa_reno,
   @serie_reno,
   @id_cxc_reno,
   @id_item_reno  

END

CLOSE item_cursor 
deallocate item_cursor 


END
