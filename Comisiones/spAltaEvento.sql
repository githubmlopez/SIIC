 USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[spAltaEvento]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spAltaEvento] @ptx_error varchar(200), @ptx_error_rise varchar(200)
AS

BEGIN
   SELECT 'ERROR ***' + @ptx_error_rise

   declare
       @fol_audit       int;

   declare 
       @k_fol_audit     varchar(4);
   

   set @k_fol_audit     = 'AUDI';       
        
   set @fol_audit  =  (select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_audit)
    
   --UPDATE CI_FOLIO
   --       SET NUM_FOLIO = @fol_audit + 1
   --WHERE  CVE_FOLIO     = @k_fol_audit

   --insert into  CI_AUDIT_ERROR (
   --             ID_FOLIO,
   --             F_OPERACION,
   --             TX_ERROR)      
   --       values
   --            (@fol_audit,
   --             GETDATE(),
   --             @ptx_error)

--   RAISERROR(@ptx_error_rise,11,1)
        
END