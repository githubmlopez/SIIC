USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfDeleteConcCxC]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CONCILIA_C_X_C for Insert statement
ALTER TRIGGER trgInsteadOfDeleteConcCxC ON [dbo].[CI_CONCILIA_C_X_C]
INSTEAD OF Delete
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
    @tx_error         varchar(300),
    @tx_error_part    varchar(300),
    @tx_error_rise    varchar(300)

declare 

    @k_verdadero     bit,
    @k_falso         bit,
    @k_no_conciliado varchar(2)
   
select   
    
    @k_verdadero     = 1,
    @k_falso         = 0,
    @k_no_conciliado = 'NC'
    
set  @b_reg_correcto =  @k_verdadero;
set  @tx_error_part  =  ' ';

select  @id_movto_bancario  =  i.ID_MOVTO_BANCARIO from deleted i;
select  @id_concilia_cxc    =  i.ID_CONCILIA_CXC from deleted i;
select  @sit_concilia_cxc   =  i.SIT_CONCILIA_CXC  from deleted i;
select  @tx_nota            =  i.TX_NOTA  from deleted i;

--SELECT 'id_movto_bancario ' + CAST(@id_movto_bancario AS varchar(10))
--SELECT 'id_concilia_cxc   ' + CAST(@id_concilia_cxc AS varchar(10))

BEGIN 
  SET NOCOUNT ON;

  set  @b_reg_correcto    =  @k_verdadero

  IF  NOT EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_C  WHERE  ID_MOVTO_BANCARIO =  @id_movto_bancario AND
                                                          ID_CONCILIA_CXC   =  @id_concilia_cxc) 
  BEGIN
    set @b_reg_correcto = @k_falso
    set @tx_error_part   = 'No existe el registro a dar de baja'
    set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + '  ' + @tx_error_part
    set @tx_error_rise   = 'No existe la factura a Conciliar'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
  END 

  IF  @b_reg_correcto  =  @k_verdadero
  BEGIN

    BEGIN TRY
--    SELECT ' ** VOY A DAR DE BAJA  ** ' + '   '  + CAST(@id_movto_bancario AS varchar(10)) 


    DELETE FROM CI_CONCILIA_C_X_C WHERE ID_MOVTO_BANCARIO  =  @id_movto_bancario
                                     
  
    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = ' No fue posible realizar la BAJA'
        set @tx_error        = 'Error CI_CONCILIA_C_X_C: ' + ' ' + CAST(@id_movto_bancario AS varchar(10)) + ' ' +
        CAST(@id_concilia_cxc AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = ' No fue posible realizar la insercion'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;
-------
    BEGIN TRY
    SELECT ' ** ACTUALIZANDO limpiando FACTURA ** ' + '   '  + CAST(@id_concilia_cxc AS varchar(10)) 

     UPDATE CI_FACTURA SET CVE_R_MONEDA     =  NULL,
                           F_REAL_PAGO      =  NULL, 
                           IMP_R_NETO_COM   =  0,
                           IMP_R_NETO       =  0,   
                           TIPO_CAMBIO_LIQ  =  0,
                           SIT_CONCILIA_CXC =  @k_no_conciliado WHERE
                           ID_CONCILIA_CXC  =  @id_concilia_cxc            
                   
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar FACT LIMPIA'
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;


-------

    BEGIN TRY
--    SELECT ' ** LLAMANDO CALCULA DATOS ** '
    EXEC spCalDatosCXC  @id_concilia_cxc,
                        @cve_r_moneda    OUT,
                        @imp_neto_com    OUT,
                        @imp_r_neto      OUT,
                        @tipo_cambio_liq OUT,
                        @f_real_pago     OUT  


    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = 'No pudo llamar proceso spCalDatosCXC'
        set @tx_error        = 'Error Proceso  ' 
        set @tx_error_rise   = 'No pudo llamar proceso spCalDatosCXC'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;
    
    BEGIN TRY
--    SELECT ' ** ACTUALIZANDO FACTURA ** ' + '   '  + CAST(@id_concilia_cxc AS varchar(10)) 

     UPDATE CI_FACTURA SET CVE_R_MONEDA     =  @cve_r_moneda,
                           F_REAL_PAGO      =  @f_real_pago, 
                           IMP_R_NETO_COM   =  @imp_neto_com,
                           IMP_R_NETO       =  @imp_r_neto,   
                           TIPO_CAMBIO_LIQ  =  @tipo_cambio_liq,
                           SIT_CONCILIA_CXC =  @k_no_conciliado WHERE
                           ID_CONCILIA_CXC  =  @id_concilia_cxc            
                   
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar calculado'
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_concilia_cxc AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

------------------------------
    BEGIN TRY
      UPDATE CI_MOVTO_BANCARIO SET SIT_CONCILIA_BANCO =  @k_no_conciliado  WHERE                            
                                   ID_MOVTO_BANCARIO  =  @id_movto_bancario            
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar Movto Bancario'
        set @tx_error        = 'Error CI_FACTURA : ' + CAST(@id_movto_bancario AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;


-----------------------------


  END
 
END 

