USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCalculaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter PROCEDURE [dbo].[spCalculaComisionDef]  @pano_proc int, @pmes_proc int, @pid_concilia_cxc  int, @fol_pcup int
AS
BEGIN

/*  Declaración de Constantes  */

declare   @k_verdadero           bit,
          @k_falso               bit,
          @k_activa              varchar(2),
          @k_peso                varchar(1),
          @k_dolar               varchar(1),
          @k_sin_param           varchar(2),
          @k_cero_uno            varchar(4),
          @k_fol_audit           varchar(4),
          @k_fol_pcup            varchar(4)
/*  Declaración de Variables para CI_ITEM_C_X_C  */

declare
          @cve_subproducto       varchar(8),
          @id_item               int,   
          @imp_bruto_item        numeric(12,2), 
          @imp_desc_comis1       numeric(12,2), 
          @imp_desc_comis2       numeric(12,2), 
          @imp_com_dir1          numeric(12,2),
          @imp_com_dir2          numeric(12,2), 
          @f_inicio              date,
          @f_fin                 date,
          @cve_vendedor1         varchar(4),
          @cve_proceso1          varchar(4),
          @cve_especial1         varchar(2),
          @cve_vendedor2         varchar(4),
          @cve_especial2         varchar(2),
          @cve_proceso2          varchar(4)

/*  Declaración de variables para CI_FACTURA */ 

declare   @f_operacion           date,
          @f_real_pago           date,
          @imp_neto_com          numeric(12,2),
          @tipo_cambio           numeric(8,2),
          @cve_r_moneda          varchar(1),
          @cve_empresa           varchar(4),
          @serie                 varchar(6),
          @id_cxc                int


/*  Declaración de variables para CI_VENTA_FACTURA */ 

declare   @imp_c_bruto           numeric(12,2)

/*  Declaración de variables para CI_PRODUCTO */ 

declare   @cve_producto          varchar(4),
          @b_paga_comision       bit,
          @b_paga_comis_vend1    bit,
          @b_paga_comis_vend2    bit,
          @b_mantenimiento       bit
 

declare   @tx_error              varchar(200),
          @tx_error_rise         varchar(200),
          @tx_error_part         varchar(200),
          @b_fact_pagada         bit,
          @sit_transaccion       varchar(2),
          @b_seg_vendedor        varchar(1),
          @b_conv_pesos          varchar(1),
          @b_fact_valida         varchar(1),
          @mes_inicio_cxc        int,      
          @mes_real_pago         int,
          @meses_prim_pago       int,
          @pje_comis_ven1        numeric(8,2),
          @pje_comis_ven2        numeric(8,2),
          @imp_c_neto            numeric(12,2),
          @imp_neto_com_c        numeric(12,2),
          @imp_bruto_item_c      numeric(12,2), 
          @imp_c_bruto_c         numeric(12,2),
          @id_venta              int,
          @id_fact_parcial       int,
          @pje_item_fact         numeric(9,6),
          @imp_com_x_pagar1      numeric(12,2), 
          @imp_com_x_pagar2      numeric(12,2),
          @tipo_cam_pago         numeric(8,2),
          @cve_moneda_fact       varchar(2),          
          @f_hoy                 date,
          @num_cupon             int,
          @num_meses_rest        int,
          @ano                   int,
          @mes                   int
          
          
set  @k_verdadero  =  1
set  @k_falso      =  0
set  @k_activa     =  'A'
set  @k_peso       =  'P'
set  @k_dolar      =  'D'
set  @k_sin_param  =  'SP'
set  @k_fol_audit  = 'AUDI'
set  @k_fol_pcup   = 'PCUP'
set  @k_cero_uno   =  'CU'
          
set  @f_hoy        =  GETDATE()  
       
IF  EXISTS  (SELECT  1  FROM   CI_FACTURA WHERE  ID_CONCILIA_CXC = @pid_concilia_cxc)
BEGIN -- 0

