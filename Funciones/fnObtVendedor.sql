USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtVendedor]    Script Date: 16/11/2020 06:18:10 a. m. ******/
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtVendedor')
BEGIN
  DROP  FUNCTION fnObtVendedor
END
GO
CREATE FUNCTION [dbo].[fnObtVendedor] 
(
@pCveEmpresa    varchar(4),
@pSerie         varchar(6),     
@pIdCxC         int,
@pIdItem        int
)
RETURNS varchar(4)						  
AS
BEGIN
  DECLARE  @cve_vendedor    varchar(4),
           @num_vendedores  varchar(4),
		   @cont_venta      varchar(4) = 'COVT',
           @venta           varchar(4) = 'VENT',
           @pres_venta      varchar(4) = 'PRVT', 
		   @venta_vesc      varchar(4) = 'VESC'

  IF
 (SELECT COUNT(*)  FROM VTA_COMIS_ITEM
  WHERE    CVE_EMPRESA  =  @pCveEmpresa AND SERIE = @pSerie AND ID_CXC = @pIdCxC AND ID_ITEM = @pIdItem) 
  > 1
  BEGIN
    SET @cve_vendedor = 
   (SELECT TOP 1 CVE_VENDEDOR  FROM VTA_COMIS_ITEM
    WHERE    CVE_EMPRESA  =  @pCveEmpresa AND SERIE = @pSerie AND ID_CXC = @pIdCxC AND ID_ITEM = @pIdItem AND
	CVE_PROCESO IN (@cont_venta, @cont_venta, @venta, @pres_venta, @venta_vesc))  
  END
  ELSE
  BEGIN
    SET @cve_vendedor = 
   (SELECT CVE_VENDEDOR  FROM VTA_COMIS_ITEM
    WHERE    CVE_EMPRESA  =  @pCveEmpresa AND SERIE = @pSerie AND ID_CXC = @pIdCxC AND ID_ITEM = @pIdItem) 
  END
  RETURN @cve_vendedor
END



