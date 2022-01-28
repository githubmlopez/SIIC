USE ADMON01		
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spConcMetaSat')
BEGIN
  DROP  PROCEDURE spConcMetaSat
END
GO
--EXEC spConcMetaSat 1,'EGG','MARIO','SIIC','202011',15,1,1,0,' ',' '
CREATE PROCEDURE [dbo].[spConcMetaSat]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pBError        bit OUT,
@pError         varchar(80) OUT, 
@pMsgError      varchar(400) OUT
)
AS
BEGIN

  DECLARE @NumRegistros  int,
          @RowCount      int,
		  @rfc           varchar(15),
		  @id_unico      varchar(36),
		  @sit_proc      varchar(4),
          @tipo_meta     varchar(4)

  DECLARE @k_verdadero   bit  =  1,
          @k_falso       bit  =  0,
		  @k_cxc         varchar(4) = 'FACT',
		  @k_cxp         varchar(4) = 'CXP',
		  @k_match       varchar(4) = 'MT',
		  @k_match_ni    varchar(4) = 'NI',
		  @k_nmbsource   varchar(4) = 'SO',
		  @k_nmbtarget   varchar(4) = 'TA',
		  @k_error       varchar(1) = 'E',
		  @k_ingreso     varchar(1) = 'I'

  DECLARE @TMetadata table
  (RowID         int  identity(1,1),
   ID_UNICO      varchar(36),
   RFC_EMISOR    varchar(15),
   RFC_RECEPTOR  varchar(15),
   IMP_FACTURA   numeric(12,2),
   IMP_CFDI      numeric(12,2),
   SIT_PROC      varchar(4))

  DECLARE @TMetError table
  (RowID         int  identity(1,1),
   ID_UNICO      varchar(36),
   RFC_EMISOR    varchar(15),
   RFC_RECEPTOR  varchar(15),
   IMP_FACTURA   numeric(12,2),
   IMP_CFDI      numeric(12,2),
   SIT_PROC      varchar(4))

  DECLARE @TCfdi table
  (UUID          varchar(36),
   RFC_EMI       varchar(15), 
   RFC_REC       varchar(15), 
   IMP_TOTAL     numeric(12,2))

  SELECT
  @tipo_meta  = SUBSTRING(PARAMETRO,1,4)
  FROM FC_PROCESO  WHERE
  CVE_EMPRESA    = @pCveEmpresa    AND
  ID_PROCESO     = @pIdProceso


  IF  @tipo_meta  = @k_cxc
  BEGIN
    INSERT @TMetadata (ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, IMP_CFDI, SIT_PROC)
    SELECT s.ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, 0, ' '
    FROM CFDI_META_CXC s WHERE ANO_MES_PROC = @pAnoPeriodo  AND EFECTO_COMPROB = @k_ingreso AND B_AUTOMATICO = @k_verdadero

    INSERT @TCfdi (UUID, RFC_EMI, RFC_REC, IMP_TOTAL)
    SELECT c.UUID, e.RFC_EMI, r.RFC_REC, c.IMP_TOTAL
    FROM CFDI_COMPROBANTE c, CFDI_EMISOR e, CFDI_RECEPTOR r WHERE
    c.CVE_EMPRESA      = @pCveEmpresa  AND
    c.ANO_MES          = @pAnoPeriodo  AND 
    c.CVE_TIPO         = @k_cxc        AND
    c.CVE_EMPRESA      = r.CVE_EMPRESA AND
    c.ANO_MES          = r.ANO_MES     AND
    c.CVE_TIPO         = r.CVE_TIPO    AND
    c.UUID             = r.UUID        AND
    c.ANO_MES          = e.ANO_MES     AND
    c.CVE_TIPO         = e.CVE_TIPO    AND
    c.UUID             = e.UUID        AND
	c.CVE_TIPO_COMPROB =  @k_ingreso
  END
  ELSE
  BEGIN
    INSERT @TMetadata (ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, IMP_CFDI, SIT_PROC)
    SELECT s.ID_UNICO, RFC_EMISOR, 	RFC_RECEPTOR, IMP_FACTURA, 0, ' '
    FROM CFDI_META_CXP s WHERE ANO_MES_PROC = @pAnoPeriodo  AND EFECTO_COMPROB = @k_ingreso AND B_AUTOMATICO = @k_verdadero

    INSERT @TCfdi (UUID, RFC_EMI, RFC_REC, IMP_TOTAL)
    SELECT c.UUID, e.RFC_EMI, r.RFC_REC, c.IMP_TOTAL
    FROM CFDI_COMPROBANTE c, CFDI_EMISOR e, CFDI_RECEPTOR r WHERE
    c.CVE_EMPRESA = @pCveEmpresa  AND
    c.ANO_MES     = @pAnoPeriodo  AND 
    c.CVE_TIPO    = @k_cxp        AND
    c.CVE_EMPRESA = r.CVE_EMPRESA AND
    c.ANO_MES     = r.ANO_MES     AND
    c.CVE_TIPO    = r.CVE_TIPO    AND
    c.UUID        = r.UUID        AND
    c.ANO_MES     = e.ANO_MES     AND
    c.CVE_TIPO    = e.CVE_TIPO    AND
    c.UUID        = e.UUID        AND
	c.CVE_TIPO_COMPROB =  @k_ingreso

  END

  MERGE @TMetadata AS target  
    USING @TCfdi AS source
    ON (target.ID_UNICO = source.UUID) 
    WHEN MATCHED 
	THEN
        UPDATE SET target.SIT_PROC = @k_match, IMP_CFDI = source.IMP_TOTAL 
    WHEN NOT MATCHED BY TARGET THEN  
        INSERT (ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, IMP_CFDI, SIT_PROC)  
        VALUES (source.UUID, source.RFC_EMI, source.RFC_REC, source.IMP_TOTAL, 0, @k_nmbtarget) 
	WHEN NOT MATCHED BY SOURCE THEN  
        UPDATE SET TARGET.SIT_PROC = @k_nmbsource;

	--SELECT * FROM @TMetadata  WHERE 
	--SIT_PROC <>  @k_match  OR 
 --  (SIT_PROC =   @k_match  AND IMP_FACTURA <> IMP_CFDI)
 
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT @TMetError (ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, IMP_CFDI, SIT_PROC) 
    SELECT ID_UNICO, RFC_EMISOR, RFC_RECEPTOR, IMP_FACTURA, IMP_CFDI, SIT_PROC FROM @TMetadata  WHERE     
	SIT_PROC <>  @k_match  OR 
   (SIT_PROC =   @k_match  AND IMP_FACTURA <> IMP_CFDI)
    SET @NumRegistros =  @@ROWCOUNT
------------------------------------------------------------------------------------------------------
    SET @RowCount     = 1
    WHILE @RowCount <= @NumRegistros
    BEGIN
      SET  @pBError  =  @k_verdadero
      SELECT @id_unico = ID_UNICO, @sit_proc  =  SIT_PROC
	  FROM   @TMetError  WHERE  RowID = @RowCount
      SET  @pError    = 
	  CASE
	  WHEN  @sit_proc  =  @k_match
	  THEN  'Match pero <> importe : ' +   @id_unico 
	  WHEN  @sit_proc  =  @k_nmbsource
	  THEN  'No existe en CFDI : ' +   @id_unico 
	  WHEN  @sit_proc  =  @k_nmbtarget
	  THEN  'No existe en Metadata : ' +   @id_unico
	  END; 
      SET  @pMsgError =  @pError +  ' '
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
--      SELECT @pMsgError
      SET @RowCount     =  @RowCount + 1
	END
END


  