/*  Obtiene información de CI_FACTURA   */

  SELECT  @f_operacion = F_OPERACION, @f_real_pago = F_REAL_PAGO, @imp_neto_com = IMP_R_NETO_COM, @tipo_cambio = TIPO_CAMBIO_LIQ,
          @cve_r_moneda = CVE_R_MONEDA, @id_venta = ID_VENTA, @id_fact_parcial = ID_FACT_PARCIAL,
          @b_fact_pagada = B_FACTURA_PAGADA, @sit_transaccion =  SIT_TRANSACCION, @imp_c_bruto  =  IMP_F_BRUTO, @cve_moneda_fact = CVE_F_MONEDA,
          @cve_empresa = CVE_EMPRESA, @serie = SERIE, @id_cxc = ID_CXC FROM CI_FACTURA WHERE ID_CONCILIA_CXC = @pid_concilia_cxc
  
--  IF  @b_fact_pagada  =  @k_verdadero and @sit_transaccion = @k_activa  
  IF  @sit_transaccion = @k_activa  
  BEGIN -- 1
  	                                                            
/*  Obtiene información de CI_VENTA_FACTURA   */

--    SELECT  @imp_c_bruto  =  IMP_C_BRUTO, @cve_moneda_fact = CVE_C_MONEDA  FROM  CI_VENTA_FACTURA  
--                                                                           WHERE ID_VENTA         = @id_venta  AND 
--                                                                                 ID_FACT_PARCIAL  = @id_fact_parcial 


/*  Declara cursor para leer CI_ITEM_C_X_C   */


  	declare item_cursor cursor for SELECT i.CVE_EMPRESA, i.CVE_SUBPRODUCTO, ID_ITEM, IMP_BRUTO_ITEM, IMP_DESC_COMIS1, IMP_DESC_COMIS2, F_INICIO, F_FIN, 
  	                                      i.CVE_VENDEDOR1, i.CVE_PROCESO1, i.CVE_ESPECIAL1, i.CVE_VENDEDOR2, i.CVE_PROCESO2, i.CVE_ESPECIAL2, i.IMP_COM_DIR1, i.IMP_COM_DIR2
  	                                      FROM   CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO su
  	                                      WHERE  i.CVE_EMPRESA     = @cve_empresa                                AND
  	                                             i.SERIE           = @serie                                      AND  
  	                                             i.ID_CXC          = @id_cxc                                     AND
--                                        join Factura - Item
          	                                     f.CVE_EMPRESA      = i.CVE_EMPRESA                              AND 
                                                 f.SERIE            = i.SERIE                                    AND
                                                 f.ID_CXC           = i.ID_CXC                                   AND
--                                        join con  Subproducto
  	                                             i.CVE_SUBPRODUCTO = su.CVE_SUBPRODUCTO                          AND              
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
                                                              (p.B_PAGA_COMISION  = 1 or p.B_MANTENIMIENTO = 1)) AND
