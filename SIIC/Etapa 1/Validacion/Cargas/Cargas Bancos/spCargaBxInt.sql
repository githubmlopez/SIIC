USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaBxInt')
BEGIN
  DROP  PROCEDURE spCargaBxInt
END
GO

--EXEC spCargaBxInt 1,'CU','MARIO','SIIC','201906',210,1,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCargaBxInt]
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

  DECLARE @cve_chequera       varchar(6),
          @f_operacion        date,
          @cve_cargo_abono    varchar (1),
          @imp_transaccion    numeric (16,2),
          @cve_tipo_movto     varchar (6),
          @descripcion        varchar(250), 
	      @referencia         varchar(20),
          @sit_concilia_banco varchar(2),
          @sit_movto          varchar(2),
 		  @b_default          bit


  DECLARE @pTipoInfo     int,
          @pIdBloque     int,
		  @pIdFormato    int

  DECLARE @NunRegistros  int = 0, 
		  @RowCount      int = 0,
          @NunRegistros1 int = 0, 
		  @RowCount1     int = 0,
          @val_dato_c    varchar(250),
		  @val_dato_n    numeric(16,2),
		  @folio         int,
		  @cve_operacion varchar(7),
		  @valor	     varchar(100),
		  @pos_ini       int,
		  @pos_fin       int,
		  @sdo_final     numeric(18,2)

  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_error       varchar(1) = 'E',
		  @k_cerrado     varchar(1) = 'C',
		  @k_no_conc     varchar(2) = 'NC',
		  @k_activa      varchar(1) = 'A',
		  @k_cargo       varchar(1) = 'C',
		  @k_abono       varchar(1) = 'A',
		  @k_mov_banc    varchar(4) = 'MOVB',
		  @k_inicio      varchar(1) = 'I',
 		  @k_fin         varchar(1) = 'F',
		  @k_f_ddmmyyyy  int         = 103,
		  @k_default     varchar(1)  = 'D',
		  @k_impto_cargo varchar(6)  = 'RET',
		  @k_impto_abono varchar(6)  = 'IBF'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado 
  BEGIN

    DECLARE @TvpBmxInt TABLE
   (
    NUM_REGISTRO       int identity(1,1),
    CVE_CHEQUERA       varchar (6)    NOT NULL
   )

    EXEC  spParamCarga
    @pAnoPeriodo, @pCveEmpresa, @pIdProceso, 
	@pTipoInfo OUT, @pIdBloque OUT, @pIdFormato OUT, @cve_chequera OUT, @k_verdadero

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

    INSERT INTO @TvpBmxInt 
   (
    CVE_CHEQUERA
   )
    SELECT  CVE_CHEQUERA
    FROM CI_CHEQUERA ch WHERE
    CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6))  = @pTipoInfo
    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      BEGIN TRY
	  SELECT @cve_chequera = CVE_CHEQUERA  FROM @TvpBmxInt  WHERE NUM_REGISTRO = @RowCount

	  SELECT @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6)),
	         @pIdBloque  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,7,6)),
			 @pIdFormato = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,13,6))
	  FROM   CI_CHEQUERA 
	  WHERE  CVE_CHEQUERA =  @cve_chequera

-- En esta sección se crean los movimientos correspondientes a los impuestos retenidos que no vienen en los estados de cuenta
	  IF  @RowCount = 1
	  BEGIN
  		SET @folio = (select  NUM_FOLIO + 1 FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_mov_banc)
	    UPDATE CI_FOLIO SET NUM_FOLIO = @folio  WHERE CVE_FOLIO  =  @k_mov_banc

        INSERT INTO CI_MOVTO_BANCARIO 
       (
        ANO_MES,
        CVE_CHEQUERA,
        ID_MOVTO_BANCARIO,
        F_OPERACION,
        CVE_CARGO_ABONO,
        IMP_TRANSACCION,
        CVE_TIPO_MOVTO,
        DESCRIPCION,
		REFERENCIA,
        SIT_CONCILIA_BANCO,
        SIT_MOVTO,
		B_OPER_DEFAULT
       )  VALUES
	   (
	    @pAnoPeriodo,
        @cve_chequera,
	    @folio,
        (SELECT F_FINAL FROM CI_PERIODO_CONTA WHERE ANO_MES = @pAnoPeriodo),
		@k_cargo,
        dbo.fnObtParNumero(@cve_chequera + @k_cargo),
        @k_impto_cargo,
		'(C) Impuesto Retenido',
		0,
		@k_no_conc,
        @k_activa,
		0
	   )  

  		SET @folio = (select  NUM_FOLIO + 1 FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_mov_banc)
	    UPDATE CI_FOLIO SET NUM_FOLIO = @folio  WHERE CVE_FOLIO  =  @k_mov_banc

        INSERT INTO CI_MOVTO_BANCARIO 
       (
        ANO_MES,
        CVE_CHEQUERA,
        ID_MOVTO_BANCARIO,
        F_OPERACION,
        CVE_CARGO_ABONO,
        IMP_TRANSACCION,
        CVE_TIPO_MOVTO,
        DESCRIPCION,
		REFERENCIA,
        SIT_CONCILIA_BANCO,
        SIT_MOVTO,
		B_OPER_DEFAULT
       )  VALUES
	   (
	    @pAnoPeriodo,
        @cve_chequera,
	    @folio,
        (SELECT F_FINAL FROM CI_PERIODO_CONTA WHERE ANO_MES = @pAnoPeriodo),
		@k_cargo,
        dbo.fnObtParNumero(@cve_chequera + @k_abono),
        @k_impto_abono,
		'(A) Impuesto Retenido',
		0,
		@k_no_conc,
        @k_activa,
		0
	   )  
      END
