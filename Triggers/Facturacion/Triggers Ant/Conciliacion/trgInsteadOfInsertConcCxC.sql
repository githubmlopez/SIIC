USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertConcCxC]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CONCILIA_C_X_C for Insert statement
ALTER TRIGGER trgInsteadOfInsertConcCxC ON [dbo].[CI_CONCILIA_C_X_C]
INSTEAD OF Insert
AS
declare
    @id_movto_bancario int,
    @id_concilia_cxc   int,
    @sit_concilia_cxc  varchar(2),
    @tx_nota           varchar(200)

declare

    @cve_r_moneda      varchar(1),
    @imp_neto_com      numeric(12,2),
    @imp_r_neto        numeric(12,2),
    @tipo_cambio_liq   numeric(8,4),
    @f_real_pago       date  

declare

    @b_reg_correcto   bit,
    @f_operacion      date,
    @cve_chequera     varchar(6),
    @cve_mon_movto    varchar(1),
    @ano_mes          varchar(4),
    @sit_transaccion  varchar(2),
    @b_factura_pagada bit,
    @firma            varchar(10),
    @imp_movto        numeric(12,2),
    @tx_error         varchar(300),
    @tx_error_part    varchar(300),
    @tx_error_rise    varchar(300),
    @fol_audit        int,
    @ano_mes_con      varchar(6)

declare 

    @k_verdadero     bit,
    @k_falso         bit,
    @k_activa        varchar(1), 
    @k_cancelada     varchar(1),
    @k_autorizada    varchar(10),
    @k_peso          varchar(1),
    @k_dolar         varchar(1),
    @k_fol_audit     varchar(4),
    @k_fol_concilia  varchar(4);   

select   
    
    @k_verdadero     = 1,
    @k_falso         = 0,
    @k_cancelada     = 'C',
    @k_activa        = 'A',
    @k_autorizada    = 'AUTORIZADO',
    @k_peso          = 'P',
    @k_dolar         = 'D',
    @k_fol_audit     = 'AUDI',
    @k_fol_concilia  = 'MPRO'
    
set  @b_reg_correcto =  @k_verdadero;
set  @tx_error_part  =  ' ';

select  @id_movto_bancario  =  i.ID_MOVTO_BANCARIO from inserted i;
select  @id_concilia_cxc    =  i.ID_CONCILIA_CXC from inserted i;
select  @sit_concilia_cxc   =  i.SIT_CONCILIA_CXC  from inserted i;
select  @tx_nota            =  i.TX_NOTA  from inserted i;

BEGIN 
  SET NOCOUNT ON;

  set  @firma             =  ' '
  set  @sit_transaccion   =  @k_activa
  set  @b_factura_pagada  =  @k_falso
  set  @b_reg_correcto    =  @k_verdadero

--  select 'Voy a desplegar' + CAST(@id_movto_bancario AS varchar(10))