--                                        Verifica que la fecha de inicio sea valida 
                                                 ((i.F_INICIO IS NOT NULL)                                       OR
                                                  (i.F_INICIO IS NULL AND su.CVE_PRODUCTO <>  'PO')              OR
                                                  (i.F_INICIO = '1900-01-01' AND su.CVE_PRODUCTO <>  'PO'))      AND
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


  
    open  item_cursor

    FETCH item_cursor INTO  @cve_empresa, @cve_subproducto, @id_item, @imp_bruto_item, @imp_desc_comis1, @imp_desc_comis2, @f_inicio,
                            @f_fin, @cve_vendedor1, @cve_proceso1, @cve_especial1, @cve_vendedor2, @cve_proceso2,@cve_especial2, @imp_com_dir1, @imp_com_dir2  
    
    WHILE (@@fetch_status = 0 )
    BEGIN -- 2
	  set  @num_cupon              =  0
	  set  @b_paga_comis_vend1     =  @k_falso
	  set  @b_seg_vendedor         =  @k_falso
      set  @b_paga_comis_vend2     =  @k_falso
	  
      
      SELECT @cve_producto  =  CVE_PRODUCTO FROM  CI_SUBPRODUCTO  where  CVE_SUBPRODUCTO =  @cve_subproducto   

      SELECT @b_paga_comision = B_PAGA_COMISION, @b_mantenimiento = B_MANTENIMIENTO  FROM CI_PRODUCTO       WHERE 
                                                                                          CVE_PRODUCTO      =  @cve_producto

      SELECT  @b_paga_comis_vend1 =  B_PAGA_COMISION FROM CI_VENDEDOR WHERE CVE_VENDEDOR = @cve_vendedor1


      --SELECT '*** ITEM *** ' + cast(@id_item as varchar(12))
      --SELECT '*** DATOS COMISION ***' +  ' ' + @cve_producto + ' ' + @cve_proceso1 + ' ' + @cve_vendedor1 
      --SELECT '*** PAGA COMISION ***' +  ' ' + cast(@b_paga_comis_vend1 as varchar(1))
      set  @pje_comis_ven1  =  0

 --SELECT 'PREGUNTANDO POR BANDERA COMISION VENDEDOR 1 ' 
  
      IF  @b_paga_comis_vend1 = @k_verdadero
      BEGIN -- 50
  
 --SELECT 'VERIFICANDO VENDEDOR 1 ' 

         IF EXISTS  (select 1 FROM  CI_PROD_PROCESO WHERE  CVE_PRODUCTO        = @cve_producto   AND
                                                           CVE_PROCESO         = @cve_proceso1   AND
                                                           CVE_VENDEDOR        = @cve_vendedor1  AND
                                                           CVE_ESPECIAL        = @cve_especial1) 
                                                        
         BEGIN  -- 3
 
 /* Obtiene porcentaje de comision a cobrar para el vendedor 1   */
 
            select  @pje_comis_ven1 =  PJE_COMISION  FROM  CI_PROD_PROCESO WHERE  CVE_PRODUCTO   = @cve_producto   AND
                                                                               CVE_PROCESO    = @cve_proceso1   AND
                                                                               CVE_VENDEDOR   = @cve_vendedor1  AND
                                                                               CVE_ESPECIAL   = @cve_especial1      
           --SELECT 'PJE COMIS VEN1 ' + CAST(@pje_comis_ven1 AS varchar(10))
         END  -- 3
         ELSE
         BEGIN  -- 4
           --select '99'
           set @tx_error_part   = ' No existe comision para vendedor1'
           set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @serie + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
           set @tx_error_rise   = 'No existe comision para vendedor1'
           execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
        
         END   -- 4                                                 
 
      END  -- 50
--SELECT 'VERIFICANDO VENDEDOR 2 ' 
      IF EXISTS  (SELECT 1 FROM  CI_VENDEDOR WHERE CVE_VENDEDOR = @cve_vendedor2)
      BEGIN -- 5
--SELECT 'SI EXISTE VENDEDOR 2'
               
        set  @b_seg_vendedor  =  @k_verdadero
        
        SELECT  @b_paga_comis_vend2 =  B_PAGA_COMISION FROM CI_VENDEDOR WHERE CVE_VENDEDOR = @cve_vendedor2


