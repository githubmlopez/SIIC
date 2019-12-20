USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtCveOper')
BEGIN
  DROP  FUNCTION fnObtCveOper
END
GO
CREATE FUNCTION [dbo].[fnObtCveOper] 
(
@pCveEmpresa    varchar(4),
@pAnoPeriodo    varchar(6),
@pCveTipo       varchar(4),
@pUuid          varchar(36),
@pCveProdServ   varchar(8)          
)
RETURNS varchar(4)						  
AS
BEGIN
  DECLARE  @cve_operacion   varchar(4) = ' ',
           @cve_prod_serv   varchar(8)  

  SET  @cve_prod_serv =  SUBSTRING(@pCveProdServ,1,6) + '00'
  IF EXISTS (SELECT 1 FROM CFDI_CAT_PRODUC  WHERE  CVE_PROD_SERV  =  @cve_prod_serv)
  BEGIN
    SET @cve_operacion  =  ISNULL(  
   (SELECT CVE_OPERACION FROM CFDI_CAT_PRODUC WHERE CVE_PROD_SERV  =  @cve_prod_serv)
    ,' ')
  END

  IF EXISTS (SELECT 1 FROM CFDI_CAT_PRODUC  WHERE  CVE_PROD_SERV  =  @pCveProdServ)
  BEGIN
    SET @cve_operacion  =  ISNULL(  
   (SELECT CVE_OPERACION FROM CFDI_CAT_PRODUC WHERE CVE_PROD_SERV  =  @pCveProdServ)
    ,' ')
  END

  IF  EXISTS (SELECT 1 FROM CDFI_OPER_COMPROB WHERE 
      CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoPeriodo AND CVE_TIPO = @pCveTipo  AND UUID = @pUuid)
  BEGIN
    SET @cve_operacion  =  ISNULL(  
   (SELECT CVE_OPERACION FROM CDFI_OPER_COMPROB WHERE 
    CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoPeriodo AND CVE_TIPO = @pCveTipo  AND UUID = @pUuid)
    ,' ')
  END

  RETURN(@cve_operacion) 
END

