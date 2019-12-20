USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaBmx')
BEGIN
  DROP  PROCEDURE spCargaBmx
END
GO

--EXEC spCargaBmx 'CU','MARIO','201906',135,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaBmx]
(
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE @pIdCliente    int,
          @pIdFormato    int,
		  @pTipoInfo     int,
          @pIdBloque     int

  DECLARE @f_operacion        date,
          @cve_cargo_abono    varchar (1),
          @imp_transaccion    numeric (16,2),
          @cve_tipo_movto     varchar (6),
          @descripcion        varchar(250), 
	      @referencia         varchar(20),
          @sit_concilia_banco varchar(2),
          @sit_movto          varchar(2),
		  @b_default          bit

  DECLARE @NunRegistros  int = 0, 
		  @RowCount      int = 0,
          @NunRegistros1 int = 0, 
		  @RowCount1     int = 0,
          @val_dato_c    varchar(250),
		  @val_dato_n    numeric(16,2),
		  @folio         int,
		  @cve_operacion varchar(6),
		  @valor	     varchar(100),
		  @pos_ini       int,
		  @pos_fin       int,
		  @cve_chequera  varchar(6),
		  @sdo_final     numeric(16,2)

  DECLARE @k_verdadero   bit        = 1,
          @k_falso       bit        = 0,
		  @k_error       varchar(1) = 'E',
		  @k_cerrado     varchar(1) = 'C',
		  @k_no_conc     varchar(2) = 'NC',
		  @k_activa      varchar(1) = 'A',
		  @k_cargo       varchar(1) = 'C',
		  @k_abono       varchar(1) = 'A',
		  @k_inicio      varchar(1) = 'I',
 		  @k_fin         varchar(1) = 'F',
		  @k_pos_ini     varchar(10) = 'POSINI',
		  @k_pos_fin     varchar(10) = 'POSFIN',
		  @k_mov_banc    varchar(4)  = 'MOVB',
		  @k_sec_sdo_ini int         = 1,
		  @k_referencia  varchar(13) = 'Autorización:',
		  @k_f_ddmmyyyy  int         = 103,
		  @k_default     varchar(1)  = 'D'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado OR
	  (SELECT COUNT(*) FROM CI_MOVTO_BANCARIO m, CI_CONCILIA_C_X_C c
	   WHERE m.ANO_MES = @pAnoPeriodo  AND m.ID_MOVTO_BANCARIO = c.ID_MOVTO_BANCARIO) > 1 OR
	  (SELECT COUNT(*) FROM CI_MOVTO_BANCARIO m, CI_CONCILIA_C_X_P c
	   WHERE m.ANO_MES = @pAnoPeriodo  AND m.ID_MOVTO_BANCARIO = c.ID_MOVTO_BANCARIO) > 1 
  BEGIN

    DELETE CI_BMX_ACUM_REF  WHERE ANO_MES = @pAnoPeriodo 
 
    DECLARE @TvpBanamex TABLE
   (
    NUM_REGISTRO       int identity(1,1),
    CVE_CHEQUERA       varchar (6)    NOT NULL
   )

    EXEC  spParamCarga
    @pAnoPeriodo, @pCveEmpresa, @pIdProceso, @pIdCliente OUT, 
	@pTipoInfo OUT, @pIdBloque OUT, @pIdFormato OUT, @cve_chequera OUT

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

    INSERT INTO @TvpBanamex 
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
	  SELECT @cve_chequera = CVE_CHEQUERA  FROM @TvpBanamex  WHERE NUM_REGISTRO = @RowCount

      DELETE FROM CI_MOVTO_BANCARIO WHERE ANO_MES = @pAnoPeriodo AND CVE_CHEQUERA = @cve_chequera

	  SELECT @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6)),
	         @pIdBloque  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,7,6)),
			 @pIdFormato = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,13,6))
	  FROM CI_CHEQUERA 
	  WHERE  CVE_CHEQUERA =  @cve_chequera

	  SET  @pos_ini  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@cve_chequera + @k_inicio),0)))
	  SET  @pos_fin  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@cve_chequera + @k_fin),0)))

	  UPDATE CI_CHEQUERA_PERIODO  SET  SDO_FIN_MES = 0 WHERE ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

	  SELECT @NunRegistros1 = MAX(NUM_REGISTRO) FROM CARGADOR.dbo.FC_CARGA_COL_DATO WHERE
      ID_CLIENTE       = @pIdCliente  AND
      CVE_EMPRESA      = @pCveEmpresa AND
      TIPO_INFORMACION = @pTipoInfo   AND
      ID_BLOQUE        = @pIdBloque   AND
      ID_FORMATO       = @pIdFormato  AND
      PERIODO          = @pAnoPeriodo

      SET @NunRegistros1  = ISNULL(@NunRegistros1,' ')
