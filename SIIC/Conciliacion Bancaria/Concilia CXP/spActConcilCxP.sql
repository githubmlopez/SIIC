USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcilCxP')
BEGIN
  DROP  PROCEDURE spActConcilCxP
END
GO

CREATE PROCEDURE [dbo].[spActConcilCxP]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@TMovBancCxp TMOVBANCXP READONLY,
@pBError          bit,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  SELECT * FROM @TMovBancCxp
  DECLARE @TvpError  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  TIPO_ERROR      varchar (1),
  ERROR           varchar (80),
  MSG_ERROR       varchar (400)
 )

  DECLARE  @TMovBancCxpT TABLE
 (RowID             int IDENTITY(1,1) NOT NULL,
  CVE_EMPRESA       varchar (4) NULL,
  ANO_PERIODO       varchar (6) NULL,
  ID_MOVTO_BANCARIO int NULL,
  B_PAGO            bit NULL,
  ID_PAGO           int NULL,
  CVE_CHEQUERA      varchar (6) NULL,
  ID_CXP            int NULL
 )

  DECLARE @cve_empresa        varchar(4),
          @ano_periodo        varchar(6),
          @id_movto_bancario  int,
		  @b_pago             bit,
		  @id_pago            int,
          @cve_chequera       varchar(6),
          @id_cxp             int

  DECLARE  @NunRegistros      int, 
           @RowCount          int,
           @RowCount2         int,
		   @NunRegistros2     int, 
           @id_concilia_cxp   int,
           @ano_mes_proc      varchar(6),
		   @tipo_error        varchar(1)
   
  DECLARE  @k_verdadero        bit  =  1,
           @k_falso            bit  =  0,
  		   @k_abierto          varchar(1)  =  'A',
		   @k_conciliado       varchar(2)  =  'CC',
		   @k_error            varchar(1)  =  'E'

  INSERT   @TMovBancCxpT  (CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, B_PAGO, ID_PAGO, CVE_CHEQUERA, ID_CXP) 
  SELECT   CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, B_PAGO, ID_PAGO, CVE_CHEQUERA, ID_CXP
           FROM   @TMovBancCxp

  SET @NunRegistros = (SELECT COUNT(*) FROM @TMovBancCxp)
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TMovBancCxp
  SET @RowCount     = 1

  BEGIN TRAN

  WHILE @RowCount <= @NunRegistros
  BEGIN

    BEGIN TRY

    SELECT @cve_empresa = CVE_EMPRESA, @ano_periodo = ANO_PERIODO, @id_movto_bancario = ID_MOVTO_BANCARIO, @b_pago = B_PAGO, 
	       @id_pago = ID_PAGO, @cve_chequera = CVE_CHEQUERA, @id_cxp = ID_CXP
    FROM   @TMovBancCxpT
    WHERE  RowID  =  @RowCount

    	    
    IF  @b_pago = @k_falso
    BEGIN
      IF  EXISTS (SELECT 1 FROM  CI_CUENTA_X_PAGAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CXP = @id_cxp ) 
      BEGIN
        SET  @id_concilia_cxp  =  
	      (SELECT ID_CONCILIA_CXP FROM  CI_CUENTA_X_PAGAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CXP = @id_cxp)
      END
      ELSE
      BEGIN
        SET  @pBError = @k_verdadero
        SET  @pError =  'La CXP a conciliar no existe ' +   CONVERT(VARCHAR(8), @id_cxp)
        INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
      END 
    END
	ELSE
	BEGIN
      IF  NOT EXISTS (SELECT 1 FROM  CI_PAGO  WHERE  CVE_EMPRESA = @cve_empresa AND ID_PAGO = @id_pago) 
      BEGIN
        SET  @pBError = @k_verdadero
        SET  @pError =  'El Pago a conciliar no existe ' +  CONVERT(VARCHAR(8), @id_pago)
        INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
      END 
	END

    SET  @ano_mes_proc  =  (SELECT MAX(ANO_MES) FROM  CI_PERIODO_CONTA  WHERE  CVE_EMPRESA = @cve_empresa  AND SIT_PERIODO = @k_abierto)

    IF  NOT EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO  WHERE  
        ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario)  
    BEGIN
        SET  @pBError = @k_verdadero
      SET  @pError =  'No Existe el movimiento Bancario ' + CONVERT(VARCHAR(8), @id_movto_bancario)
      INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 
  
    IF  NOT EXISTS (SELECT 1 FROM  CI_CHEQUERA  WHERE  CVE_CHEQUERA = @cve_chequera)  
    BEGIN
      SET  @pBError = @k_verdadero
      SET  @pError =  'No Existe la Chequera ' + @cve_chequera
	  INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 
  
    IF  @pBError =  @k_falso
    BEGIN
      IF  @b_pago  =  @k_falso
	  BEGIN
	    select 'no PAGO'
	    INSERT INTO CI_CONCILIA_C_X_P
       (   
        ID_MOVTO_BANCARIO,
        ID_CONCILIA_CXP,
        SIT_CONCILIA_CXP,
        TX_NOTA,
        ANOMES_PROCESO
       )
        VALUES
       ( 
	    @id_movto_bancario,
	    @id_concilia_cxp,
	    @k_conciliado,
	    'PRUEBA',
	    @ano_mes_proc
       )

        UPDATE  CI_CUENTA_X_PAGAR  SET  SIT_CONCILIA_CXP =  @k_conciliado  WHERE
                                   CVE_EMPRESA = @cve_empresa AND ID_CXP = @id_cxp 

	    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
                                   ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  
      END
	  ELSE
	  BEGIN
        select 'PAGO'
        EXEC spActConcPag
             @cve_empresa,
             @ano_periodo,
             @cve_chequera,
             @id_movto_bancario,
			 @id_pago,
             @pError OUT,
             @pMsgError OUT
	  END
    END

    SET @RowCount     =   @RowCount + 1

    END TRY

    BEGIN CATCH
      SET  @pBError    =  @k_verdadero
      SET  @pError    =  '(E) Conciliación de C x P ' + ';' 
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
      INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
    END CATCH
    
	END

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
      SELECT  @tipo_error = @k_error, @pError = ERROR, @pMsgError = MSG_ERROR FROM @TvpError WHERE  RowID = @RowCount2
      EXECUTE spCreaTareaEventoB @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError

      SET @RowCount2 =  @RowCount2  +  1
    END

  SELECT * FROM @TvpError
END