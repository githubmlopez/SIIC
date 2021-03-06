USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCXC] ON [dbo].[CI_FACTURA]
INSTEAD OF INSERT
AS

BEGIN

  DECLARE
	  @cve_empresa        varchar(4),
	  @serie              varchar(6),
	  @id_cxc             int,
	  @f_operacion        date,
	  @f_captura          date,
	  @f_real_pago        date ,
	  @tipo_cambio        numeric(8,4),
	  @cve_chequera       varchar(6),
	  @id_venta           int,
	  @id_fact_parcial    int,
	  @cve_tipo_contrato  varchar(1),
	  @cve_f_moneda       varchar(1),
	  @imp_f_bruto        numeric(12,2),
	  @imp_f_iva          numeric(12,2),
	  @imp_f_neto         numeric(12,2),
	  @cve_r_moneda       varchar(1),
	  @imp_r_neto_com     numeric(12,2),
	  @imp_r_neto         numeric(12,2),
	  @tipo_cambio_liq    numeric(8,4),
	  @tx_nota            varchar(400),
	  @nombre_docto_pdf   varchar(25),
	  @nombre_docto_xml   varchar(25),
	  @firma              varchar(10),
	  @b_factura_pagada   bit,
	  @id_concilia_cxc    int,
	  @sit_concilia_cxc   varchar(2),
	  @sit_transaccion    varchar(2),
	  @f_compromiso_pago  date,
	  @tx_nota_cobranza   varchar(200),
	  @f_cancelacion      date,
	  @b_factura          bit,
	  @cve_subproducto    varchar(8)

  DECLARE
    @cve_producto     varchar(4),
    @cve_producto_i   varcHAR(4),
    @cve_tipo_docum   varchar(2),
	@ano_mes          varchar(6)


  DECLARE
   @b_reg_correcto   bit,
   @tx_error         varchar(300),
   @tx_error_part    varchar(300),
   @fol_act          int,
   @fol_audit        int,
   @cve_moneda       varchar(1)

  DECLARE 
   @k_verdadero     bit = 1,
   @k_falso         bit = 0,
   @k_dolar         varchar(1)  =  'D',
   @k_fol_audit     varchar(4)  =  'AUDI',
   @k_fol_act       varchar(4)  =  'NACT',
   @k_pendiente     varchar(1)  =  'P',
   @k_factura       varchar(4)  =  'FACT',
   @k_cerrado       varchar(1)  =  'C'

  SET  @tx_error_part  =  ' '

  IF  (SELECT COUNT(*) FROM INSERTED) = 1
  BEGIN

  SET  @b_reg_correcto =  @k_verdadero

