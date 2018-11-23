USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spRepIva]    Script Date: 03/10/2018 06:40:14 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC spRepIva 'CU', '201804','2'
ALTER PROCEDURE [dbo].[spRepIva]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pOpcion varchar(1)
AS
BEGIN

  DECLARE  @k_verdadero      bit  =  1,   
           @k_falso          bit  =  0,
		   @k_acreditado     varchar(1) =  '1',
		   @k_no_acred       varchar(1) =  '2',
		   @k_ambos          varchar(1) =  '3'
  SELECT 
  CVE_EMPRESA,
  ANO_MES,
  ID_SECUENCIA,
  CVE_TIPO,
  CONCEPTO,
  RFC,
  ID_PROVEEDOR,
  CVE_TIPO_OPERACION,
  IMP_BRUTO,
  IMP_IVA,
  B_ACREDITADO,
  ISNULL(ANO_MES_ACRED,' ') AS ANO_MES_ACRED
  FROM CI_PERIODO_IVA
  WHERE CVE_EMPRESA  = @pCveEmpresa  AND ANO_MES   = @pAnoMes AND
      ((B_ACREDITADO = @k_falso      AND @pOpcion  = @k_no_acred)    OR  
       (B_ACREDITADO = @k_verdadero  AND @pOpcion  = @k_acreditado)  OR
	   (@pOpcion     = @k_ambos)) 

END