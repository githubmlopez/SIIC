USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCtasXCobCan')
BEGIN
  DROP  PROCEDURE spCtasXCobCan
END
GO
--EXEC spCtasXCobCan 1,'CU','MARIO','SIIC','201906',200,37,1,0,' ',' '
CREATE PROCEDURE spCtasXCobCan  
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
AS
BEGIN
  DECLARE  @TCCobrar  TABLE
          (RowID      int  identity(1,1),
           SERIE      varchar(6),
           ID_CXC     int,
		   UUID       varchar(36),
		   RFC_EMI    varchar(13),
		   RFC_REC    varchar(13),
		   IMP_TOTAL  numeric(18,6))

  DECLARE  @uuid          varchar(36),
		   @rfc_emi       varchar(13),
		   @rfc_rec       varchar(13),
		   @imp_total     numeric(18,6),
		   @NumRegistros  int,
		   @RowCount      int,
		   @error         varchar(80)

  DECLARE  @k_verdadero   bit  =  1,
           @k_falso       bit  =  0,
           @k_cancelada      varchar(1)  =  'C',
		   @k_no_concilia    varchar(2)  =  'NC',
		   @k_activa         varchar(1)  =  'A',
		   @k_factura        varchar(4)  =  'FACT',
		   @k_error          varchar(1)  =  'E'

  INSERT   @TCCobrar (UUID) 
  SELECT
  f.UUID		
  FROM CI_CUENTA_X_COBRAR f     
  WHERE f.CVE_EMPRESA         = @pCveEmpresa        AND         
        f.SIT_TRANSACCION     = @k_activa           AND
        f.SIT_CONCILIA_CXC    = @k_no_concilia      AND
		f.SIT_TRANSACCION    <> @k_cancelada
 
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TCCobrar 
  SET @NumRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @uuid = UUID
	FROM   @TCCobrar  WHERE  RowID = @RowCount

	IF EXISTS (SELECT 1 FROM CFDI_COMPROBANTE WHERE CVE_EMPRESA = @pCveEmpresa  AND UUID = @uuid)
	BEGIN
      SELECT  @uuid = c.UUID, @rfc_emi = e.RFC_EMI, @rfc_rec = r.RFC_REC, @imp_total = c.IMP_TOTAL
	  FROM CFDI_COMPROBANTE c, CFDI_RECEPTOR r, CFDI_EMISOR e WHERE
	  c.CVE_EMPRESA  =  @pCveEmpresa  AND
	  c.CVE_TIPO     =  @k_factura    AND
	  c.UUID         =  @uuid         AND
	  c.ANO_MES      =  e.ANO_MES     AND
	  c.CVE_TIPO     =  e.CVE_TIPO    AND
	  c.CVE_EMPRESA  =  e.CVE_EMPRESA AND
	  c.ANO_MES      =  e.ANO_MES     AND
	  c.CVE_TIPO     =  e.CVE_TIPO
	  
	  UPDATE  @TCCobrar  SET    @uuid = UUID, @rfc_emi = RFC_EMI, @rfc_rec = RFC_REC, IMP_TOTAL = @imp_total
	  WHERE   RowID = @RowCount
 	END
	ELSE
	BEGIN
      SET  @pBError  =  @k_verdadero
	  SET @pError  =  LTRIM ('(E) No existe CFDI ' + ISNULL(@UUID,'NULO') )
      SET  @pMsgError =  @pError +  ' '
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
 	END

    SET @RowCount     =  @RowCount + 1
  END
  SELECT * FROM @TCCobrar

END