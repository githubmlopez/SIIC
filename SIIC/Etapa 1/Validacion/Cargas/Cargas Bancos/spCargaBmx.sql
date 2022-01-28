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

--EXEC spCargaBmx 1,'EGG','MARIO','SIIC','202011',18,1,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCargaBmx]
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
  DECLARE @pTipoInfo     int,
          @pIdBloque     int,
		  @pIdFormato    int

  DECLARE @f_operacion        date,
          @cve_cargo_abono    varchar (1),
          @imp_transaccion    numeric (16,2),
          @cve_tipo_movto     varchar (6),
          @descripcion        varchar(250), 
	      @referencia         varchar(20),
		  @ref_emp            varchar(14),
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
		  @cheq_param    varchar(6),
		  @sdo_final     numeric(16,2)

  DECLARE @k_verdadero   bit         = 1,
          @k_falso       bit         = 0,
		  @k_error       varchar(1)  = 'E',
		  @k_cerrado     varchar(1)  = 'C',
		  @k_no_conc     varchar(2)  = 'NC',
		  @k_activa      varchar(1)  = 'A',
		  @k_cargo       varchar(1)  = 'C',
		  @k_abono       varchar(1)  = 'A',
		  @k_inicio      varchar(1)  = 'I',
 		  @k_fin         varchar(1)  = 'F',
		  @k_mov_banc    varchar(4)  = 'MOVB',
		  @k_sec_sdo_ini int         = 1,
		  @k_referencia  varchar(13) = 'Autorización:',
		  @k_ref_emp     varchar(4)  = 'Ref/',
		  @k_f_ddmmyyyy  int         = 103,
		  @k_default     varchar(1)  = 'D'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado   
  BEGIN
 
    DECLARE @TvpBanamex TABLE
   (
    NUM_REGISTRO       int identity(1,1),
    CVE_CHEQUERA       varchar (6)    NOT NULL
   )

	SELECT @cheq_param  = SUBSTRING(PARAMETRO,1,6)
    FROM   FC_PROCESO 
	WHERE  CVE_EMPRESA =  @pCveEmpresa  AND ID_PROCESO = @pIdProceso


 --   EXEC  spParamCarga
 --   @pAnoPeriodo, @pCveEmpresa, @pIdProceso, 
	--@pTipoInfo OUT, @pIdBloque OUT, @pIdFormato OUT, @cve_chequera OUT, @k_verdadero
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT INTO @TvpBanamex 
   (
    CVE_CHEQUERA
   )
    SELECT  CVE_CHEQUERA
    FROM CI_CHEQUERA ch WHERE
    CVE_CHEQUERA  =  @cheq_param

    SET @NunRegistros = @@ROWCOUNT
--	SELECT * FROM @TvpBanamex
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1
    WHILE @RowCount <= @NunRegistros
    BEGIN
      BEGIN TRY
	  SELECT @cve_chequera = CVE_CHEQUERA  FROM @TvpBanamex  WHERE NUM_REGISTRO = @RowCount

      DELETE CI_BMX_ACUM_REF  WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND ANO_MES = @cve_chequera

