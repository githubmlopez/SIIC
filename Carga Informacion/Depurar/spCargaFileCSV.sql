USE CARGAINF
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCargaFile')
BEGIN
  DROP  PROCEDURE spCargaFile
END
GO
-- exec spCargaFile 'CU', 'MARIO', '201805', 1, 144, ' ', ' '
CREATE PROCEDURE [dbo].[spCargaFile] 
(
@pIdProceso     numeric(9),
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pIdFormato     int,
@pPeriodo       varchar(8), 
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN

  CREATE TABLE #FILEP 
  (Rowfile     varchar(500))

  CREATE TABLE #FILE 
  (id_renglon  int identity,
   Rowfile     varchar(500))

  CREATE TABLE #PARAMETRO
  (paths          varchar(50),
   inicio         int,
   fin            int,
   num_campos     int,
   type_campos    varchar(6)) 

  DECLARE @paths        varchar(50),
          @inicio       int,
          @fin          int,
          @num_campos   int,
          @type_campos  varchar(6) 

  DECLARE @b_despliega  bit,
          @tipo_campo   varchar(1),
		  @num_reg_proc int = 0

  DECLARE  @rowfile       varchar(500),
           @rowfileo      varchar(500),
           @cuenta           varchar(100),
           @nom_cliente      varchar(100),
		   @sdo_inicial      varchar(100),
    	   @imp_cargos       varchar(100),
		   @imp_abonos       varchar(100),
		   @sdo_final        varchar(100)

  DECLARE  @posicion         int,
           @sql              varchar(max),
		   @cont_campo       int,
		   @contador         int = 0
         
  DECLARE  @k_posic_valida   varchar(1),
           @k_delimitador    varchar(1),
           @k_falso          bit,
           @k_verdadero      bit,
		   @k_abierto        varchar(1)  =  'A',
		   @k_automatica     varchar(2)  =  'AU',
		   @k_pendiente      varchar(1)  =  'P',
		   @k_error          varchar(1)  =  'E',
		   @k_warning        varchar(1)  =  'W'

  SET  @posicion       =  0
 
  SET  @k_posic_valida = '-'
  SET  @k_verdadero    =  1
  SET  @k_falso        =  0
  SET  @k_delimitador  =  ','
  
  SET @paths = LTRIM(@paths + 'file' + @pPeriodo) + '.CSV'

  SET  @sql  =  
  'BULK INSERT #fileP FROM ' + char(39) + @paths + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
  ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'

  EXEC(@sql)

--  SELECT @sql

  INSERT INTO #file (Rowfile) 
  SELECT Rowfile FROM #fileP

  IF  @inicio  <>  0
  BEGIN
    DELETE FROM #file WHERE id_renglon < @inicio OR id_renglon > @fin 
  END
 
  --INSERT INTO #fileP (Rowfile) 
  --SELECT Rowfile FROM #fileP

  UPDATE #file SET Rowfile = LTRIM(REPLACE(Rowfile,CHAR(13),' '))
  UPDATE #file SET Rowfile = LTRIM(REPLACE(Rowfile,CHAR(10),' '))
  UPDATE #file SET Rowfile = LTRIM(Rowfile + ',')

--  SELECT * FROM #file 
  SET @rowfile   = ' '

  DECLARE file_cursor CURSOR FOR SELECT Rowfile FROM #file 
  OPEN file_cursor

  FETCH file_cursor INTO @rowfile 

  SET @b_despliega = 1  
  --SET @contador = 1

  WHILE (@@fetch_status = 0 )
  BEGIN
 --   IF @contador > 900 
	--SELECT 'Prcesando Renglon ==> ' + CONVERT(varchar(8), @contador)
    SET @cont_campo  =  0
    SET @cuenta  =  ' '
	SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @cuenta OUT, 
                                  @rowfileo OUT

	SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
    SET  @rowfile  =  @rowfileo

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @nom_cliente OUT, 
                                  @rowfileo OUT

    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowfile  =  @rowfileo

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @sdo_inicial OUT, 
                                  @rowfileo OUT

    SET @sdo_inicial = ISNULL(@sdo_inicial,'0')
	IF  @sdo_inicial = ' ' 
	BEGIN
	  SET @sdo_inicial = '0'
	END

    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowfile  =  @rowfileo

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @imp_cargos OUT, 
                                  @rowfileo OUT

    SET @imp_cargos = ISNULL(@imp_cargos,'0')
	IF  @imp_cargos = ' ' 
	BEGIN
	  SET @imp_cargos = '0'
	END

    SET  @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowfile  =  @rowfileo

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @imp_abonos OUT, 
                                  @rowfileo OUT

    SET @imp_abonos = ISNULL(@imp_abonos,'0')
	IF  @imp_abonos = ' ' 
	BEGIN
	  SET @imp_abonos = '0'
	END

    SET  @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowfile  =  @rowfileo

    EXEC spObtCampo  @rowfile, @tipo_campo, 
                                  @sdo_final OUT, 
                                  @rowfileo OUT

    SET @sdo_final = ISNULL(@sdo_final,'0')
	IF  @sdo_final = ' ' 
	BEGIN
	  SET @sdo_final = '0'
	END

    IF  NOT EXISTS (SELECT 1 FROM CI_CAT_CTA_CONT WHERE CVE_EMPRESA = @pCveEmpresa AND CTA_CONTABLE = @cuenta)
	BEGIN
	  INSERT CI_CAT_CTA_CONT (CVE_EMPRESA, CTA_CONTABLE, DESC_CTA_CONT, CVE_REFERENCIA, SIT_CUENTA) VALUES
	                         (@pCveEmpresa, @cuenta, @nom_cliente, @k_automatica, @k_pendiente)
      SET  @pError    =  'Alta de Cuenta file' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' +  @cuenta 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
	END  

	SET @num_reg_proc = @num_reg_proc  + 1

	BEGIN TRY

	INSERT INTO CI_file_OPERATIVA
	           (CVE_EMPRESA,
			    ANO_MES,
				CTA_CONTABLE,
				SDO_INICIAL,
				IMP_CARGO,
				IMP_ABONO,
				SDO_FINAL,
				SDO_INICIAL_C,
				IMP_CARGO_C,
				IMP_ABONO_C,
				SDO_FINAL_C,
				B_file)
	VALUES     (
	            @pCveEmpresa,
				@pAnoMes,
				@cuenta, 
	            CONVERT(NUMERIC(12,2),@sdo_inicial),
	            CONVERT(NUMERIC(12,2),@imp_cargos),
			    CONVERT(NUMERIC(12,2),@imp_abonos),
			    CONVERT(NUMERIC(12,2),@sdo_final),
				0,
				0,
				0,
				0,
				@k_verdadero) 
    END TRY

    BEGIN CATCH
      SELECT ' ENTRE A CATCH ' 
	  SELECT CONVERT(VARCHAR(10), @num_reg_proc)
	  SELECT @rowfile
      IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
      BEGIN
	    CLOSE file_cursor
        DEALLOCATE file_cursor
      END

      IF object_id('tempdb..#file') IS NOT NULL 
      BEGIN
        DROP TABLE #file
      END

      IF object_id('tempdb..#fileP') IS NOT NULL 
      BEGIN
        DROP TABLE #fileP
      END

      IF object_id('tempdb..#BAL_EXTRAC') IS NOT NULL 
      BEGIN
        DROP TABLE #BAL_EXTRAC
      END

      SET  @pError    =  'Error de Ejecucion Proceso Gen. file COI ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
      SELECT @pMsgError
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END CATCH

    FETCH file_cursor INTO  @rowfile
 --   SET @contador = @contador + 1
  END            

  CLOSE  file_cursor
  DEALLOCATE file_cursor

  IF object_id('tempdb..#file') IS NOT NULL 
  BEGIN
    DROP TABLE #file
  END
  IF object_id('tempdb..#file') IS NOT NULL 
  BEGIN
    DROP TABLE #file
  END
  IF object_id('tempdb..#BAL_EXTRAC') IS NOT NULL 
  BEGIN
    DROP TABLE #BAL_EXTRAC
  END
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc
END