/* Obtiene porcentaje de comision a cobrar para el vendedor 2   */

        set @pje_comis_ven2 = 0
  
        IF  @b_paga_comis_vend2  =  @k_verdadero
        BEGIN -- 51
 
          IF EXISTS  (SELECT 1 FROM  CI_PROD_PROCESO WHERE  CVE_PRODUCTO        = @cve_producto   AND
                                                            CVE_PROCESO         = @cve_proceso2   AND
                                                            CVE_VENDEDOR        = @cve_vendedor2  AND
                                                            CVE_ESPECIAL        = @cve_especial2) 
                                                         
          BEGIN  -- 6
            select  @pje_comis_ven2 =  PJE_COMISION  FROM  CI_PROD_PROCESO WHERE  CVE_PRODUCTO   = @cve_producto   AND
                                                                                  CVE_PROCESO    = @cve_proceso2   AND
                                                                                  CVE_VENDEDOR   = @cve_vendedor2  AND
                                                                                  CVE_ESPECIAL   = @cve_especial2      
 
          --SELECT 'PJE COMIS VEN2 ' + CAST(@pje_comis_ven2 AS varchar(10))
          END  -- 6 
          ELSE
          BEGIN  -- 7
            --select '2'
            set @tx_error_part   = ' No existe comision para vendedor2'
            set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @serie + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
            set @tx_error_rise   = 'No existe comision para vendedor2'
            execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
          END    -- 7                                              
 
        END -- 51
 
      END  -- 5

      IF EXISTS (SELECT 1  FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_real_pago)
      BEGIN  -- 8
        SELECT @tipo_cam_pago = TIPO_CAMBIO  FROM CI_TIPO_CAMBIO WHERE F_OPERACION = @f_real_pago
      END  -- 8
      ELSE 
      BEGIN -- 9
        --select '3'
        set @tx_error_part   = ' No existe tipo de cambio para el dia de pago'
        set @tx_error        = 'Error CI_TIPO_CAMBIO : ' + LEFT(CONVERT(VARCHAR, @f_real_pago, 120), 10) + ' ' +@tx_error_part
        set @tx_error_rise   = 'No existe comision para vendedor2'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 

      END -- 9
      --select 'Voy a desplegar banderas ****'
      --select '***** BANDERAS ' + convert(varchar, @b_paga_comision) + convert(varchar, @b_mantenimiento)
      --select CAST(@tipo_cam_pago AS varchar(18))
      --select CAST(@imp_neto_com AS varchar(18))
      --select CAST(@imp_bruto_item AS varchar(18))
      --select CAST(@imp_c_bruto AS varchar(18))
      --select @cve_moneda_fact
      --select @cve_r_moneda
      --select 'Monedas ****' + ' ' + @cve_moneda_fact + ' ' + @cve_r_moneda
      
      set  @imp_neto_com_c    =   @imp_neto_com
      set  @imp_c_bruto_c     =   @imp_c_bruto
      set  @imp_bruto_item_c  =   @imp_bruto_item
      
      IF  @cve_moneda_fact  <>  @cve_r_moneda 
      BEGIN  -- 10
        --select ' Entro a 10'
        IF  @cve_r_moneda  =   @k_dolar
        BEGIN
          set  @imp_neto_com_c   =   @imp_neto_com  *  @tipo_cam_pago
        END     -- 10           
        ELSE
        BEGIN  -- 11
          --select ' Entro a 11'
          set  @imp_c_bruto_c    =  @imp_c_bruto  *  @tipo_cam_pago             
          set  @imp_bruto_item_c  =  @imp_bruto_item  *  @tipo_cam_pago             
          --select 'conv dolar' + CAST(@imp_bruto_item AS varchar(18))
        END  --11
      END
      ELSE
      IF  @cve_moneda_fact  =  @k_dolar
      BEGIN  -- 12
        --select ' Entro a 12'
        set  @imp_c_bruto_c     =  @imp_c_bruto     *  @tipo_cam_pago             
        set  @imp_neto_com_c   =   @imp_neto_com    *  @tipo_cam_pago
        set  @imp_bruto_item_c  =  @imp_bruto_item  *  @tipo_cam_pago  
      END  -- 12
  
      --SELECT ' ** IMP NETO COM IMP B  ITEM ****' + '   '  +  CAST(@imp_neto_com_c as varchar(20)) + '  ' + CAST(@imp_bruto_item_c as varchar(20)) +
      --'   ' + CAST(@imp_c_bruto_c as varchar(20))
  
      set @pje_item_fact  =  @imp_bruto_item_c / @imp_c_bruto_c

      --select '** pje division' + CAST(@pje_item_fact AS varchar(18))

  
      IF @b_mantenimiento  =  @k_verdadero AND (@b_paga_comis_vend1  =  @k_verdadero OR  @b_paga_comis_vend2  =  @k_verdadero) 
      BEGIN  -- 13
        --SELECT '***** ENTRE A PAGA MANTENIMIENTO****', LEFT(CONVERT(VARCHAR, @f_inicio, 120), 10) + '  ' + LEFT(CONVERT(VARCHAR, @f_real_pago, 120), 10)
 
        set @mes_inicio_cxc  = MONTH(@f_inicio)	
        set @mes_real_pago   = MONTH(@f_real_pago)
        
        IF  @f_real_pago > @f_inicio
        BEGIN
          --SELECT '***** fecha real mayor ****'
          set @ano  = YEAR(@f_real_pago)
          set @mes  = MONTH(@f_real_pago)
          IF
          CONVERT(varchar(4),@pano_proc) +  replicate ('0',(02 - len(@pmes_proc))) + convert(varchar, @mes) >
          CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes) 
          BEGIN
            set @ano  = @pano_proc
            set @mes  = @pmes_proc
          END  
          IF @mes_real_pago - @mes_inicio_cxc < 0
          BEGIN
            set @meses_prim_pago  =  (@mes_real_pago + 12) - @mes_inicio_cxc + 1
          END
          ELSE
          BEGIN
            set @meses_prim_pago  =  @mes_real_pago - @mes_inicio_cxc + 1
          END
        END
        ELSE
        BEGIN
          --SELECT '***** fecha inicio = o mayor ****'
          set @ano  = YEAR(@f_inicio);
          set @mes  = MONTH(@f_inicio)
          IF
          CONVERT(varchar(4),@pano_proc) +  replicate ('0',(02 - len(@pmes_proc))) + convert(varchar, @pmes_proc) >
          CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes) 
          BEGIN
            set @ano  = @pano_proc
            set @mes  = @pmes_proc
          END  
          set @meses_prim_pago  =  1
        END
 
        --select ' mes inicio ***', CAST(@mes_inicio_cxc AS varchar(18))
        --select ' mes inicioR ***', CAST(@mes_real_pago AS varchar(18))
        
 --       set @meses_prim_pago  =  @mes_real_pago - @mes_inicio_cxc + 1
 
        --select ' mes primer ***', CAST(@meses_prim_pago AS varchar(18)), ' ' + CAST(@imp_neto_com_c AS varchar(20))
       
        set @imp_com_x_pagar2 =  0  
        --SELECT ' ** IN Fact comis desc ****' + '   '  +  CAST(@imp_neto_com_c as varchar(20)) + '  ' + CAST(@pje_item_fact as varchar(20)) +
        --'   ' + CAST(@pje_comis_ven1 as varchar(20)) +  ' ** ' + CAST(@imp_desc_comis1 as varchar(20))
        IF  ISNULL(@imp_com_dir1, 0.00) = 0
        BEGIN
          set @imp_desc_comis1 = ISNULL(@imp_desc_comis1, 0.00)
          set @imp_com_x_pagar1 = (((@imp_neto_com_c - @imp_desc_comis1)* @pje_item_fact) *  @pje_comis_ven1) / 100 
 --         SELECT ' ** a pagar  ****' + '   '  +  CAST(@imp_com_x_pagar1 as varchar(20))
        END
        ELSE
        BEGIN
          set @imp_com_x_pagar1 = @imp_com_dir1
        END
         --SELECT ' ** a pagar  Directo ****' + '   '  +  CAST(@imp_com_x_pagar1 as varchar(20))
         --SELECT ' ** a pagar 12 ****' + '   '  +  CAST(@imp_com_x_pagar1 as varchar(20))
        set @imp_com_x_pagar1 = @imp_com_x_pagar1 / 12      
