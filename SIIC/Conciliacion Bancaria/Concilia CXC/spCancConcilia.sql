USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCancConcilia')
BEGIN
  DROP  PROCEDURE spCancConcilia
END
GO

--------------------------------------------------------------------------------------------
-- Actualización de la conciliación de un movimiento bancario contra movimiento(s) de CXC --
-- Opción : ACEPTAR  en la pantalla de conciliación                                       --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spCancConcilia]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int          OUT,
@pIdTarea       numeric(9)   OUT,
@pJson          nvarchar(max),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  select @pJson
  DECLARE @TvpError  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  TIPO_ERROR      varchar(1),
  ERROR           varchar(80),
  MSG_ERROR       varchar (400)
 )

  DECLARE  @cve_empresa        varchar(4),
           @ano_periodo        varchar(6),
           @id_movto_bancario  int,
		   @b_referencia       bit,
		   @referencia         varchar(20),
           @cve_chequera       varchar(6),
		   @folio_exec         int,
		   @hora_inicio        varchar(10) = ' ',
		   @hora_fin           varchar(10) = ' '

  DECLARE  @NunRegistros       int, 
           @RowCount           int,
           @RowCount2          int,
		   @NunRegistros2      int, 
           @id_concilia_cxc    int,
           @ano_mes_proc       varchar(6),
		   @tipo_error         varchar(1)
   
  DECLARE  @k_verdadero        bit  =  1,
           @k_falso            bit  =  0,
  		   @k_abierto          varchar(1)  =  'A',
		   @k_no_conciliado    varchar(2)  =  'NC',
		   @k_error            varchar(1)  =  'E',
		   @k_referencia       varchar(1)  =  'R'

  DECLARE  @TConciliacion  AS TABLE (
  RowID             int IDENTITY(1,1) NOT NULL,
  CVE_EMPRESA       varchar(4),
  ANO_PERIODO       varchar(6),
  ID_MOVTO_BANCARIO int,
  B_REFERENCIA      bit,
  REFERENCIA        varchar(20),
  CVE_CHEQUERA      varchar(6),
  ID_CONCILIA_CXC   int)

------------------------------------------------------------------------------------------
-- Crea instancia del proceso para manejo de errores                                    --
------------------------------------------------------------------------------------------
  EXEC spCreaInstancia
  @pIdCliente,
  @pCveEmpresa,
  @pCodigoUsuario,
  @pCveAplicacion,
  @pAnoPeriodo,
  @pIdProceso,
  @pIdTarea      OUT,
  @pFolioExe     OUT,
  @k_falso,      -- Creara su propio folio de instancia
  @hora_inicio   OUT,
  @hora_fin      OUT,
  @pBError       OUT,
  @pError        OUT,
  @pMsgError     OUT
  
  IF  @pBError  =  @k_verdadero
  BEGIN
    RETURN
  END

 -----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

 INSERT @TConciliacion  (CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, B_REFERENCIA, REFERENCIA, 
                         CVE_CHEQUERA, ID_CONCILIA_CXC)  
  SELECT
  cveEmpresa,
  anoPeriodo,
  idMovtoBancario,
  bReferencia,
  referencia,
  cveChequera,
  idConciliaCxc
  FROM OPENJSON(@pJson)
  WITH (
  cveEmpresa       varchar(4)  '$.cveEmpresa',
  anoPeriodo       varchar(6)  '$.anoPeriodo',
  idMovtoBancario  int         '$.idMovtoBancario',
  bReferencia      bit         '$.bReferencia',
  referencia       varchar(20) '$.referencia',
  cveChequera      varchar(6)  '$.cveChequera',
  idConciliaCxc    int         '$.idConciliaCxc'
  )
  SET @NunRegistros = (SELECT COUNT(*) FROM @TConciliacion)
