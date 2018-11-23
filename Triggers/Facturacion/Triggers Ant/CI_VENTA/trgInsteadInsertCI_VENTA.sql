USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_VENTA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCI_VENTA] ON [dbo].[CI_VENTA]
INSTEAD OF Insert
AS

BEGIN

declare
    @id_venta          int,
    @id_cliente        numeric(10),
    @id_cliente_r      numeric(10)
  
declare

    @b_reg_correcto   bit,
    @tx_error         varchar(300),
    @tx_error_part    varchar(300),
    @fol_audit        int;

declare 

    @k_verdadero     bit,
    @k_falso         bit,
    @k_intefi        numeric(10),
    @k_gn            numeric(10),     
    @k_fol_audit     varchar(4)

select   
   
    @k_verdadero     = 1,
    @k_falso         = 0,
    @k_fol_audit     = 'AUDI',
    @k_intefi        = 1348,
    @k_gn            = 1008

-- Inicialización de datos 

select   @id_venta          =  i.ID_VENTA from inserted i;
select   @id_cliente        =  i.ID_CLIENTE from inserted i;
select   @id_cliente_r      =  i.ID_CLIENTE_R from inserted i;
    
set  @b_reg_correcto =  @k_verdadero
set  @tx_error_part  =  ' '

IF   NOT EXISTS (SELECT 1 FROM CI_CLIENTE  WHERE   ID_CLIENTE  =  @id_cliente)
BEGIN
  set @b_reg_correcto   =  @k_falso;
  set @tx_error_part    =  @tx_error_part + ': No existe el Cliente';
END

IF  @id_cliente  NOT IN  (@k_intefi,@k_gn)
BEGIN
  set @id_cliente_r  = @id_cliente 
END
ELSE
BEGIN
  IF  NOT EXISTS (SELECT 1 FROM CI_CLIENTE  WHERE   ID_CLIENTE  =  @id_cliente_r)
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': No existe el Cliente Real';
  END
END        

IF  @b_reg_correcto   =  @k_verdadero                                      
BEGIN

    Insert into CI_VENTA 
               (ID_VENTA,
                ID_CLIENTE,
                ID_CLIENTE_R)
           values     
               (@id_venta,
                @id_cliente,
                @id_cliente_r)
 
END
ELSE
BEGIN
  set @tx_error = 'Error CI_VENTA : ' + CAST(@id_venta AS varchar(10)) +
                  ' ' + CAST(@id_cliente AS varchar(10)) + @tx_error_part
  set @fol_audit  =  (select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_audit)
   
  UPDATE CI_FOLIO
         SET NUM_FOLIO = @fol_audit + 1
  WHERE  CVE_FOLIO     = @k_fol_audit

  insert into  CI_AUDIT_ERROR (
               ID_FOLIO,
               F_OPERACION,
               TX_ERROR)      
         values
              (@fol_audit,
               GETDATE(),
               @tx_error)
  COMMIT
  RAISERROR('El INSERT TIENE INCONSISTENCIA DE INFORMACION',11,1)
END    

END