--	  SELECT @cve_chequera + ' ' + convert(varchar(6), @NunRegistros1)
      SELECT @RowCount1  =  1

	  WHILE  @RowCount1  <=  @NunRegistros1 
      BEGIN
        SET @f_operacion  =
        dbo.fnobtObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 1, 1, 12, @k_f_ddmmyyyy) 

        SET @descripcion =  
        dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 2, 1, 250)  

        SET @val_dato_c =  
        dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 3, 1, 250)  

		IF  @val_dato_c <> ' ' 
		BEGIN
		  SET  @val_dato_n = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) 
          SET  @cve_cargo_abono    =  @k_abono
		END
		ELSE
		BEGIN
          SET @val_dato_c =  
          dbo.fnobtObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 4, 1, 250)  
          SET  @val_dato_n = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) * -1
          SET  @cve_cargo_abono    =  @k_cargo
        END

        SET  @imp_transaccion    =  @val_dato_n
        SET  @cve_operacion  = 
	    SUBSTRING(dbo.fnObtOperBanc(@pTipoInfo, @pos_ini,@pos_fin,@cve_cargo_abono, @descripcion),2,6)
		IF  SUBSTRING(dbo.fnObtOperBanc(@pTipoInfo, @pos_ini,@pos_fin,@cve_cargo_abono, @descripcion),1,1) = @k_default
		BEGIN
		  SET @b_default  =  @k_verdadero
		END
		ELSE
		BEGIN
          SET @b_default  =  @k_falso
		END
 
        SET  @cve_tipo_movto     =  @cve_operacion
  
		IF NOT EXISTS (SELECT 1 FROM CI_TIPO_MOVIMIENTO WHERE CVE_TIPO_MOVTO = @cve_tipo_movto)
		BEGIN
          SET  @pError    =  'N.E. Oper '  +  ISNULL(SUBSTRING(@descripcion,1,50),'NULO') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ')
          SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--          SELECT @pMsgError
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
          SET @RowCount1  =  @NunRegistros1 
 		END

 -- Obtiene Referencia solo para el caso de BANAMEX
        SET @referencia =  SUBSTRING(dbo.fnobExtCadena (@descripcion, @k_referencia, 1, 8),1,8)

		SET @referencia = ISNULL(@referencia, ' ')

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
        @f_operacion,
		@cve_cargo_abono,
		@imp_transaccion,
		@cve_operacion,
		@descripcion,
		@referencia,
		@k_no_conc,
        @k_activa,
		@b_default
	   )  
		SELECT @RowCount1  =  @RowCount1  +  1 
      END

      END TRY 

	  BEGIN CATCH
        SET  @pError    =  'Error carga Banamex (1) '  +  ISNULL(@cve_chequera,'NULO') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
        SELECT @pMsgError
--        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
      END CATCH

      BEGIN TRY

	  INSERT  CI_BMX_ACUM_REF
     (
	  ANO_MES,
	  CVE_CHEQUERA,
	  REFERENCIA,
	  IMP_TRANSACCION
	 )
      SELECT 
	  @pAnoPeriodo,
	  CVE_CHEQUERA,
	  REFERENCIA,
	  SUM(IMP_TRANSACCION)
      FROM  CI_MOVTO_BANCARIO  WHERE  ANO_MES  =  @pAnoPeriodo  AND CVE_CHEQUERA = @cve_chequera
	  GROUP BY CVE_CHEQUERA, REFERENCIA
	  HAVING COUNT(*) > 1  AND ISNULL (REFERENCIA,' ') <> ' '

      UPDATE CI_MOVTO_BANCARIO  SET IMP_TRANSACCION =  ABS(IMP_TRANSACCION) WHERE
	  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

      UPDATE CI_BMX_ACUM_REF   SET IMP_TRANSACCION =  ABS(IMP_TRANSACCION) WHERE
	  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera
 
      DELETE  CI_MOVTO_BANCARIO WHERE ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera  AND IMP_TRANSACCION = 0 
	   
--      SELECT * from CI_MOVTO_BANCARIO  WHERE  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

      END TRY
 
      BEGIN CATCH
        SET  @pError    =  'Error carga Banamex (2) '  +  ISNULL(@cve_chequera,'NULO') + ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--        SELECT @pMsgError
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	  END CATCH

 	  SET  @val_dato_c =  dbo.fnobtObtColInd (@pIdCliente, @pCveEmpresa,  @pTipoInfo, @pIdFormato, 1, @pAnoPeriodo, 1)   

      SET  @sdo_final = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) 

      UPDATE  CI_CHEQUERA_PERIODO  SET SDO_FIN_MES = @sdo_final WHERE
	  ANO_MES       =  @pAnoPeriodo  AND
	  CVE_CHEQUERA  =  @cve_chequera

      SELECT @RowCount  =  @RowCount  +  1 

    END
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros
  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado o conciliados ' + ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