--  select 'Movto bancario' + CAST(@id_concilia_cxc AS varchar(10))

  IF  NOT EXISTS (SELECT 1 FROM CI_FACTURA  WHERE  ID_CONCILIA_CXC =  @id_concilia_cxc) 
  BEGIN
    set @b_reg_correcto = @k_falso
    set @tx_error_part   = 'No existe la factura a Conciliar'
    set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + '  ' + @tx_error_part
    set @tx_error_rise   = 'No existe la factura a Conciliar'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
  END 
  ELSE
  BEGIN
    SELECT @sit_transaccion = SIT_TRANSACCION, @firma = FIRMA, @b_factura_pagada = B_FACTURA_PAGADA FROM CI_FACTURA                   
      WHERE  ID_CONCILIA_CXC =  @id_concilia_cxc
                                                                                                                           
    IF  @sit_transaccion = @k_cancelada or @firma <> @k_autorizada or @b_factura_pagada = @k_verdadero
    BEGIN
      set @b_reg_correcto = @k_falso
      set @tx_error_part   = 'Factura cancelada,  pagada o no autorizada'
      set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + '  ' + @tx_error_part
      set @tx_error_rise   = 'Factura cancelada,  pagada o no autorizada'
      execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END
    ELSE
    BEGIN
      IF  NOT EXISTS (SELECT 1 FROM CI_MOVTO_BANCARIO  WHERE  ID_MOVTO_BANCARIO  =  @id_movto_bancario)
      BEGIN
        set @b_reg_correcto = @k_falso
        set @tx_error_part   = 'No existe el pago a Conciliar'
        set @tx_error        = 'Error CI_MOVTO_BANCO : ' + CAST(@id_movto_bancario AS varchar(10)) + '  ' + @tx_error_part
        set @tx_error_rise   = 'No existe el pago a Conciliar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise
      END
      ELSE
      BEGIN

        SELECT @f_operacion = F_OPERACION, @cve_chequera = CVE_CHEQUERA FROM CI_MOVTO_BANCARIO  WHERE  
                                                                                                ID_MOVTO_BANCARIO  =  @id_movto_bancario
        SELECT  @cve_mon_movto  = CVE_MONEDA  FROM   CI_CHEQUERA  WHERE  CVE_CHEQUERA  =  @cve_chequera
 
        IF  @cve_mon_movto  =  @k_peso
        BEGIN
        
  --        SELECT 'LA MONEDA ES PESOS'
          IF  EXISTS (SELECT 1 FROM  CI_CHEQUERA ch, CI_MOVTO_BANCARIO mo  WHERE 
                                                                           mo.ID_MOVTO_BANCARIO  =  @id_movto_bancario AND
                                                                           mo.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
                                                                           ch.CVE_MONEDA  = @k_dolar)
          BEGIN                                                                        
            set @b_reg_correcto = @k_falso
            set @tx_error_part   = 'Existen pagos en moneda diferente'
            set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_movto_bancario AS varchar(10)) + @tx_error_part
            set @tx_error_rise   = 'Existen pagos en moneda diferente'
            execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
          END  
        END
        ELSE
        BEGIN
          IF  EXISTS (SELECT 1 FROM  CI_CHEQUERA ch, CI_MOVTO_BANCARIO mo  WHERE 
                                                                           mo.ID_MOVTO_BANCARIO  =  @id_movto_bancario AND
                                                                           mo.CVE_CHEQUERA       =  ch.CVE_CHEQUERA    AND
                                                                           ch.CVE_MONEDA  = @k_peso)
          BEGIN                                                                        
            set @b_reg_correcto = @k_falso
            set @tx_error_part   = 'Existen pagos en moneda diferente'
            set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_movto_bancario AS varchar(10)) + @tx_error_part
            set @tx_error_rise   = 'Existen pagos en moneda diferente'
            execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise 
          END  
          ELSE
          BEGIN
            IF @cve_mon_movto = @k_dolar and (NOT EXISTS (SELECT 1 FROM CI_TIPO_CAMBIO where F_OPERACION = @f_operacion))
            BEGIN
              set @b_reg_correcto = @k_falso
              set @tx_error_part   = 'Pago en dólares sin tipo de cambio'
              set @tx_error        = 'Error CI_TIPO_CAMBIO : ' + CAST(@f_operacion AS varchar(10)) + @tx_error_part
              set @tx_error_rise   = 'Pago en dólares sin tipo de cambio'
              execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise      
            END
          END
        END
      END
    END
  END

  SET  @ano_mes_con  =  convert(varchar(6),(select NUM_FOLIO from CI_FOLIO WHERE CVE_FOLIO = @k_fol_concilia))  
  
  IF  @ano_mes_con   IS  NULL
  BEGIN
    set @b_reg_correcto  = @k_falso
    set @tx_error_part   = 'No existe folio de cierre conciliacion'
    set @tx_error        = @tx_error_part
    set @tx_error_rise   = 'No existe folio de cierre conciliacion'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise      
  END
    
  IF  @b_reg_correcto  =  @k_verdadero
  BEGIN

    BEGIN TRY