--------------------------------------------------------------------------------------------------------------------------

	  SET  @pos_ini  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@cve_chequera + @k_inicio),0)))
	  SET  @pos_fin  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@cve_chequera + @k_fin),0)))

	  UPDATE CI_CHEQUERA_PERIODO  SET  SDO_FIN_MES = 0 WHERE ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

	  SELECT @NunRegistros1 = MAX(NUM_REGISTRO) FROM FC_CARGA_COL_DATO WHERE
      ID_CLIENTE       = @pIdCliente  AND
      CVE_EMPRESA      = @pCveEmpresa AND
      TIPO_INFORMACION = @pTipoInfo   AND
      ID_BLOQUE        = @pIdBloque   AND
      ID_FORMATO       = @pIdFormato  AND
      PERIODO          = @pAnoPeriodo

      SET @NunRegistros1  = ISNULL(@NunRegistros1,' ')
--	  SELECT @cve_chequera + ' ' + convert(varchar(6), @NunRegistros1) + '*'
      SELECT @RowCount1  =  1
	  
	  WHILE  @RowCount1  <=  @NunRegistros1 
      BEGIN

        SET @val_dato_c =  
        dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 1, 1, 12)

        SET @f_operacion  = SUBSTRING(@pAnoPeriodo,1,4) + '/' + SUBSTRING(@pAnoPeriodo,5,6) + '/' + SUBSTRING(@val_dato_c,1,2) 

	    SET @descripcion =  
        dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 2, 1, 250) 

	    SET @val_dato_n =  dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 3, 1, 50) 

		SET @imp_transaccion  =  0
		SET @cve_operacion    =  ' '

	    IF  @val_dato_n  <>  0
	    BEGIN
          SET  @imp_transaccion    =  @val_dato_n
          SET  @cve_cargo_abono    =  @k_cargo
          SET  @cve_operacion  = 
          SUBSTRING(dbo.fnObtOperBanc(@pTipoInfo, @pos_ini,@pos_fin,@cve_cargo_abono, @descripcion),2,6)
        END

    	SET @val_dato_n =  dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 4, 1, 50) 

	    IF  @val_dato_n  <>  0
	    BEGIN
          SET  @imp_transaccion    =  @val_dato_n
          SET  @cve_cargo_abono    =  @k_abono
          SET  @cve_operacion  = 
          SUBSTRING(dbo.fnObtOperBanc(@pTipoInfo, @pos_ini,@pos_fin,@cve_cargo_abono, @descripcion),2,6)
	    END

     	IF  SUBSTRING(dbo.fnObtOperBanc(@pTipoInfo, @pos_ini,@pos_fin,@cve_cargo_abono, @descripcion),1,1) = @k_default
	    BEGIN
 		  SET @b_default  =  @k_verdadero
	    END
	    ELSE
	    BEGIN
 		  SET @b_default  =  @k_falso
	    END
 
        SET  @cve_tipo_movto     =  @cve_operacion

		IF NOT EXISTS (SELECT 1 FROM CI_TIPO_MOVIMIENTO WHERE CVE_TIPO_MOVTO = @cve_tipo_movto) AND
		@imp_transaccion <>  0
		BEGIN
          SET  @pError    =  'N.E. Oper '  +  ISNULL(SUBSTRING(@descripcion,1,50),'NULO') + ' ' + @cve_tipo_movto 
	      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--          SELECT @pMsgError
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
          SET @RowCount1  =  @NunRegistros1 
 		END

    	SET @referencia = 0

		SET @folio = (select  NUM_FOLIO + 1 FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_mov_banc)
	    UPDATE CI_FOLIO SET NUM_FOLIO = @folio  WHERE CVE_FOLIO  =  @k_mov_banc


		IF  @imp_transaccion  <> 0
		BEGIN 
        INSERT INTO CI_MOVTO_BANCARIO 
       (
        ANO_MES,
        CVE_CHEQUERA,
        ID_MOVTO_BANCARIO,
        F_OPERACION,
        CVE_CARGO_ABONO,
        IMP_TRANSACCION,
        CVE_TIPO_MOVTO,
        DESCRIPCION,
		REFERENCIA,
        SIT_CONCILIA_BANCO,
        SIT_MOVTO,
		B_OPER_DEFAULT,
		REF_EMP,
		B_REFERENCIA
       )  VALUES
	   (
	    @pAnoPeriodo,
        @cve_chequera,
	    @folio,
        @f_operacion,
		@cve_cargo_abono,
		@imp_transaccion,
		@cve_operacion,
		@descripcion,
		@referencia,
		@k_no_conc,
        @k_activa,
		@b_default,
		' ',
		0
	   )  
        END
		SELECT @RowCount1  =  @RowCount1  +  1 
      END

      END TRY 

	  BEGIN CATCH
        SET  @pError    =  '(E) Carga Banamex '  +  ISNULL(@cve_chequera,'NULO') 
	    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--       SELECT @pMsgError
        EXECUTE spCreaTareaEventoB @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
      END CATCH

      SET @sdo_final = 
	  dbo.fnobtObtValNum (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @NunRegistros1, 5, 1, 50) 

      UPDATE  CI_CHEQUERA_PERIODO  SET SDO_FIN_MES = @sdo_final WHERE
	  ANO_MES       =  @pAnoPeriodo  AND
	  CVE_CHEQUERA  =  @cve_chequera

      SELECT @RowCount  =  @RowCount  +  1 
    END
  
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros
  END
  ELSE
  BEGIN
    SET  @pError    =  '(E) Periodo esta cerrado  ' 
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
--    SELECT @pMsgError
    EXECUTE spCreaTareaEventoB @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

