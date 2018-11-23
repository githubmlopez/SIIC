	 USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[spCalDatosCXCtaEvento]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter  PROCEDURE [dbo].[spCalDatosCXC] @pid_concilia_cxc  int,
                                       @pcve_r_moneda     varchar(1)     OUT,
                                       @pimp_neto_com     numeric(12,2)  OUT,
                                       @pimp_r_neto       numeric(12,2)  OUT,
                                       @ptipo_cambio_liq  numeric(8,4)   OUT,
                                       @pf_real_pago      date           OUT                                           
AS

BEGIN

  declare  @cve_empresa         varchar(4),
           @imp_transaccion     numeric(12,2),
           @cve_chequera        varchar(6),
           @cve_moneda          varchar(1),
           @cve_cargo_abono     varchar(1),
           @f_operacion         date,
           @cve_tipo_movto      varchar(6),
           @pje_iva             numeric(8,4)
           
  declare  @num_registros       int    
 
  declare  @k_verdadero         varchar(1),
           @k_falso             varchar(1),
           @k_cargo             varchar(1),
           @k_peso              varchar(1),
           @k_dolares           varchar(1),
           @k_cuenta_x_cobrar   varchar(6),
           @k_ll_parametro      varchar(4)
  
  set @k_cargo           =  'C'
  set @k_verdadero       =  0
  set @k_peso            =  'P'
  set @k_dolares         =  'D'
  set @k_cuenta_x_cobrar = 'CXC'
  set @k_ll_parametro    = 'IVA'
  
  DECLARE @tx_error  varchar(50),
          @tx_error_rise varchar(50)

--  select 'Entre a Calcula Datos **'
        
--  set @tx_error        = 'Entrea rutina ***'
--  set @tx_error_rise   = 'Entre a rutina ***'
--  execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  

--  select ' voy por porcentaje de IVA' + '  ' + @k_ll_parametro

  SELECT @pje_iva = VALOR_NUMERICO FROM CI_PARAMETRO WHERE CVE_PARAMETRO = @k_ll_parametro
  
--  select ' pJE ' + ' ' + CAST(@pje_iva AS varchar(12))
  
  SELECT @num_registros = count(*)  FROM  CI_MOVTO_BANCARIO mo, CI_CONCILIA_C_X_C co, CI_TIPO_MOVIMIENTO tm  where
                                          co.ID_CONCILIA_CXC   = @pid_concilia_cxc    AND
                                          co.ID_MOVTO_BANCARIO = mo.ID_MOVTO_BANCARIO AND  
                                          mo.CVE_TIPO_MOVTO    = tm.CVE_TIPO_MOVTO  --  AND
--                                        tm.CVE_CARGO_ABONO  <> 'C'
-- SELECT CAST(@pid_concilia_cxc AS varchar(10))
-- SELECT CAST(@num_registros AS varchar(10))

  IF @num_registros = 0
  BEGIN
    set  @pimp_neto_com      = 0
    set  @pimp_r_neto        = 0
    set  @ptipo_cambio_liq   = 0
  END
  ELSE                                                                                   
  BEGIN
    SELECT @pf_real_pago = MAX(mo.F_OPERACION) FROM  CI_MOVTO_BANCARIO mo, CI_CONCILIA_C_X_C co, CI_TIPO_MOVIMIENTO tm  where
                                               co.ID_CONCILIA_CXC   = @pid_concilia_cxc    AND
                                               co.ID_MOVTO_BANCARIO = mo.ID_MOVTO_BANCARIO AND  
                                               mo.CVE_TIPO_MOVTO    = tm.CVE_TIPO_MOVTO    -- AND
 --                                              tm.CVE_CARGO_ABONO  <> @k_cargo

   SELECT @ptipo_cambio_liq = tipo_cambio FROM  CI_TIPO_CAMBIO  WHERE F_OPERACION = @pf_real_pago 

    declare movbanc cursor for
    SELECT mo.F_OPERACION, mo.IMP_TRANSACCION, mo.CVE_CHEQUERA, ch.CVE_MONEDA, tm.CVE_CARGO_ABONO, tm.CVE_TIPO_MOVTO   FROM 
           CI_FACTURA ft, CI_CONCILIA_C_X_C co, CI_MOVTO_BANCARIO mo, CI_CHEQUERA ch, CI_TIPO_MOVIMIENTO tm  WHERE  
           ft.ID_CONCILIA_CXC   = @pid_concilia_cxc    AND
           ft.ID_CONCILIA_CXC   = co.ID_CONCILIA_CXC   AND
           co.ID_MOVTO_BANCARIO = mo.ID_MOVTO_BANCARIO AND             
           mo.CVE_CHEQUERA      = ch.CVE_CHEQUERA      AND
           mo.CVE_TIPO_MOVTO    = tm. CVE_TIPO_MOVTO   ORDER BY mo.ID_MOVTO_BANCARIO
      
    open  movbanc

    FETCH movbanc INTO  @f_operacion, @imp_transaccion, @cve_chequera, @cve_moneda, @cve_cargo_abono, @cve_tipo_movto

    set  @pimp_r_neto        =  0
    set  @pimp_neto_com      =  0


    WHILE (@@fetch_status = 0 )
    BEGIN         

-- select  'Moneda : ', + @cve_moneda
-- select  'Chequera : ', + @cve_chequera
-- select  'Cargo Abono : ', + @cve_cargo_abono
-- select  'imp transaccion : ', + CAST(@imp_transaccion AS varchar(12))                          
-- select  'Fecha Operacion : ',  + LEFT(CONVERT(VARCHAR, @f_operacion, 120), 10)
   
      set @pcve_r_moneda    = @cve_moneda

      IF  @cve_tipo_movto   = @k_cuenta_x_cobrar
      BEGIN
        set @imp_transaccion = @imp_transaccion / (1 + (@pje_iva / 100)) 
      END


      IF  @cve_cargo_abono  =  @k_cargo 
      BEGIN
 -- select 'Es un cargo **' + '  ' +  CAST(@imp_transaccion AS varchar(12))                          

        set @pimp_neto_com      =  @pimp_neto_com  -  @imp_transaccion
      END
      ELSE
      BEGIN
 -- select 'Es un abono **' + CAST(@imp_transaccion AS varchar(12))     
        set  @pimp_r_neto        =  @pimp_r_neto  +    @imp_transaccion
        set  @pimp_neto_com      =  @pimp_neto_com  +  @imp_transaccion
      END
    
      FETCH movbanc INTO  @f_operacion, @imp_transaccion, @cve_chequera, @cve_moneda, @cve_cargo_abono, @cve_tipo_movto

    END

    close movbanc 
    deallocate movbanc 
   
  END        
END