/*  Genera cupones de comisión mantenimiento para Vendedor 1 */ 
   
        IF  @imp_com_x_pagar1  > 0  and @b_paga_comis_vend1 = @k_verdadero
        BEGIN  -- 15
  
           set @num_cupon   =  @num_cupon  + 1

------------------ Borra al corregir ----------
if  @cve_vendedor1 is null
begin
    --SELECT ' ************ VENDEDOR 1 NULO *********** ' + CAST(@id_cxc AS varchar(10)) + CAST(@id_item AS varchar(10))
    set @tx_error_part   = 'El vendedor esta en nulo'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'El vendedor esta en nulo'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
end
-----------------------------------------------
        
           INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA, FOL_PROCESO )
                  VALUES(
                        CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
                        @k_cero_uno,
                        @serie,
                        @id_cxc,
                        @id_item,
                        @num_cupon,
                        @cve_vendedor1,
                        @cve_proceso1,
                        @pje_comis_ven1,
                        @imp_com_x_pagar1 * @meses_prim_pago,
                        'Pago cupon ' + CONVERT(varchar(2), @num_cupon) + '  ;  ' + CONVERT(varchar(2),@meses_prim_pago) + ' ' + 'periodos**',
                        @fol_pcup)
 
                                             
           set @num_meses_rest  =  12 - @meses_prim_pago

           --SELECT ' ** ITERACIONES ****' + '   '  +  CAST( @num_meses_rest as varchar(20))

           WHILE ( @num_meses_rest > 0 )
           BEGIN  -- 16

             set @num_cupon = @num_cupon + 1   

             set @mes = @mes + 1
             
             IF  @mes > 12
             BEGIN
               set @ano = @ano + 1
               set @mes = 01
             END


