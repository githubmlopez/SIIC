USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcilia')
BEGIN
  DROP  PROCEDURE spActConcilia
END
GO

--------------------------------------------------------------------------------------------
-- Actualización de la conciliación de un movimiento bancario contra movimiento(s) de CXC --
-- Opción : ACEPTAR  en la pantalla de conciliación                                       --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spActConcilia]  
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
           @b_parcial          bit,
		   @id_anticipo        int,
           @cve_chequera       varchar(6),
		   @folio_exec         int,
		   @hora_inicio        varchar(10) = ' ',
		   @hora_fin           varchar(10) = ' ',
		   @log                varchar(max)

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
		   @k_conciliado       varchar(2)  =  'CC',
		   @k_error            varchar(1)  =  'E',
		   @k_referencia       varchar(1)  =  'R',
		   @k_primer_reg       bit  =  1

  DECLARE  @TMovBancFactT  AS TABLE (
  RowID             int IDENTITY(1,1) NOT NULL,
  CVE_EMPRESA       varchar(4),
  ANO_PERIODO       varchar(6),
  ID_MOVTO_BANCARIO int,
  B_REFERENCIA      bit,
  REFERENCIA        varchar(20),
  B_PARCIAL         bit,
  ID_ANTICIPO       int,
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
  @k_falso,      -- Asignara un nuevo folio
  @hora_inicio   OUT,
  @hora_fin      OUT,
  @pBError       OUT,
  @pError        OUT,
  @pMsgError     OUT	

 -----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TMovBancFactT  (CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, B_REFERENCIA, REFERENCIA, B_PARCIAL, ID_ANTICIPO,
                          CVE_CHEQUERA, ID_CONCILIA_CXC)  
  SELECT
  cveEmpresa,
  anoPeriodo,
  idMovtoBancario,
  bReferencia,
  referencia,
  bParcial,
  idAnticipo,
  cveChequera,
  idConciliaCxc
  FROM OPENJSON(@pJson)
  WITH (
  cveEmpresa       varchar(4)  '$.cveEmpresa',
  anoPeriodo       varchar(6)  '$.anoPeriodo',
  idMovtoBancario  int         '$.idMovtoBancario',
  bReferencia      bit         '$.bReferencia',
  referencia       varchar(20) '$.referencia',
  bParcial         bit         '$.bParcial',
  idAnticipo       int         '$.idAnticipo',
  cveChequera      varchar(6)  '$.cveChequera',
  idConciliaCxc    int         '$.idConciliaCxc'
  )

  ------------------  LOG --------------------------------------------

  INSERT INTO FC_LOG (TEXTO) 
  SELECT CVE_EMPRESA + ',' + ANO_PERIODO + ',' + CONVERT(VARCHAR(10),ID_MOVTO_BANCARIO) + ',' + CONVERT(VARCHAR(2),B_REFERENCIA) + ',' + REFERENCIA + ',' +
  CONVERT(VARCHAR(2),B_PARCIAL) + ',' +
  CONVERT(VARCHAR(2),ID_ANTICIPO) + ',' +
  CVE_CHEQUERA + ',' + CONVERT(VARCHAR(10),ID_CONCILIA_CXC)  FROM @TMovBancFactT  
  ------------------
   
  SET @NunRegistros = (SELECT COUNT(*) FROM @TMovBancFactT)
-----------------------------------------------------------------------------------------------------

  SET @RowCount     = 1

  BEGIN TRAN

  WHILE @RowCount <= @NunRegistros
  BEGIN
    BEGIN TRY

    SELECT @cve_empresa = CVE_EMPRESA, @ano_periodo = ANO_PERIODO, @id_movto_bancario = ID_MOVTO_BANCARIO, @b_referencia = B_REFERENCIA,
	       @referencia = REFERENCIA, 
	       @b_parcial = B_PARCIAL, @id_anticipo = ID_ANTICIPO,
           @cve_chequera = CVE_CHEQUERA, @id_concilia_cxc = ID_CONCILIA_CXC
    FROM   @TMovBancFactT
    WHERE  RowID  =  @RowCount
        ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Procesando ' + CONVERT(VARCHAR(10),@id_movto_bancario) + ',' + CONVERT(VARCHAR(10),@id_concilia_cxc))  
        -------------------------------------------------------------------------------------------------------------------
    iF  @RowCount  >  1
	BEGIN
	  SET @k_primer_reg = @k_falso
	END

----------------------------------------------------------------------------------------------
-- Verifica que las banderas de conciliación por referencia y parcial no sean verdaderas,   --
-- solo se puede actualizar por una de ellas                                                --
----------------------------------------------------------------------------------------------
    IF  @b_referencia  =  @k_verdadero  AND  @b_parcial  =  @k_verdadero
    BEGIN
      SET  @pBError  =  @k_verdadero
      SET  @pError =  '(E) Referenciado y Parcial es inválido ' +  ISNULL(CONVERT(VARCHAR(8), @id_concilia_cxc), 'NULO')
      SET  @pMsgError = @pError
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END 

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
	  SET  @pBError     =  @k_verdadero
      SET  @pError      =  '(E) La factura a conciliar no existe ' +  ISNULL(CONVERT(VARCHAR(8), @id_concilia_cxc), 'NULO')
      SET  @pMsgError   = @pError
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END 

    SET  @ano_mes_proc  =  @ano_periodo

    IF  NOT EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO  WHERE CVE_EMPRESA = @cve_empresa AND 
        ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario)  
    BEGIN
      IF  @k_primer_reg =  @k_verdadero
	  BEGIN
 	    SET  @pBError     =  @k_verdadero
        SET  @pError      =  '(E) No Existe el movimiento Bancario ' + ISNULL(CONVERT(VARCHAR(8), @id_movto_bancario), 'NULO')
        SET  @pMsgError   = @pError
        INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
      END
    END 


