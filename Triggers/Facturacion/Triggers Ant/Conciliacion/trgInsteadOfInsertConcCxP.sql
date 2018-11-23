USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertConcCxP]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CONCILIA_C_X_P for Insert statement
ALTER TRIGGER trgInsteadOfInsertConcCxP ON [dbo].[CI_CONCILIA_C_X_P]
INSTEAD OF Insert
AS

declare
   @id_movto_bancario int,
   @id_concilia_cxp   int,
   @sit_concilia_cxp  varchar(2),
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
    @fol_audit        int;

declare 

    @k_verdadero     bit,
    @k_falso         bit,
    @k_cancelada     varchar(1);

select   
    
    @k_verdadero     = 1,
    @k_falso         = 0;
    
set  @b_reg_correcto =  @k_verdadero;
set  @tx_error_part  =  ' ';

select  @id_movto_bancario  =  i.ID_MOVTO_BANCARIO from inserted i;
select  @id_concilia_cxp    =  i.ID_CONCILIA_CXP from inserted i;
select  @sit_concilia_cxp   =  i.SIT_CONCILIA_CXP  from inserted i;
select  @tx_nota            =  i.TX_NOTA  from inserted i;

BEGIN 
  SET NOCOUNT ON;

 set  @b_reg_correcto    =  @k_verdadero

--  select 'Voy a desplegar MB' + CAST(@id_movto_bancario AS varchar(10))

--  select 'Movto CXP' + CAST(@id_concilia_cxp AS varchar(10))

  IF  NOT EXISTS (SELECT 1 FROM CI_CUENTA_X_PAGAR  WHERE  ID_CONCILIA_CXP =  @id_concilia_cxp) 
  BEGIN
    set @b_reg_correcto = @k_falso
    set @tx_error_part   = 'No existe la CXP a Conciliar'
    set @tx_error        = 'Error CI_CUENTA_X_PAGAR : ' + CAST(@id_concilia_cxp AS varchar(10)) + '  ' + @tx_error_part
    set @tx_error_rise   = 'No existe la CXP a Conciliar'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
  END 

  IF  @b_reg_correcto  =  @k_verdadero
  BEGIN
--    select ' *** Registro correcto ** '

    BEGIN TRY

--    select ' *** voy a insertar ** '
    INSERT INTO CI_CONCILIA_C_X_P (ID_MOVTO_BANCARIO,ID_CONCILIA_CXP,SIT_CONCILIA_CXP,TX_NOTA) 
           VALUES(
                  @id_movto_bancario,
                  @id_concilia_cxp,         
                  @sit_concilia_cxp,        
                  @tx_nota)           

    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = 'No fue posible realizar la insercion'
        set @tx_error        = 'Error CI_CUENTA_X_PAGAR : ' + CAST(@id_concilia_cxp AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible realizar la insercion'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

 
    BEGIN TRY
-- select ' *** voy a actual cXP ** '
      select  @f_real_pago = F_OPERACION  FROM CI_MOVTO_BANCARIO WHERE ID_MOVTO_BANCARIO = @id_movto_bancario 

     UPDATE CI_CUENTA_X_PAGAR SET SIT_CONCILIA_CXP =  @sit_concilia_cxp,
                                  F_PAGO           =  @f_real_pago  WHERE
                                  ID_CONCILIA_CXP  =  @id_concilia_cxp            
                       
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar cxp'
        set @tx_error        = 'Error CI_CUENTA_X_PAGAR : ' + CAST(@id_concilia_cxp AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

    BEGIN TRY
-- select ' *** voy a actual MB ** '
     UPDATE CI_MOVTO_BANCARIO SET SIT_CONCILIA_BANCO =  @sit_concilia_cxp WHERE
                                  ID_MOVTO_BANCARIO  =  @id_movto_bancario            
                       
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar movto bancario'
        set @tx_error        = 'Error CI_MOVTO_BANCARIO : ' + CAST(@id_movto_bancario AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

  END
 
END 
 
 
 
 
 
 
 
 
 
 
 
 