------------------ Borra al corregir ----------
if  @cve_vendedor1 is null
begin
    --SELECT ' ************ VENDEDOR 1 NULO *********** ' + CAST(@id_cxc AS varchar(10)) + CAST(@id_item AS varchar(10))
    set @tx_error_part   = 'El vendedor esta en nulo'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'El vendedor esta en nulo'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
end
-----------------------------------------------

             INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA, FOL_PROCESO)
                    VALUES(
                          CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
                         @k_cero_uno,
                         @serie,
                         @id_cxc,
                         @id_item,
                         @num_cupon,
                         @cve_vendedor1,
                         @cve_proceso1,
                         @pje_comis_ven1,
                         @imp_com_x_pagar1,
                         'Pago cupon ' + CONVERT(varchar(2), @num_cupon),
                         @fol_pcup)
            
              set @num_meses_rest  =  @num_meses_rest - 1 
            END -- 16

        END;  -- 15

        set @num_cupon =  1

/*  Genera cupones de comisión mantenimiento para Vendedor 2 */

        IF  @b_seg_vendedor  =  @k_verdadero  and  @b_paga_comis_vend2 = @k_verdadero
        BEGIN  -- 17
                                                                                         
          --SELECT ' *****ENTRE A CALCULAR COMISIONES MANT VEN 2******' + CONVERT(varchar(18),@imp_neto_com_c) + ' ' + CONVERT(varchar(18),@pje_item_fact) + ' ' +
          --CONVERT(varchar(18),@pje_comis_ven2)   
          IF  ISNULL(@imp_com_dir2, 0.00) = 0
          BEGIN
            set @imp_desc_comis2 = ISNULL(@imp_desc_comis2, 0.00)
            --SELECT ' * imp_neto_com_c ** ' + CONVERT(varchar(18),@imp_neto_com_c)
            --SELECT ' * imp_desc_comis2** ' + CONVERT(varchar(18),@imp_desc_comis2)
            --SELECT ' * pje_item_fact** ' + CONVERT(varchar(18),@pje_item_fact)
            --SELECT ' * pje_comis_ven2 ** ' + CONVERT(varchar(18),@pje_comis_ven2)
            --SELECT ' * Total ** ' + CONVERT(varchar(40),(((@imp_neto_com_c - @imp_desc_comis2)* @pje_item_fact) *  @pje_comis_ven2) / 100)
            --SELECT ' * Total 2 ** ' + CONVERT(varchar(40),
            --(convert(numeric(12,2),(((@imp_neto_com_c - @imp_desc_comis2)* @pje_item_fact) *  @pje_comis_ven2) / 100)))          
            set @imp_com_x_pagar2 = (convert(numeric(12,2),(((@imp_neto_com_c - @imp_desc_comis2)* @pje_item_fact) *  @pje_comis_ven2) / 100))
            --SELECT ' *****COMISION A PAGAR VEN 2****** ' + CONVERT(varchar(40),@imp_com_x_pagar2 )
          END 
          ELSE
          BEGIN
            set @imp_com_x_pagar2 = @imp_com_dir2
          END
--          set @imp_com_x_pagar2 = @imp_com_x_pagar2 / 12
          --SELECT ' *****COMISION A PAGAR VEN 2****** ' + CONVERT(varchar(40),@imp_com_x_pagar2 )

          IF  @imp_com_x_pagar2  >  0 
          BEGIN  -- 18
             --SELECT ' *****GENERANDO REGISTRO VEN 2****** '


------------------ Borra al corregir ----------
if  @cve_vendedor2 is null
begin
    --SELECT ' ************ VENDEDOR NULO 2-1*********** ' + CAST(@id_cxc AS varchar(10)) + CAST(@id_item AS varchar(10))
    set @tx_error_part   = 'El vendedor esta en nulo'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'El vendedor esta en nulo'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