----------------------------------------------------------------------------------------------
-- Verifica que la chequera especificada en los parámetros exista                           --
----------------------------------------------------------------------------------------------
    IF  NOT EXISTS (SELECT 1 FROM  CI_CHEQUERA  WHERE  CVE_EMPRESA = @cve_empresa AND CVE_CHEQUERA = @cve_chequera)  
    BEGIN
      IF  @k_primer_reg =  @k_verdadero
	  BEGIN
        SET  @pBError  =  @k_verdadero
        SET  @pError =  '(E) No Existe la Chequera ' + @cve_chequera
        SET  @pMsgError = @pError
	    INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
      END
    END 
  
    IF  @pBError  =  @k_falso
    BEGIN
	  	------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Registro Correcto :' + CONVERT(VARCHAR(1),@pBError) )   
        -------------------------------------------------------------------------------------------------------------------
      IF  @b_referencia  =   @k_falso  AND  @b_parcial  =  @k_falso
	  BEGIN
	     ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('No es Referencia :' + CONVERT(VARCHAR(1),@b_referencia) + ',' + CONVERT(VARCHAR(1),@b_parcial))   
        -------------------------------------------------------------------------------------------------------------------
	    INSERT INTO CI_CONCILIA_C_X_C
       (   
        CVE_EMPRESA,
		ID_MOVTO_BANCARIO,
        ID_CONCILIA_CXC,
        SIT_CONCILIA_CXC,
        TX_NOTA,
        ANOMES_PROCESO,
        IMP_PAGO_AJUST
       )
        VALUES
       ( 
	    @pCveEmpresa,
	    @id_movto_bancario,
	    @id_concilia_cxc,
	    @k_conciliado,
	    'PRUEBA',
	    @ano_mes_proc,
  	    0
       )

        UPDATE  CI_CUENTA_X_COBRAR  SET  SIT_CONCILIA_CXC =  @k_conciliado  WHERE
                                         CVE_EMPRESA = @cve_empresa AND ID_CONCILIA_CXC = @id_concilia_cxc 

        ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('UPDATE Bancario No Ref:' + @pCveEmpresa + ' ' + @pAnoPeriodo + ' ' + @cve_chequera + ' ' +  CONVERT(VARCHAR(10),@id_movto_bancario) )   
        -------------------------------------------------------------------------------------------------------------------
	    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
		                           CVE_EMPRESA  =  @pCveEmpresa  AND
                                   ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  
      END
	  ELSE
	  BEGIN
 
        ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Referencia 1 :' + CONVERT(VARCHAR(10),@id_movto_bancario) + ',' + CONVERT(VARCHAR(10),@id_concilia_cxc))   
        -------------------------------------------------------------------------------------------------------------------
        IF  @b_referencia  =  @k_verdadero
		BEGIN
		------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Referencia 2 :' + CONVERT(VARCHAR(10),@id_movto_bancario) + ',' + CONVERT(VARCHAR(10),@id_concilia_cxc))   
        -------------------------------------------------------------------------------------------------------------------
		  EXEC spActConcRef   
          @cve_empresa,
          @ano_periodo,
          @referencia,
          @cve_chequera,
          @id_concilia_cxc,
          @pError OUT,
          @pMsgError OUT

        END

        IF  @b_parcial  =  @k_verdadero
		BEGIN
		  EXEC spActConcParc   
          @cve_empresa,
          @ano_periodo,
          @id_anticipo,
          @cve_chequera,
          @id_concilia_cxc,
          @pError OUT,
          @pMsgError OUT
        END
	  END

    END
    END TRY
 
    BEGIN CATCH
      SET  @pBError    =  @k_verdadero
      SET  @pError    =  '(E) Conciliación de C x C ' + ';' 
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END CATCH
    
-------- ELSE
    SET @RowCount     =   @RowCount + 1
  END

  UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
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
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError

    SET @RowCount2 =  @RowCount2  +  1
  END

  END