-- SELECT 'REGISTRO CORRECTO VOY A INSERTAR'

--    SELECT   CAST(@id_movto_bancario AS varchar(10)) + '  ' + CAST(@id_concilia_cxc AS varchar(10)) +
--             '  ' + @sit_concilia_cxc +  '  ' + @tx_nota   

    INSERT INTO CI_CONCILIA_C_X_C (ID_MOVTO_BANCARIO,ID_CONCILIA_CXC,SIT_CONCILIA_CXC,ANOMES_PROCESO,TX_NOTA) 
           VALUES(
                  @id_movto_bancario,
                  @id_concilia_cxc,         
                  @sit_concilia_cxc,
                  @ano_mes_con,        
                  @tx_nota)  
  
       
    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = 'No fue posible realizar la insercion' + @@ERROR
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible realizar la insercion'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

    BEGIN TRY

      EXEC spCalDatosCXC  @id_concilia_cxc,
                          @cve_r_moneda    OUT,
                          @imp_neto_com    OUT,
                          @imp_r_neto      OUT,
                          @tipo_cambio_liq OUT,
                          @f_real_pago     OUT  



 -- select ' **** Regreso de Calcular ** '
 -- SELECT   CAST(@id_concilia_cxc AS varchar(10)) + '  ' + @cve_r_moneda + '  '  +  CAST(@imp_neto_com AS varchar(20)) + '  ' +
 -- CAST(@imp_r_neto AS varchar(20)) + '  ' + CAST(@tipo_cambio_liq AS varchar(20)) + '  '  +  LEFT(CONVERT(VARCHAR, @f_real_pago, 120), 10) + '  '  +
 -- CAST(@sit_concilia_cxc AS varchar(20))
 

 
  
    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = 'No pudo llamar proceso spCalDatosCXC'
        set @tx_error        = 'Error Proceso  ' 
        set @tx_error_rise   = 'No pudo llamar proceso spCalDatosCXC'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;
    
    BEGIN TRY

-- select ' ** voy a dar update *** '
-- SELECT   CAST(@id_concilia_cxc AS varchar(10)) 
-- SELECT   CAST(@id_concilia_cxc AS varchar(10)) + '  ' + @cve_r_moneda + '  '  +  CAST(@imp_neto_com AS varchar(20)) + '  ' +
-- CAST(@imp_r_neto AS varchar(20)) + '  ' + CAST(@tipo_cambio_liq AS varchar(20)) + '  '  +  LEFT(CONVERT(VARCHAR, @f_real_pago, 120), 10) + '  '  +
-- CAST(@sit_concilia_cxc AS varchar(20))

     UPDATE CI_FACTURA SET CVE_R_MONEDA     =  @cve_r_moneda,
                           F_REAL_PAGO      =  @f_real_pago, 
                           IMP_R_NETO_COM   =  @imp_neto_com,
                           IMP_R_NETO       =  @imp_r_neto,   
                           TIPO_CAMBIO_LIQ  =  @tipo_cambio_liq,
                           SIT_CONCILIA_CXC =  @sit_concilia_cxc WHERE
                           ID_CONCILIA_CXC  =  @id_concilia_cxc            

-- select @@ERROR

-- select ' ** sali de UPDATE **'
                       
    END TRY
    
    BEGIN CATCH
        select @@ERROR
        set @tx_error_part   = 'No fue posible actualizar Factura'
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;
-------------------------

    BEGIN TRY
      UPDATE CI_MOVTO_BANCARIO SET SIT_CONCILIA_BANCO =  @sit_concilia_cxc  WHERE                            
                                   ID_MOVTO_BANCARIO  =  @id_movto_bancario            
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar Movto Bancario'
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_movto_bancario AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

-----------------
  END
 
END 
 
 
 
 
 
 
 
 
 
 
 
 