end
-----------------------------------------------

             INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA, FOL_PROCESO )
                  VALUES(
                        CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
                        @k_cero_uno,
                        @serie,
                        @id_cxc,
                        @id_item,
                        @num_cupon,
                        @cve_vendedor2,
                        @cve_proceso2,
                        @pje_comis_ven2,
                        @imp_com_x_pagar2,
                        'Pago cupon 1', 
                        @fol_pcup)
                                             
 --            set @num_meses_rest  =  12 - @meses_prim_pago

 --            WHILE ( @num_meses_rest > 0 )
 --            BEGIN  -- 19

 --             set @num_cupon = @num_cupon + 1   

 --             set  @mes  =  @mes  +  1
              
 --             IF  @mes > 12
 --             BEGIN
 --               set @ano = @ano + 1
 --               set @mes = 01
 --             END


 --             INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA )
 --                 VALUES(
 --                       CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
 --                       @k_cero_uno,
 --                       @serie,
 --                       @id_cxc,
 --                       @id_item,
 --                       @num_cupon,
 --                       @cve_vendedor2,
 --                       @cve_proceso2,
 --                       @pje_comis_ven2,
 --                       @imp_com_x_pagar2,
 --                       'Pago cupon ' + CONVERT(varchar(2), @num_cupon))
            
 --              set @num_meses_rest  =  @num_meses_rest - 1 
 --            END  -- 19
          END  -- 18
        END  -- 17
      END -- 13
      --SELECT ' *** VOY A PREGUNTAR POR LA BANDERA comision**'
 
      IF @b_paga_comision    =  @k_verdadero  AND (@b_paga_comis_vend1  =  @k_verdadero OR  @b_paga_comis_vend2  =  @k_verdadero)   
      BEGIN -- 20
        SELECT @cve_producto  =  CVE_PRODUCTO FROM  CI_SUBPRODUCTO  where  CVE_SUBPRODUCTO =  @cve_subproducto    

        SELECT @b_paga_comision = B_PAGA_COMISION, @b_mantenimiento = B_MANTENIMIENTO  FROM CI_PRODUCTO       WHERE 
                                                                                          CVE_PRODUCTO      =  @cve_producto
 
 /*  Genera cupones de comisión para Vendedor 1 */
        --SELECT ' *** ENTRO A PAGA COMISION ** '
        set @num_cupon = 1   

        SET @imp_desc_comis1 = ISNULL(@imp_desc_comis1, 0.00)
        --SELECT ' *****ENTRE A CALCULAR COMISIONES NM++++++' + CONVERT(varchar(18),@imp_neto_com) + ' ' + CONVERT(varchar(18),@pje_item_fact) + ' ' +
        --CONVERT(varchar(18),@pje_comis_ven1)  + ' ' +  CONVERT(varchar(18),@imp_desc_comis1)  

        IF  ISNULL(@imp_com_dir1, 0.00) = 0
        BEGIN
 --SELECT ' *** CALCULO DE COMISION NM'
          set @imp_desc_comis1 = ISNULL(@imp_desc_comis1, 0.00)
          set @imp_com_x_pagar1 = (((@imp_neto_com_c - @imp_desc_comis1) * @pje_item_fact) *  @pje_comis_ven1) / 100
 --SELECT ' *****IMPORTE POR PAGAR ++++++' + CONVERT(varchar(18),@imp_com_x_pagar1)
        END
        ELSE
        BEGIN
 --SELECT ' *** EXISTE COMISION DIRECTA NM'
          set @imp_com_x_pagar1 = @imp_com_dir1
        END
  
        IF  @imp_com_x_pagar1  >  0  AND  @b_paga_comis_vend1 = @k_verdadero
        BEGIN  -- 21
 --SELECT ' *** insercion de registro' + ' ' + @cve_vendedor1
          IF  CONVERT(varchar(4),@pano_proc) +  replicate ('0',(02 - len(@pmes_proc))) + convert(varchar, @pmes_proc) >=
              CONVERT(varchar(4),YEAR(@f_real_pago)) +  replicate ('0',(02 - len(MONTH(@f_real_pago)))) + convert(varchar, MONTH(@f_real_pago)) 
          BEGIN                                                
            set @ano  = @pano_proc
            set @mes  = @pmes_proc
          END
          ELSE
          BEGIN
            set @ano  = YEAR(@f_real_pago)
            set @mes  = MONTH(@f_real_pago)
          END

------------------ Borra al corregir ----------
if  @cve_vendedor1 is null
begin
    --SELECT ' ************ VENDEDOR NULO 1 *********** ' + CAST(@id_cxc AS varchar(10)) + CAST(@id_item AS varchar(10))
    set @tx_error_part   = 'El vendedor esta en nulo'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'El vendedor esta en nulo'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