--	  SELECT 'PROCESANDO CHEQUERA ' + @cve_chequera

	  SELECT @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,1,6)),
	         @pIdBloque  = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,7,6)),
			 @pIdFormato = CONVERT(INT,SUBSTRING(PARAM_INFORMACION,13,6))
	  FROM   CI_CHEQUERA 
	  WHERE  CVE_CHEQUERA =  @cve_chequera

	  SET  @pos_ini  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@pCveEmpresa, @cve_chequera + @k_inicio),0)))
	  SET  @pos_fin  =  CONVERT(INT,(ISNULL(dbo.fnObtParNumero(@pCveEmpresa, @cve_chequera + @k_fin),0)))

	  UPDATE CI_CHEQUERA_PERIODO  SET  SDO_FIN_MES = 0 WHERE
	  CVE_EMPRESA =  @pCveEmpresa  AND  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

	  SELECT @NunRegistros1 = MAX(NUM_REGISTRO) FROM FC_CARGA_COL_DATO WHERE
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

        SET @descripcion =  
        dbo.fnObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 2, 1, 250)  

		IF  NOT EXISTS (SELECT 1 FROM CI_MOVTO_BANCARIO WHERE ANO_MES = @pAnoPeriodo  AND DESCRIPCION = @descripcion)
		BEGIN --1
        SET @f_operacion  =
        dbo.fnObtValDate (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 1, 1, 12, @k_f_ddmmyyyy) 

        SET @val_dato_c =  
        dbo.fnObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 3, 1, 250)  

		IF  @val_dato_c <> ' ' 
		BEGIN
		  SET  @val_dato_n = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) 
          SET  @cve_cargo_abono    =  @k_abono
		END
		ELSE
		BEGIN
          SET @val_dato_c =  
          dbo.fnObtColumna (@pIdCliente, @pCveEmpresa, @pTipoInfo, @pIdBloque, @pIdFormato, @pAnoPeriodo, @RowCount1, 4, 1, 250)  
          SET  @val_dato_n = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) -- * -1
          SET  @cve_cargo_abono    =  @k_cargo
        END

        SET  @imp_transaccion    =  @val_dato_n

 -- Obtiene Clave de Operacion
        		
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
 --       SELECT 'CLAVE ' + @cve_operacion
        SET  @cve_tipo_movto     =  @cve_operacion
 
 -- Obtiene Referencia solo para el caso de BANAMEX
        IF  ISNULL(CHARINDEX(@k_referencia,@descripcion),0) > 0
		BEGIN
          SET @referencia = SUBSTRING(dbo.fnobtExtCadena (@descripcion, @k_referencia, 1, 8),1,8)
		  SET @referencia = ISNULL(@referencia, ' ')
		END
		ELSE
		BEGIN
		  SET  @referencia  =  ' '
		END 
 -- Obtiene Referencia solicitada por la empresa

       IF  ISNULL(CHARINDEX(@k_ref_emp,@descripcion),0) > 0
	   BEGIN
		 SET @ref_emp = SUBSTRING(dbo.fnobtExtCadena (@descripcion, @k_ref_emp, 1,9),1,9)
		 SET @ref_emp = ISNULL(@ref_emp, ' ')
       END
	   ELSE
	   BEGIN
		 SET  @ref_emp  =  ' ' 
	   END 

	   IF EXISTS (SELECT 1 FROM CI_TIPO_MOVTO_BANCO WHERE CVE_EMPRESA = @pCveEmpresa AND CVE_TIPO_MOVTO = @cve_tipo_movto)
	   BEGIN

          SET @folio = (select  NUM_FOLIO + 1 FROM  CI_FOLIO  WHERE CVE_FOLIO  =  @k_mov_banc)
	      UPDATE CI_FOLIO SET NUM_FOLIO = @folio  WHERE CVE_FOLIO  =  @k_mov_banc

          INSERT INTO CI_MOVTO_BANCARIO 
         (
          ID_MOVTO_BANCARIO,
          CVE_EMPRESA,
          ANO_MES,
          F_OPERACION,
          CVE_CHEQUERA,
          CVE_CARGO_ABONO,
          IMP_TRANSACCION,
          CVE_TIPO_MOVTO,
          DESCRIPCION,
          SIT_CONCILIA_BANCO,
          SIT_MOVTO,
		  B_OPER_DEFAULT,
		  REFERENCIA,
		  REF_EMP,
		  B_REFERENCIA
         )  VALUES
	     (
	      @folio,
          @pCveEmpresa,
	      @pAnoPeriodo,
          @f_operacion,
          @cve_chequera,
		  @cve_cargo_abono,
		  @imp_transaccion,
		  @cve_operacion,
		  @descripcion,
		  @k_no_conc,
          @k_activa,
		  @b_default,
		  @referencia,
		  @ref_emp,
		  @k_falso
	     )  
 		END
		ELSE
		BEGIN
          SET  @pBError    =  @k_verdadero
          SET  @pError    =  '(E) No Existe Operacion '  +  ISNULL(SUBSTRING(@descripcion,1,50),'NULO') 
          SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
          SET @RowCount1  =  @NunRegistros1 
		END 

        END  --1

        SELECT @RowCount1  =  @RowCount1  +  1 

	  END
      END TRY 

	  BEGIN CATCH
        SET  @pBError    =  @k_verdadero
        SET  @pError    =  '(E) Carga Banamex (1) '  +  ISNULL(@cve_chequera,'NULO') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
      END CATCH

      BEGIN TRY

      IF  @pBError    =  @k_falso
	  BEGIN
	  INSERT  CI_BMX_ACUM_REF
     (
	  CVE_EMPRESA,
	  ANO_MES,
	  CVE_CHEQUERA,
	  REFERENCIA,
	  IMP_TRANSACCION
	 )
      SELECT 
	  @pCveEmpresa,
	  @pAnoPeriodo,
	  CVE_CHEQUERA,
	  REFERENCIA,
	  SUM(IMP_TRANSACCION)
      FROM  CI_MOVTO_BANCARIO  WHERE  ANO_MES  =  @pAnoPeriodo  AND CVE_CHEQUERA = @cve_chequera
	  GROUP BY CVE_CHEQUERA, REFERENCIA
	  HAVING COUNT(*) > 1  AND ISNULL (REFERENCIA,' ') <> ' '

      UPDATE CI_MOVTO_BANCARIO  SET IMP_TRANSACCION =  ABS(IMP_TRANSACCION) WHERE
	  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

	  UPDATE m1 SET B_REFERENCIA =  @k_verdadero FROM CI_MOVTO_BANCARIO m1  WHERE
	  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera AND ISNULL(REFERENCIA, ' ') <> ' '  AND
	  (SELECT COUNT(*) FROM CI_MOVTO_BANCARIO m2  WHERE
	   ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera AND m1.REFERENCIA = m2.REFERENCIA) > 1
	 
      UPDATE CI_BMX_ACUM_REF   SET IMP_TRANSACCION =  ABS(IMP_TRANSACCION) WHERE
	  CVE_EMPRESA = @pCveEmpresa  AND  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera
 
      DELETE  CI_MOVTO_BANCARIO WHERE ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera  AND IMP_TRANSACCION = 0 
	   
