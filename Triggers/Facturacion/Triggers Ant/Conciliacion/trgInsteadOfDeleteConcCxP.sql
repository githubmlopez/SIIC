USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfDeleteConcCXP]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CONCILIA_C_X_P for Insert statement
alter TRIGGER trgInsteadOfDeleteConcCXP ON [dbo].[CI_CONCILIA_C_X_P]
INSTEAD OF Delete
AS
declare
   @id_movto_bancario int,
   @id_concilia_cxp   int,
   @sit_concilia_cxp  varchar(2),
   @tx_nota           varchar(200)

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
select  @id_concilia_cxp    =  i.ID_CONCILIA_CXP from deleted i;
select  @sit_concilia_cxp   =  i.SIT_CONCILIA_CXP  from deleted i;
select  @tx_nota            =  i.TX_NOTA  from deleted i;

-- SELECT 'id_movto_bancario ' + CAST(@id_movto_bancario AS varchar(10))
-- SELECT 'id_concilia_cxp   ' + CAST(@id_concilia_cxp AS varchar(10))

BEGIN 
  SET NOCOUNT ON;

  set  @b_reg_correcto    =  @k_verdadero

  IF  NOT EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_P  WHERE  ID_MOVTO_BANCARIO =  @id_movto_bancario AND
                                                          ID_CONCILIA_CXP   =  @id_concilia_cxp) 
  BEGIN
    set @b_reg_correcto = @k_falso
    set @tx_error_part   = 'No existe el registro a dar de baja'
    set @tx_error        = 'Error CI_CUENTA_X_PAGAR : ' + CAST(@id_concilia_cxp AS varchar(10)) + '  ' + @tx_error_part
    set @tx_error_rise   = 'No existe la factura a Conciliar'
    execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
  END 

  IF  @b_reg_correcto  =  @k_verdadero
  BEGIN

    BEGIN TRY


    DELETE FROM CI_CONCILIA_C_X_P WHERE ID_CONCILIA_CXP   =  @id_concilia_cxp
                                     
  
    END TRY 

    BEGIN CATCH	
        set @tx_error_part   = ' No fue posible realizar la insercion'
        set @tx_error        = 'Error CI_CONCILIA_C_X_P: ' + ' ' + CAST(@id_movto_bancario AS varchar(10)) + ' ' +
        CAST(@id_concilia_cxp AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = ' No fue posible realizar la insercion'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;
     
    BEGIN TRY

     UPDATE CI_CUENTA_X_PAGAR SET SIT_CONCILIA_CXP =  @k_no_conciliado,
                                  F_PAGO           =  NULL  WHERE
                                  ID_CONCILIA_CXP  =  @id_concilia_cxp            
                   
    END TRY
    
    BEGIN CATCH
        set @tx_error_part   = 'No fue posible actualizar'
        set @tx_error        = 'Error CI_CUENTA_X_PAGAR : ' + CAST(@id_concilia_cxp AS varchar(10)) + @tx_error_part
        set @tx_error_rise   = 'No fue posible actualizar'
        execute spAltaEvento @ptx_error = @tx_error, @ptx_error_rise = @tx_error_rise  
    END CATCH;

    BEGIN TRY

     UPDATE CI_MOVTO_BANCARIO SET SIT_CONCILIA_BANCO =  @k_no_conciliado  WHERE
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

