USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnArmaProducto]    Script Date: 20/07/2018 08:36:33 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnArmaFacturas] (@IdMovtoBancario int)
RETURNS varchar(60)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  
  DECLARE  @facturas        varchar(60),
           @conc_factura    varchar(20)

  set @facturas = ' '	 

  DECLARE curFactura CURSOR FOR SELECT f.CVE_EMPRESA + '/' +  f.SERIE + '/' + CONVERT(VARCHAR(10),f.ID_CXC)
  FROM  CI_FACTURA f, CI_CONCILIA_C_X_C c
  WHERE    
  c.ID_MOVTO_BANCARIO   = @IdMovtoBancario   AND
  c.ID_CONCILIA_CXC     = f.ID_CONCILIA_CXC     
  
  OPEN  curFactura

  FETCH curFactura INTO  @conc_factura  
    
  WHILE (@@fetch_status = 0 )
  BEGIN 

    SET @facturas = 
	RTRIM(LTRIM(@facturas) + RTRIM(@conc_factura) + '-')
    SET  @facturas = SUBSTRING(@facturas,1,LEN(@facturas) - 1)
    
    FETCH curFactura  INTO  @conc_factura
    
  END  

  close curFactura 
  deallocate curFactura

  return(@facturas)

END

