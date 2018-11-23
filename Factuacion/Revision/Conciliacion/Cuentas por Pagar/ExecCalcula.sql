Declare
       @pid_concilia_cxc int,
       @pcve_r_moneda     varchar(1),     
       @pimp_neto_com     numeric(12,2),
       @pimp_r_neto       numeric(12,2),
       @ptipo_cambio_liq  numeric(8,2),
       @pf_real_pago      date         

set @pid_concilia_cxc = 1

EXEC spCalDatosCXC @pid_concilia_cxc,
                   @pcve_r_moneda     OUT,
                   @pimp_neto_com     OUT,
                   @pimp_r_neto       OUT,
                   @ptipo_cambio_liq  OUT,
                   @pf_real_pago      OUT   


select  'Moneda : ', + @pcve_r_moneda
select  'Imp Neto Com : ',  + CAST(@pimp_neto_com AS varchar(14))                                     
select  'Imp Neto : ',  + CAST(@pimp_r_neto AS varchar(14))                
select  'Tipo Cambio : ', + CAST(@ptipo_cambio_liq AS varchar(12))                          
select  'Fecha Pago : ',  + LEFT(CONVERT(VARCHAR, @pf_real_pago, 120), 10)                      

