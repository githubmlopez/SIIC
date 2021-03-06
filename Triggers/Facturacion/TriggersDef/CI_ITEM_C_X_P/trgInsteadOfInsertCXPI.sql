USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]    Script Date: 21/06/2018 01:42:57 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCXPI] ON [dbo].[CI_ITEM_C_X_P]
INSTEAD OF Insert
AS

BEGIN

  DECLARE
  @cve_empresa       varchar(4),
  @id_cxp            int,
  @id_cxp_det        int,
  @cve_operacion     varchar(4),
  @imp_bruto         numeric(12,2),
  @tx_nota           varchar(200),
  @iva               numeric(12,2),
  @rfc               varchar(15),
  @b_factura         bit

  DECLARE
   @b_reg_correcto   bit,
   @tx_error         varchar(300),
   @tx_error_part    varchar(300),
   @fol_act          int,
   @fol_audit        int,
   @gpo_contable     int,
   @b_deudor         bit

  DECLARE 
   @k_verdadero     bit = 1,
   @k_falso         bit = 0,
   @k_fol_audit     varchar(4)  =  'AUDI',
   @k_fol_act       varchar(4)  =  'NACT',
   @k_cta_legacy    varchar(12) =  '900-13-02-00'

  SET @tx_error_part    =  ' ';

  SET  @b_reg_correcto =  @k_falso

  IF  (SELECT COUNT(*) FROM INSERTED) = 1
  BEGIN

-- Corrección de datos

-- Inicialización de datos 

  SELECT  @cve_empresa      = CVE_EMPRESA FROM INSERTED i;
  SELECT  @id_cxp           = ID_CXP FROM INSERTED i;
  SELECT  @id_cxp_det       = ID_CXP_DET FROM INSERTED i;
  SELECT  @cve_operacion    = CVE_OPERACION  FROM INSERTED i;
  SELECT  @imp_bruto        = IMP_BRUTO  FROM INSERTED i;
  SELECT  @tx_nota          = TX_NOTA  FROM INSERTED i;
  SELECT  @iva              = IVA  FROM INSERTED i;
  SELECT  @rfc              = RFC  FROM INSERTED i;
  SELECT  @b_factura        = B_FACTURA  FROM INSERTED i;
  
  set @b_reg_correcto   =  @k_verdadero;

  IF   EXISTS (SELECT * FROM CI_ITEM_C_X_P  WHERE  CVE_EMPRESA    =  @cve_empresa AND
                                                   ID_CXP         =  @id_cxp      AND
                                                   ID_CXP_DET     =  @id_cxp_det)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    = 
	SUBSTRING(@tx_error_part + ': El ITEM ya existe-' + CONVERT(varchar(8),@id_cxp) + '-' + CONVERT(varchar(8),@id_cxp_det),1,300)
  END                                          

  IF (SELECT COUNT(*) FROM CI_ITEM_C_X_P i  WHERE
                           i.CVE_EMPRESA  =  @cve_empresa AND
						   i.ID_CXP       =  @id_cxp) > 0
  BEGIN
    SELECT @gpo_contable = ISNULL((SELECT GPO_CONTABLE FROM CI_OPERACION_CXP WHERE CVE_OPERACION  =  @cve_operacion), 0)

	IF  @gpo_contable  <> 
	   (SELECT TOP(1) o.GPO_CONTABLE FROM CI_ITEM_C_X_P i, CI_OPERACION_CXP o  WHERE
                                     i.CVE_EMPRESA  =  @cve_empresa AND
								     i.ID_CXP       =  @id_cxp      AND
									 i.CVE_OPERACION = o.CVE_OPERACION)
	BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =  
	  SUBSTRING(@tx_error_part + ': El grupo no corresponde a otros ITEMS ' + CONVERT(varchar(8),@id_cxp) + '-' +
	  CONVERT(varchar(8),@id_cxp_det),1,300)	  
	END      
    
	SET  @b_deudor  =  ISNULL((SELECT B_DEUDOR FROM CI_OPERACION_CXP  WHERE CVE_OPERACION = @cve_operacion),0)

    IF  @b_deudor  <> 
	   (SELECT TOP(1) o.B_DEUDOR FROM CI_ITEM_C_X_P i, CI_OPERACION_CXP o  WHERE
                                      i.CVE_EMPRESA  =  @cve_empresa AND
								      i.ID_CXP       =  @id_cxp      AND
									  i.CVE_OPERACION = o.CVE_OPERACION)
	BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =
	  SUBSTRING(@tx_error_part + ': El indicador deudor no corresp a otros ITEMS' + CONVERT(varchar(8),@id_cxp) + '-' +
	  CONVERT(varchar(8),@id_cxp_det),1,300)	  	  
	END      
    
	IF  EXISTS (SELECT 1 FROM CI_OPERACION_CXP WHERE CVE_OPERACION  =  @cve_operacion  AND
	                                                 CTA_CONTABLE   =  @k_cta_legacy)
	BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =
	  SUBSTRING(@tx_error_part + ': No se premite asigna la cta contable 900-' + CONVERT(varchar(8),@id_cxp) + '-' +
	  CONVERT(varchar(8),@id_cxp_det),1,300)	  	  
	END

    IF  (SELECT B_FACTURA FROM CI_CUENTA_X_PAGAR c WHERE
		 c.CVE_EMPRESA = @cve_empresa  AND
		 c.ID_CXP      = @id_cxp)  = @k_verdadero  AND  @b_factura = @k_verdadero
    BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =
	  SUBSTRING(@tx_error_part + ': CxP e Item tienen Factura-' + CONVERT(varchar(8),@id_cxp) + '-' +
	  CONVERT(varchar(8),@id_cxp_det),1,300)	  	  
    END

    IF  @b_factura IS NULL
    BEGIN
      SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =
	  SUBSTRING(@tx_error_part + ': Bandera factura es nulo' + CONVERT(varchar(8),@id_cxp) + '-' +
	  CONVERT(varchar(8),@id_cxp_det),1,300)	  	  
    END
  END       

  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
    BEGIN TRY
    INSERT   CI_ITEM_C_X_P 
            (CVE_EMPRESA,
             ID_CXP,
			 ID_CXP_DET,
			 CVE_OPERACION,
			 IMP_BRUTO,
			 TX_NOTA,
			 IVA,
			 RFC,
			 B_FACTURA)  VALUES
            (@cve_empresa,
             @id_cxp,
             @id_cxp_det,
             @cve_operacion,
             @imp_bruto,
             @tx_nota,
             @iva,
             @rfc,
			 @b_factura)
    END TRY
	BEGIN CATCH
	SET @tx_error_part    =  ISNULL(ERROR_MESSAGE(), ' ')
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
    SET @tx_error_part    =  @tx_error_part + ': No se permiten INSERTs multiples';	  
  END

END

