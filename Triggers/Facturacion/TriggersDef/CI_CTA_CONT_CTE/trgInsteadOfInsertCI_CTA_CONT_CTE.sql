USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCI_CTA_CONT_CTE]    Script Date: 02/05/2019 03:51:35 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CUENTA_X_PAGAR for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCI_CTA_CONT_CTE] ON [dbo].[CI_CTA_CONT_CTE]
INSTEAD OF INSERT
AS

BEGIN

  DECLARE
  @cve_empresa        varchar(4),
  @id_cliente         numeric(10,0),
  @cve_tipo_cta       varchar(1),
  @cta_contable       varchar(30)


  DECLARE
   @b_reg_correcto   bit,
   @tx_error         varchar(300),
   @tx_error_part    varchar(300)

  DECLARE 
   @k_verdadero     bit = 1,
   @k_falso         bit = 0

  SET  @b_reg_correcto =  @k_verdadero
  SET  @tx_error_part  =  ' '

-- Inicialización de datos 

  SELECT  @cve_empresa          = CVE_EMPRESA FROM inserted i
  SELECT  @id_cliente           = ID_CLIENTE FROM  inserted i
  SELECT  @cve_tipo_cta         = CVE_TIPO_CTA FROM  inserted i
  SELECT  @cta_contable         = CTA_CONTABLE FROM  inserted i

  IF  (SELECT COUNT(*)  FROM inserted) = 1
  BEGIN
    set @b_reg_correcto   =  @k_verdadero;
    set @tx_error_part    =  ' ';

    IF   @cve_tipo_cta <> (SELECT CVE_TIPO_CTA FROM CI_CAT_CTA_CONT 
	                       WHERE CVE_EMPRESA = @cve_empresa  AND  @cta_contable = CTA_CONTABLE)  
    BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': cta. Contable o Tipo Cta no corresponde ' + @cta_contable,1,300)
    END                                          
         
    IF  @b_reg_correcto   =  @k_verdadero                                      
    BEGIN
      BEGIN TRY

        INSERT   CI_CTA_CONT_CTE
       (CVE_EMPRESA,
        ID_CLIENTE,
        CVE_TIPO_CTA,  
        CTA_CONTABLE)  
        VALUES
       (@cve_empresa, 
        @id_cliente,       
        @cve_tipo_cta,  
        @cta_contable)     
      END TRY

	  BEGIN CATCH
        SET @tx_error_part    =  SUBSTRING(ISNULL(ERROR_MESSAGE(), ' '),1,300)
        RAISERROR(@tx_error_part,11,1)
	  END CATCH

    END
    ELSE
	BEGIN
      RAISERROR(@tx_error_part,11,1)
	END
  END
  ELSE
  BEGIN
      SET @tx_error_part    =  'No se permiten INSERTs multiples'
	  RAISERROR(@tx_error_part,11,1)  
  END
END

