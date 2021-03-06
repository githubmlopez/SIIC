USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXP]    Script Date: 09/08/2018 03:45:34 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_CUENTA_X_PAGAR for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCXP] ON [dbo].[CI_CUENTA_X_PAGAR]
INSTEAD OF INSERT
AS

BEGIN

  DECLARE
  @cve_empresa        varchar(4),
  @id_cxp             int,
  @id_proveedor       int,
  @cve_chequera       varchar(6),
  @cve_tipo_movto     varchar(6),
  @f_captura          date,
  @f_pago             date,
  @imp_bruto          numeric(12,2),
  @imp_iva            numeric(12,2),
  @imp_ret_iva        numeric(12,2),
  @imp_ret_isr        numeric(12,2),
  @imp_neto           numeric(12,2),
  @imp_rescate        numeric(12,2),
  @cve_moneda         varchar(1),
  @tipo_cambio        numeric(8,2),
  @cve_forma_pago     varchar(1),
  @num_cheque         numeric(6,0),
  @num_docto_ref      varchar(40),
  @refer_pago         varchar(70),
  @tx_nota            varchar(200),
  @num_doctos_asoc    numeric(2,0),
  @nombre_docto_pdf   varchar(25),
  @nombre_docto_xml   varchar(25),
  @firma              varchar(10),
  @b_solic_transf     bit,
  @id_concilia_cxp    int,
  @sit_concilia_cxp   varchar(2),
  @sit_c_x_p          varchar(2),
  @f_cancelacion      date,
  @b_emp_servicio     bit,
  @b_factura          bit


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
   @k_dolar         varchar(1)  =  'D',
   @k_fol_audit     varchar(4)  =  'AUDI',
   @k_fol_act       varchar(4)  =  'NACT',
   @k_cheque        varchar(1)  =  'C'

  SET  @b_reg_correcto =  @k_verdadero

  IF  (SELECT COUNT(*) FROM INSERTED) = 1
  BEGIN

  SET  @tx_error_part  =  ' '

