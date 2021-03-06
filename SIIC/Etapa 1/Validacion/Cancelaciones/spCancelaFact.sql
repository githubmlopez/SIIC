USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCancelaFact')
BEGIN
  DROP  PROCEDURE spCancelaFact
END
GO
--EXEC spCancelaFact 1,'CU','MARIO','SIIC','201906',200,37,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCancelaFact]
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

  DECLARE  @TCxcCan       TABLE
          (RowID          int  identity(1,1),
		   UUID           varchar(36),
		   F_CANCELACION  date)

  DECLARE @TvpError  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  TIPO_ERROR      VARCHAR(1),
  ERROR           VARCHAR(80),
  MSG_ERROR       varchar (400)
 )

  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_cerrado     varchar(1) = 'C',
		  @k_activa      varchar(1) = 'A',
		  @k_cancelada   varchar(1) = 'C',
		  @k_factura     varchar(4) = 'FACT',
		  @k_error       varchar(1) = 'E',
		  @k_warning     varchar(1) = 'W',
		  @k_primer_dia  varchar(2) = '01',
		  @k_meta        varchar(2) = 'MT'

  DECLARE @NunRegistros  int = 0, 
		  @RowCount      int = 0,
          @NunRegistros2 int = 0, 
		  @RowCount2     int = 0,
		  @uuid          varchar(36),
		  @tipo_error    varchar(1),
		  @f_cancelacion date

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado
  BEGIN

  --BEGIN TRAN

  DELETE CI_CANC_PERIODO      
  WHERE  CVE_EMPRESA  = @pCveEmpresa   AND         
         ANO_MES      = @pAnoPeriodo   AND
		 CVE_ORIGEN   = @k_meta        

  INSERT   CI_CANC_PERIODO (CVE_EMPRESA, ANO_MES, UUID, F_CANCELACION, CVE_ORIGEN) 
  SELECT   
  @pCveEmpresa, @pAnoPeriodo, ID_UNICO, F_CANCELACION, @k_meta
  FROM CFDI_META_CXC s     
  WHERE s.CVE_EMPRESA  = @pCveEmpresa           AND         
        ANO_MES        = @pAnoPeriodo           AND
		ESTATUS        = @k_cancelada        

  INSERT INTO @TCxcCan (UUID, F_CANCELACION)
  SELECT UUID, F_CANCELACION FROM CI_CANC_PERIODO WHERE CVE_EMPRESA  = @pCveEmpresa  AND
                                                       ANO_MES      = @pAnoPeriodo   
   
  SET @NunRegistros  =  (SELECT COUNT(*) FROM  @TCxcCan)

  SET  @RowCount = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    BEGIN TRY
    SELECT @uuid  =  UUID, @f_cancelacion = F_CANCELACION FROM  @TCxcCan 
	WHERE  RowID  =  @RowCount

    IF  EXISTS (SELECT 1 FROM CI_CUENTA_X_COBRAR  WHERE CVE_EMPRESA = @pCveEmpresa AND UUID = @uuid)
	BEGIN
	  UPDATE CI_CUENTA_X_COBRAR SET SIT_TRANSACCION = @k_cancelada, 
      F_CANCELACION     = @f_cancelacion
      WHERE CVE_EMPRESA = @pCveEmpresa AND UUID = @uuid
	END
	ELSE
	BEGIN
      SET  @pBError = @k_verdadero
      SET  @pError    =  '(E) No existe Factura ' + 
	  LTRIM(ISNULL(@uuid ,'NULO'))  
	  SET  @pMsgError =  @pError + ';' 
      INSERT INTO @TvpError VALUES (@k_warning, @pError, @pMsgError)
	END

    END TRY

    BEGIN CATCH

    IF  @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRAN
	END

    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Cancelacion de C x C ' + ISNULL(@uuid,'NULO') + ';' 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
    INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)

    END CATCH

    SET  @RowCount = @RowCount + 1
  END 

  IF  @@TRANCOUNT > 0
  BEGIN
    IF  @pBError  =  @k_verdadero
	BEGIN
	  ROLLBACK TRAN
	END
	ELSE
	BEGIN
      COMMIT TRAN
	END
  END

  SET @NunRegistros2 = (SELECT COUNT(*)  FROM @TvpError)
  
  IF  @NunRegistros2 >  0
  BEGIN
	SET  @pBError  =  @k_verdadero
  END

  SET @RowCount2 =  1

  WHILE @RowCount2 <= @NunRegistros2
  BEGIN
    SELECT  @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR FROM @TvpError WHERE  RowID = @RowCount2
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET @RowCount2 =  @RowCount2  +  1
  END

  END
  ELSE
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Periodo cerrado ' + ISNULL(CONVERT(VARCHAR(6), @uuid),'NULO')  
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

