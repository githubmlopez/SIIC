USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spValCtaCont]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros   int, 
           @RowCount       int

  DECLARE  @k_cliente      varchar(15)  =  'Cliente',
           @k_Parametro    varchar(15)  =  'Parametro',
		   @k_chequera     varchar(15)  =  'Chequera',
		   @k_proveedor    varchar(15)  =  'Proveedor',
		   @k_dolar        varchar(1)   =  'D',
		   @k_error        varchar(1)   =  'E'

  DECLARE  @cve_moneda     varchar(1),
           @cta_cont1      varchar(30),
		   @cta_cont2      varchar(30),
		   @cta_cont3      varchar(30),
		   @origen         varchar(15)

  DECLARE  @TCuentas       TABLE
          (RowID           int  identity(1,1),
		   CTA_CONTABLE    varchar(30),
		   ORIGEN          varchar(15))

  DECLARE  @TCtaCheq       TABLE
          (RowID           int  identity(1,1),
		   CVE_MONEDA      varchar(1),
		   CTA_CONT1       varchar(30),
		   CTA_CONT2       varchar(30))

  DECLARE  @TCtaProv       TABLE
          (RowID           int  identity(1,1),
		   CTA_CONT1       varchar(30),
		   CTA_CONT2       varchar(30),
           CTA_CONT3       varchar(30))

  INSERT @TCuentas (CTA_CONTABLE, ORIGEN)  
  SELECT  CTA_CONTABLE, @k_cliente FROM CI_CTA_CONT_CTE
  
  INSERT @TCuentas (CTA_CONTABLE, ORIGEN)  
  SELECT  SUBSTRING(VALOR_ALFA,1,30), @k_Parametro FROM CI_PARAMETRO  WHERE
          SUBSTRING(VALOR_ALFA,4,1)  = '-'  AND
		  SUBSTRING(VALOR_ALFA,7,1)  = '-'   

  INSERT @TCtaCheq (CVE_MONEDA, CTA_CONT1, CTA_CONT2)
  SELECT  CVE_MONEDA, CTA_CONTABLE, ISNULL(' ',CTA_CONT_COMP) FROM CI_CHEQUERA  

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_moneda  =  CVE_MONEDA, @cta_cont1  =  CTA_CONT1, @cta_cont2  = CTA_CONT2
    FROM   @TCtaCheq
    WHERE  RowID = @RowCount
    
	INSERT @TCuentas (CTA_CONTABLE, ORIGEN) 
	VALUES (@cta_cont1, @k_chequera)

	IF  @cve_moneda  =  @k_dolar
	BEGIN
      INSERT @TCuentas (CTA_CONTABLE, ORIGEN) 
	  VALUES (@cta_cont2, @k_chequera)
	END

    SET @RowCount = @RowCount + 1
  END


  INSERT @TCtaProv (CTA_CONT1, CTA_CONT2, CTA_CONT3) 
  SELECT  ISNULL(' ', CTA_CONTABLE), ISNULL(' ', CTA_CONT_USD), ISNULL(' ', CTA_CONT_COMP) FROM CI_PROVEEDOR  

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cta_cont1  =  CTA_CONT1, @cta_cont2  = CTA_CONT2, @cta_cont3  = CTA_CONT3
    FROM   @TCtaProv
    WHERE  RowID = @RowCount
    
	IF  @cta_cont1  <>  ' '
	BEGIN
      INSERT @TCuentas (CTA_CONTABLE, ORIGEN) 
	  VALUES (@cta_cont1, @k_proveedor)
	END

	IF  @cta_cont2  <>  ' '
	BEGIN
      INSERT @TCuentas (CTA_CONTABLE, ORIGEN) 
	  VALUES (@cta_cont2, @k_proveedor)
	END

    IF  @cta_cont3  <>  ' '
	BEGIN
      INSERT @TCuentas (CTA_CONTABLE, ORIGEN) 
	  VALUES (@cta_cont3, @k_proveedor)
	END

    SET @RowCount = @RowCount + 1
  END

  SET @NunRegistros = (SELECT COUNT(*) FROM   @TCuentas)
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cta_cont1  = CTA_CONTABLE
    FROM   @TCuentas
    WHERE  RowID = @RowCount
    
	IF  NOT EXISTS(SELECT 1 FROM CI_CAT_CTA_CONT  WHERE  CTA_CONTABLE  =  @cta_cont1)
	BEGIN
      SET  @pError    =  'No Existe Cuenta ' +  @cta_cont1 + @origen
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
 	END

    SET @RowCount = @RowCount + 1
  END

END