end
-----------------------------------------------

         
          INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA, FOL_PROCESO)
                 VALUES(
                       CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
                       @k_cero_uno,
                       @serie,
                       @id_cxc,
                       @id_item,
                       @num_cupon,
                       @cve_vendedor1,
                       @cve_proceso1,
                       @pje_comis_ven1,
                       @imp_com_x_pagar1,
                       'Pago cupon ' + CONVERT(varchar(2), @num_cupon),
                       @fol_pcup)
                      
   /*  Genera cupones de comisión para Vendedor 2 */
        END  -- 21 

        IF  @b_seg_vendedor  =  @k_verdadero and  @b_paga_comis_vend2 = @k_verdadero
        BEGIN
          set @num_cupon = 1   
          SET @imp_desc_comis2 = ISNULL(@imp_desc_comis2, 0.00)
          IF  ISNULL(@imp_com_dir2, 0.00) = 0
          BEGIN
            set @imp_desc_comis2 = ISNULL(@imp_desc_comis2, 0.00)

            set @imp_com_x_pagar2 = (((@imp_neto_com_c - @imp_desc_comis2) * @pje_item_fact) *  @pje_comis_ven2) / 100
          END
          ELSE
          BEGIN
            set @imp_com_x_pagar2 = @imp_com_dir2
          END
          
          IF  @imp_com_x_pagar2  >  0  AND  @b_paga_comis_vend2 = @k_verdadero 
 
          BEGIN

------------------ Borra al corregir ----------
if  @cve_vendedor2 is null
begin
    --SELECT ' ************ VENDEDOR NULO 2-2 *********** ' + CAST(@id_cxc AS varchar(10)) + CAST(@id_item AS varchar(10))
    set @tx_error_part   = 'El vendedor esta en nulo'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'El vendedor esta en nulo'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
end
-----------------------------------------------

             INSERT INTO CI_CUPON_COMISION (ANO_MES,CVE_EMPRESA,SERIE,ID_CXC,ID_ITEM,NUM_PAGO,CVE_VENDEDOR,CVE_PROCESO, PJE_COMISION, IMP_CUPON, TX_NOTA, FOL_PROCESO )
                 VALUES(
                       CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes),
                       @k_cero_uno,
                       @serie,
                       @id_cxc,
                       @id_item,
                       @num_cupon,
                       @cve_vendedor2,
                       @cve_proceso2,
                       @pje_comis_ven2,
                       @imp_com_x_pagar2,
                       'Pago cupon ' + CONVERT(varchar(2), @num_cupon),
                       @fol_pcup)
          END 
        END

      END -- 20

      FETCH item_cursor INTO  @cve_empresa, @cve_subproducto, @id_item, @imp_bruto_item, @imp_desc_comis1, @imp_desc_comis2, @f_inicio,
                            @f_fin, @cve_vendedor1, @cve_proceso1, @cve_especial1, @cve_vendedor2, @cve_proceso2,@cve_especial2, @imp_com_dir1, @imp_com_dir2  
    
    END -- 2

    close item_cursor 
    deallocate item_cursor 
    
    --SELECT ' Voy update Factura ** ' + LEFT(CONVERT(VARCHAR, @f_hoy, 120), 10) + ' ' + CONVERT(VARCHAR(6), @fol_pcup) + ' ' + CONVERT(varchar(10),@pid_concilia_cxc) 
    
    UPDATE CI_FACTURA SET FIRMA = CONVERT(VARCHAR(6), @fol_pcup), B_FACTURA_PAGADA = 1 WHERE ID_CONCILIA_CXC = @pid_concilia_cxc
    
  END  -- 1
  ELSE
  BEGIN  -- 22
    --select '4'
    set @tx_error_part   = 'La factura aún no está pagada o esta cancelada'
    set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) + ' '  + @tx_error_part
    set @tx_error_rise   = 'La factura aún no está pagada o esta cancelada'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
  END  -- 22

END   -- 0 

ELSE

BEGIN  -- 23 
  --select ''
  set @tx_error_part   = 'No existe factura solicitada'
  set @tx_error        = 'Error CI_FACTURA : ' + @cve_empresa + '  ' + @serie + '  ' + CAST(@id_cxc AS varchar(10)) + ' ' + @tx_error_part
  set @tx_error_rise   = 'No existe factura solicitada'
  execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
END   -- 23  

END 