--      SELECT * from CI_MOVTO_BANCARIO  WHERE  ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera

      END
      END TRY
 
      BEGIN CATCH
        SET  @pBError    =  @k_verdadero
        SET  @pError    =  '(E) Carga Banamex (2) '  +  ISNULL(@cve_chequera,'NULO')  
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        SELECT @pMsgError
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  END CATCH

      IF  @pBError    =  @k_falso
	  BEGIN
 	    SET  @val_dato_c =  dbo.fnObtColInd (@pIdCliente, @pCveEmpresa,  @pTipoInfo, @pIdFormato, @pAnoPeriodo, 1)   
        SET  @sdo_final = CONVERT(numeric(16,2),REPLACE((RTRIM(SUBSTRING(@val_dato_c,1,18))),' ',0)) 
        IF   @sdo_final  IS NULL 
	    BEGIN
          SET  @pBError    =  @k_verdadero
          SET  @pError    =  '(E) No existe saldo final '  +  ISNULL(@cve_chequera,'NULO')  
          SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
          SELECT @pMsgError
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
		  SET @RowCount  =  @NunRegistros 
	    END
	    ELSE
	    BEGIN
          UPDATE  CI_CHEQUERA_PERIODO  SET SDO_FIN_MES = @sdo_final WHERE
	      ANO_MES       =  @pAnoPeriodo  AND
	      CVE_CHEQUERA  =  @cve_chequera
	    END
	  END
      SELECT @RowCount  =  @RowCount  +  1 

    END
--    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros
  END
  ELSE
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Periodo esta cerrado  ' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