-- Inicialización de datos 

  SELECT @cve_empresa        =  CVE_EMPRESA       FROM INSERTED i
  SELECT @serie              =  SERIE             FROM INSERTED i
  SELECT @id_cxc             =  ID_CXC            FROM INSERTED i
  SELECT @f_operacion        =  F_OPERACION       FROM INSERTED i
  SELECT @f_captura          =  F_CAPTURA         FROM INSERTED i
  SELECT @f_real_pago        =  F_REAL_PAGO       FROM INSERTED i
  SELECT @tipo_cambio        =  TIPO_CAMBIO       FROM INSERTED i
  SELECT @cve_chequera       =  CVE_CHEQUERA      FROM INSERTED i
  SELECT @id_venta           =  ID_VENTA          FROM INSERTED i
  SELECT @id_fact_parcial    =  ID_FACT_PARCIAL   FROM INSERTED i
  SELECT @cve_tipo_contrato  =  CVE_TIPO_CONTRATO FROM INSERTED i
  SELECT @cve_f_moneda       =  CVE_F_MONEDA      FROM INSERTED i
  SELECT @imp_f_bruto        =  IMP_F_BRUTO       FROM INSERTED i
  SELECT @imp_f_iva          =  IMP_F_IVA         FROM INSERTED i
  SELECT @imp_f_neto         =  IMP_F_NETO        FROM INSERTED i
  SELECT @cve_r_moneda       =  CVE_R_MONEDA      FROM INSERTED i
  SELECT @imp_r_neto_com     =  IMP_R_NETO_COM    FROM INSERTED i
  SELECT @imp_r_neto         =  IMP_R_NETO        FROM INSERTED i
  SELECT @tipo_cambio_liq    =  TIPO_CAMBIO_LIQ   FROM INSERTED i
  SELECT @tx_nota            =  TX_NOTA           FROM INSERTED i
  SELECT @nombre_docto_pdf   =  NOMBRE_DOCTO_PDF  FROM INSERTED i
  SELECT @nombre_docto_xml   =  NOMBRE_DOCTO_XML  FROM INSERTED i
  SELECT @firma              =  FIRMA             FROM INSERTED i
  SELECT @b_factura_pagada   =  B_FACTURA_PAGADA  FROM INSERTED i
  SELECT @id_concilia_cxc    =  ID_CONCILIA_CXC   FROM INSERTED i
  SELECT @sit_concilia_cxc   =  SIT_CONCILIA_CXC  FROM INSERTED i
  SELECT @sit_transaccion    =  SIT_TRANSACCION   FROM INSERTED i
  SELECT @f_compromiso_pago  =  F_COMPROMISO_PAGO FROM INSERTED i
  SELECT @tx_nota_cobranza   =  TX_NOTA_COBRANZA  FROM INSERTED i
  SELECT @f_cancelacion      =  F_CANCELACION     FROM INSERTED i
  SELECT @b_factura          =  B_FACTURA         FROM INSERTED i  


  set @b_reg_correcto   =  @k_verdadero;

  set @tx_error_part    =  ' ';

  IF   EXISTS (SELECT * FROM CI_FACTURA  WHERE  CVE_EMPRESA    =  @cve_empresa AND
                                                ID_CXC         =  @id_cxc)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La CXC ya existe-' + CONVERT(varchar(8),@id_cxc),1,300)
  END                                          

  IF  @cve_moneda  =  @k_dolar  AND  ISNULL(@tipo_cambio,0) = 0
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': En USD se requiere T. Cambio-' + CONVERT(varchar(8),@id_cxc),1,300)
  END                         

  IF  @cve_moneda  <>
     (SELECT CVE_MONEDA  FROM  CI_CHEQUERA  WHERE CVE_CHEQUERA = @cve_chequera)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La moneda no corresp a chequera-' + CONVERT(varchar(8),@id_cxc),1,300)
  END 

  IF  (@imp_f_bruto + @imp_f_iva)  <>  @imp_f_neto  
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Imp Neto <> a Imp. Bruto + IVA-' + CONVERT(varchar(8),@id_cxc),1,300);
  END      

  IF  @b_factura  IS NULL 
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Bandera factura nulo' + CONVERT(varchar(8),@id_cxc),1,300);
  END      

  IF  @f_cancelacion IS NOT NULL 
  BEGIN
    SET @ano_mes = dbo.fnArmaAnoMes (YEAR(@f_cancelacion), MONTH(@f_cancelacion))

    IF  EXISTS (SELECT 1 FROM  CI_PERIODO_CONTA  WHERE  CVE_EMPRESA = @cve_empresa  AND ANO_MES =  @ano_mes)
	BEGIN
      IF  (SELECT SIT_PERIODO FROM  CI_PERIODO_CONTA  WHERE  CVE_EMPRESA = @cve_empresa  AND ANO_MES =  @ano_mes) =  @k_cerrado
	  BEGIN
	    SET @b_reg_correcto   =  @k_falso;
        SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Fecha de Cancelacion Invalida' + CONVERT(varchar(8),@id_cxc),1,300);
	  END
    END      
    ELSE
	BEGIN
	  SET @b_reg_correcto   =  @k_falso;
      SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Fecha de Can. Per. Cerrado ' + CONVERT(varchar(8),@id_cxc),1,300);
	END
  END

  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
    BEGIN TRY
    INSERT   CI_FACTURA 
            (CVE_EMPRESA,            
             SERIE,                  
             ID_CXC,                 
             F_OPERACION,            
             F_CAPTURA,              
             F_REAL_PAGO,            
             TIPO_CAMBIO,            
             CVE_CHEQUERA,           
             ID_VENTA,          
             ID_FACT_PARCIAL,        
             CVE_TIPO_CONTRATO,      
             CVE_F_MONEDA,           
             IMP_F_BRUTO,            
             IMP_F_IVA,              
             IMP_F_NETO,             
             CVE_R_MONEDA,           
             IMP_R_NETO_COM,         
             IMP_R_NETO,             
             TIPO_CAMBIO_LIQ,        
             TX_NOTA,                
             NOMBRE_DOCTO_PDF,       
             NOMBRE_DOCTO_XML,       
             FIRMA,                  
             B_FACTURA_PAGADA,       
             ID_CONCILIA_CXC,        
             SIT_CONCILIA_CXC,       
             SIT_TRANSACCION,        
             F_COMPROMISO_PAGO,      
             TX_NOTA_COBRANZA,       
             F_CANCELACION,          
             B_FACTURA)               
    VALUES
	        (@cve_empresa,
	         @serie,
	         @id_cxc,
	         @f_operacion,
	         @f_captura,
	         @f_real_pago,
	         @tipo_cambio,
	         @cve_chequera,
	         @id_venta,
	         @id_fact_parcial,
	         @cve_tipo_contrato,
	         @cve_f_moneda,
	         @imp_f_bruto,
	         @imp_f_iva,
	         @imp_f_neto,
	         @cve_r_moneda,
	         @imp_r_neto_com,
	         @imp_r_neto,
	         @tipo_cambio_liq,
	         @tx_nota,
	         @nombre_docto_pdf,
	         @nombre_docto_xml,
	         @firma,
	         @b_factura_pagada,
	         @id_concilia_cxc,
	         @sit_concilia_cxc,
	         @sit_transaccion,
	         @f_compromiso_pago,
	         @tx_nota_cobranza,
	         @f_cancelacion,
	         @b_factura)

    IF EXISTS (SELECT 1 FROM CI_DOCUM_PRODUCTO  WHERE CVE_PRODUCTO = @k_factura)
    BEGIN
      declare docum_cursor cursor for SELECT CVE_PRODUCTO, CVE_TIPO_DOCUM FROM CI_DOCUM_PRODUCTO
                                      WHERE CVE_PRODUCTO = @cve_producto 
      open  docum_cursor

      FETCH docum_cursor INTO  @cve_producto_i, @cve_tipo_docum  
    
      WHILE (@@fetch_status = 0 )
      BEGIN 
        Insert into CI_DOCUM_ITEM
                   (CVE_EMPRESA,
                    SERIE,
                    ID_CXC,
                    ID_ITEM,
                    CVE_TIPO_DOCUM,
                    SITUACION, 
                    NOMBRE_DOCTO_PDF)
               values     
                   (@cve_empresa,
                    @serie,
                    @id_cxc,
                    0,
                    @cve_tipo_docum,
                    @k_pendiente,
                    ' ')     

        FETCH docum_cursor INTO  @cve_producto_i, @cve_tipo_docum  

      END

    END
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


