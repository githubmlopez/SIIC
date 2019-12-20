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

--EXEC spActConcilia 'CU','MARIO','201903',135,1,'MDB437',' ',' '
CREATE PROCEDURE [dbo].[spActConcilCxP]  
@TMovBanccxp TMOVBANCXP READONLY,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  SELECT * FROM @TMovBanccxp
  DECLARE @TvpError  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  TIPO_ERROR      varchar(1),
  ERROR           varchar(80),
  MSG_ERROR       varchar (400)
 )

  DECLARE @cve_empresa        varchar(4),
          @ano_periodo        varchar(6),
          @id_movto_bancario  int,
		  @cve_tipo           varchar(1),
		  @referencia         varchar(20),
          @cve_chequera       varchar(6),
          @cve_tipo_pago      varchar(1),
          @id_cxp             int,
		  @id_pago            int

  DECLARE  @NunRegistros      int, 
           @RowCount          int,
           @id_concilia_cxc    int,
           @ano_mes_proc       varchar(6),
		   @b_error            bit         =  0
   
  DECLARE  @k_verdadero        bit  =  1,
           @k_falso            bit  =  0,
  		   @k_abierto          varchar(1)  =  'A',
		   @k_conciliado       varchar(2)  =  'CC',
		   @k_error            varchar(1)  =  'E',
		   @k_pago             varchar(1)  =  'P'

  SET @NunRegistros = (SELECT COUNT(*) FROM TMovBanccxp)
-----------------------------------------------------------------------------------------------------
  SELECT * FROM TMovBanccxp
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN

    SELECT @cve_empresa = CVE_EMPRESA, @ano_periodo = ANO_PERIODO, @id_movto_bancario = ID_MOVTO_BANCARIO, @cve_tipo = CVE_TIPO, 
	       @referencia  =  REFERENCIA, @cve_chequera = CVE_CHEQUERA, @cve_tipo_pago = CVE_TIPO_PAGO, @id_cxp = ID_CXP, 
		   @id_pago = ID_PAGO 
    FROM   TMovBanccxp
    WHERE  RowID  =  @RowCount

    	    
    IF  @cve_tipo_pago <> @k_pago
    BEGIN
      IF  EXISTS (SELECT 1 FROM  CI_CUENTA_X_PAGAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CXP = @id_cxp )  AND
      BEGIN
        SET  @id_concilia_cxp  =  
	      (SELECT ID_CONCILIA_CXC FROM  CI_CUENTA_X_PAGAR  WHERE  CVE_EMPRESA = @cve_empresa AND ID_CXP = @id_cxp)
      END
      ELSE
      BEGIN
        SET  @pError =  'La CXP a conciliar no existe ' +  @serie + '/' + CONVERT(VARCHAR(8), @id_cxp)
        SET  @b_error = @k_verdadero
        INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
      END 
    END
	ELSE
	BEGIN
      IF  NOT EXISTS (SELECT 1 FROM  CI_PAGO  WHERE  CVE_EMPRESA = @cve_empresa AND ID_PAGO = @id_pago) 
      BEGIN
        SET  @pError =  'El Pago a conciliar no existe ' +  CONVERT(VARCHAR(8), @id_pago)
        SET  @b_error = @k_verdadero
        INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
      END 
	END

    SET  @ano_mes_proc  =  (SELECT MAX(ANO_MES) FROM  CI_PERIODO_CONTA  WHERE  CVE_EMPRESA = @cve_empresa  AND SIT_PERIODO = @k_abierto)

    IF  NOT EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO  WHERE  
        ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario)  AND
		@cve_tipo <>  @k_referencia
    BEGIN
      SET  @pError =  'No Existe el movimiento Bancario ' + CONVERT(VARCHAR(8), @id_movto_bancario)
      SET  @b_error = @k_verdadero
      INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 
  
    IF  NOT EXISTS (SELECT 1 FROM  CI_CHEQUERA  WHERE  CVE_CHEQUERA = @cve_chequera)  
    BEGIN
      SET  @pError =  'No Existe la Chequera ' + @cve_chequera
      SET  @b_error = @k_verdadero
	  INSERT INTO @TvpError VALUES (@k_error, @pError, ' ')
    END 
  
    IF  @b_error  =  @k_falso
    BEGIN
      BEGIN TRY

      BEGIN TRAN

      IF  @cve_tipo      <>  @k_referencia  AND
	      @cve_tipo_pago <>  @k_pago
	  BEGIN
	    select 'no referencia'
	    INSERT INTO CI_CONCILIA_C_X_C
       (   
        ID_MOVTO_BANCARIO,
        ID_CONCILIA_CXC,
        SIT_CONCILIA_CXC,
        TX_NOTA,
        ANOMES_PROCESO,
        IMP_PAGO_AJUST
       )
        VALUES
       ( 
	    @id_movto_bancario,
	    @id_concilia_cxp,
	    @k_conciliado,
	    'PRUEBA',
	    @ano_mes_proc,
  	    0
       )

        UPDATE  CI_CUENTA_X_PAGAR  SET  SIT_CONCILIA_CXP =  @k_conciliado  WHERE
                                   CVE_EMPRESA = @cve_empresa AND ID_CXC = @id_cxp 

	    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
                                   ANO_MES  =  @ano_periodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  
      END
	  ELSE
	  BEGIN
        EXEC spActConcilCxP
             @cve_empresa,
             @ano_periodo,
             @cve_chequera,
             @referencia,
             @id_concilia_cxp,
             @pError OUT,
             @pMsgError OUT
	  END

      END TRY
 
      BEGIN CATCH
        IF  @@TRANCOUNT > 0
        BEGIN
          ROLLBACK TRAN
        END
 
        SET  @pError    =  'Error al Insertar Conciliacion ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        INSERT INTO @TvpError VALUES (@k_error, @pError, @pMsgError)
      END CATCH

	  IF @@TRANCOUNT > 0  
      COMMIT TRAN
    END
  SET @RowCount     =   @RowCount + 1
  END
  SELECT * FROM @TvpError
END