-- Inicialización de datos 

  SELECT  @cve_empresa          = CVE_EMPRESA FROM inserted i
  SELECT  @id_cxp               = ID_CXP FROM  inserted i
  SELECT  @id_proveedor         = ID_PROVEEDOR FROM  inserted i
  SELECT  @cve_chequera         = CVE_CHEQUERA FROM  inserted i
  SELECT  @cve_tipo_movto       = CVE_TIPO_MOVTO FROM  inserted i
  SELECT  @f_captura            = F_CAPTURA FROM  inserted i
  SELECT  @f_pago               = F_PAGO FROM  inserted i
  SELECT  @imp_bruto            = IMP_BRUTO FROM  inserted i
  SELECT  @imp_iva              = IMP_IVA FROM  inserted 
  SELECT  @imp_ret_iva          = IMP_RET_IVA FROM  inserted i
  SELECT  @imp_ret_isr          = IMP_RET_ISR FROM  inserted i
  SELECT  @imp_neto             = IMP_NETO FROM  inserted i
  SELECT  @imp_rescate          = IMP_RESCATE FROM  inserted i
  SELECT  @cve_moneda           = CVE_MONEDA FROM  inserted i
  SELECT  @tipo_cambio          = TIPO_CAMBIO FROM  inserted i
  SELECT  @cve_forma_pago       = CVE_FORMA_PAGO FROM  inserted i
  SELECT  @num_cheque           = NUM_CHEQUE FROM  inserted i
  SELECT  @num_docto_ref        = NUM_DOCTO_REF FROM  inserted i
  SELECT  @refer_pago           = REFER_PAGO FROM  inserted i
  SELECT  @tx_nota              = TX_NOTA FROM  inserted i
  select  @num_doctos_asoc      = NUM_DOCTOS_ASOC FROM  inserted i
  SELECT  @nombre_docto_pdf     = NOMBRE_DOCTO_PDF FROM  inserted i
  SELECT  @nombre_docto_xml     = NOMBRE_DOCTO_XML FROM  inserted i
  SELECT  @firma                = FIRMA FROM  inserted i
  SELECT  @b_solic_transf       = B_SOLIC_TRANSF FROM  inserted i
  SELECT  @id_concilia_cxp      = ID_CONCILIA_CXP FROM  inserted i
  SELECT  @sit_concilia_cxp     = SIT_CONCILIA_CXP FROM  inserted i
  SELECT  @sit_c_x_p            = SIT_C_X_P FROM  inserted i
  SELECT  @f_cancelacion        = F_CANCELACION FROM  inserted i
  SELECT  @b_emp_servicio       = B_EMP_SERVICIO FROM inserted i
  SELECT  @b_factura            = B_FACTURA FROM inserted i


  SET @b_reg_correcto   =  @k_verdadero;

  SET @tx_error_part    =  ' ';

  IF   EXISTS (SELECT * FROM CI_CUENTA_X_PAGAR  WHERE  CVE_EMPRESA    =  @cve_empresa AND
                                                       ID_CXP         =  @id_cxp)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La CXP ya existe-' + CONVERT(varchar(8),@id_cxp),1,300)
  END                                          

  IF  @cve_moneda  <>
     (SELECT CVE_MONEDA  FROM  CI_CHEQUERA  WHERE CVE_CHEQUERA = @cve_chequera)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La moneda no corresp la chequera-' + CONVERT(varchar(8),@id_cxp),1,300)
  END                                

  IF  @cve_moneda  =  @k_dolar  AND ISNULL(@tipo_cambio,0)  = 0
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': En USD especif tipo de cambio-' + CONVERT(varchar(8),@id_cxp),1,300);
  END                    
 
  IF  @cve_forma_pago  =  @k_cheque  AND  
     (SELECT B_CHEQUE FROM CI_CHEQUERA WHERE CVE_CHEQUERA = @cve_chequera) = @k_falso 
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La chequera no permite cheques-' + CONVERT(varchar(8),@id_cxp),1,300);
  END 
  
  IF  (@imp_bruto + @imp_iva - @imp_ret_iva - @imp_ret_isr)  <>  @imp_neto  
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Imp Neto <> a Imp. Bruto + IVA ' + CONVERT(varchar(8),@id_cxp),1,300);
  END   
  
  IF  @b_factura  IS NULL  
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Bandera Factura nullo ' + CONVERT(varchar(8),@id_cxp),1,300);
  END         
         
  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
    BEGIN TRY

    INSERT   CI_CUENTA_X_PAGAR
   (CVE_EMPRESA,
    ID_CXP,  
    ID_PROVEEDOR,  
    CVE_CHEQUERA,  
    CVE_TIPO_MOVTO,  
    F_CAPTURA,  
    F_PAGO,  
    IMP_BRUTO,  
    IMP_IVA, 
    IMP_RET_IVA,  
    IMP_RET_ISR,  
    IMP_NETO,  
    IMP_RESCATE,  
    CVE_MONEDA,  
    TIPO_CAMBIO,  
    CVE_FORMA_PAGO,  
    NUM_CHEQUE,  
    NUM_DOCTO_REF,  
    REFER_PAGO,  
    TX_NOTA,  
    NUM_DOCTOS_ASOC,  
    NOMBRE_DOCTO_PDF,  
    NOMBRE_DOCTO_XML,  
    FIRMA,  
    B_SOLIC_TRANSF,  
    ID_CONCILIA_CXP,  
    SIT_CONCILIA_CXP,  
    SIT_C_X_P,  
    F_CANCELACION,
	B_EMP_SERVICIO,
	B_FACTURA) 
    VALUES
   (@cve_empresa, 
    @id_cxp,       
    @id_proveedor,  
    @cve_chequera,  
    @cve_tipo_movto,  
    @f_captura,       
    @f_pago,          
    @imp_bruto,       
    @imp_iva,        
    @imp_ret_iva,     
    @imp_ret_isr,     
    @imp_neto,        
    @imp_rescate,     
    @cve_moneda,      
    @tipo_cambio,     
    @cve_forma_pago,   
    @num_cheque,       
    @num_docto_ref,    
    @refer_pago,       
    @tx_nota,          
    @num_doctos_asoc,  
    @nombre_docto_pdf,  
    @nombre_docto_xml,  
    @firma,             
    @b_solic_transf,    
    @id_concilia_cxp,   
    @sit_concilia_cxp,  
    @sit_c_x_p,         
    @f_cancelacion,
	@b_emp_servicio,
	@b_factura )     
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
    SET @tx_error_part    =  @tx_error_part + ': No se permiten INSERTs multiples'
	RAISERROR(@tx_error_part,11,1)  
  END


END