-----------------------------------------------------------------------------------------------------
  
  SELECT * FROM @TConciliacion
  SET @RowCount     = 1

  BEGIN TRAN

  WHILE @RowCount <= @NunRegistros
  BEGIN
    BEGIN TRY

    SELECT @cve_empresa = CVE_EMPRESA, @ano_periodo = ANO_PERIODO, @id_movto_bancario = ID_MOVTO_BANCARIO, @b_referencia = B_REFERENCIA,
	       @referencia = REFERENCIA, 
           @cve_chequera = CVE_CHEQUERA, @id_concilia_cxc = ID_CONCILIA_CXC
    FROM   @TConciliacion
    WHERE  RowID  =  @RowCount

----------------------------------------------------------------------------------------------
-- Verifica que la cuenta x pagar especificada en los parámetros exista                     --
----------------------------------------------------------------------------------------------
    IF  EXISTS (SELECT 1 FROM  CI_CUENTA_X_COBRAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CONCILIA_CXC = @id_concilia_cxc )
    BEGIN
      SET  @id_concilia_cxc  =  
	      (SELECT ID_CONCILIA_CXC FROM  CI_CUENTA_X_COBRAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CONCILIA_CXC = @id_concilia_cxc)
    END
    ELSE
    BEGIN
      SET  @pBError  =  @k_verdadero
      SET  @pError =  '(E) La factura no existe ' +  ISNULL(CONVERT(VARCHAR(8), @id_concilia_cxc), 'NULO')
      SET  @pMsgError = @pError
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END 

    SET  @ano_mes_proc  =  @ano_periodo

    IF  NOT EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO  WHERE  
        CVE_EMPRESA =  @pCveEmpresa  AND ID_MOVTO_BANCARIO = @id_movto_bancario)  
    BEGIN
      SET  @pBError  =  @k_verdadero
      SET  @pError =  '(E) No Existe el movimiento Bancario ' + ISNULL(CONVERT(VARCHAR(8), @id_movto_bancario), 'NULO')
      SET  @pMsgError = @pError
      INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 

----------------------------------------------------------------------------------------------
-- Verifica que el registro de conciliacion existe                           --
----------------------------------------------------------------------------------------------
    IF  NOT EXISTS (SELECT 1 FROM  CI_CONCILIA_C_X_C  WHERE  CVE_EMPRESA       = @pCveEmpresa        AND  
	                                                         ID_MOVTO_BANCARIO = @id_movto_bancario  AND
															 ID_CONCILIA_CXC   = @id_concilia_cxc)
    BEGIN
      SET  @pBError  =  @k_verdadero
      SET  @pError =  '(E) No Existe la Registro de conciliacion ' + @cve_chequera + ' ' + CONVERT(VARCHAR(10), @id_concilia_cxc)
      SET  @pMsgError = @pError
	  INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 
  
    IF  @pBError  =  @k_falso
    BEGIN

      DELETE FROM  CI_CONCILIA_C_X_C  WHERE  CVE_EMPRESA       = @pCveEmpresa        AND  
	                                         ID_MOVTO_BANCARIO = @id_movto_bancario  AND
											 ID_CONCILIA_CXC   = @id_concilia_cxc

      UPDATE  CI_CUENTA_X_COBRAR  SET  SIT_CONCILIA_CXC =  @k_no_conciliado  WHERE
                                       CVE_EMPRESA = @cve_empresa AND ID_CONCILIA_CXC = @id_concilia_cxc 

      IF  @b_referencia  =   @k_verdadero  
	  BEGIN
	    EXEC spCanConcRef
        @cve_empresa,
        @ano_periodo,
        @referencia,
		@id_concilia_cxc,
        @cve_chequera,
		@pBError   OUT,
        @pError    OUT,
        @pMsgError OUT
      END
	  ELSE
	  BEGIN
        UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_no_conciliado  WHERE
	                                    CVE_EMPRESA  =  @pCveEmpresa  AND
                                        ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  
	  END
    END

	END TRY
 
    BEGIN CATCH
      SET  @pBError    =  @k_verdadero
      SET  @pError    =  '(E) Canvelacion de C x C ' + ';' 
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END CATCH
    
    SET @RowCount     =   @RowCount + 1
  END

  UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_no_conciliado  WHERE
	      CVE_EMPRESA  =  @pCveEmpresa  AND
          ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  


  IF  @@TRANCOUNT >= 1
  BEGIN
    IF  @pBError  =  1
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