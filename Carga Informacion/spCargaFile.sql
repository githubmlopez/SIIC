USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaFile')
BEGIN
  DROP  PROCEDURE spCargaFile
END
GO
-- exec spCargaFile 1,'CU','MARIO','SIIC','202010',1,1,1,0,' ',' '
CREATE PROCEDURE [dbo].[spCargaFile] 
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

  DECLARE
  @tipo_info       int,
  @id_formato      int,
  @id_bloque       int,
  @num_reng_ini    int,
  @num_reng_fin    int,
  @num_campos      int,
  @cadena_fin      varchar(3),
  @cve_tipo_bloque varchar(4),
  @cadena_enca     nvarchar(15),
  @num_reng_d_cad  int

  DECLARE
  @secuencia       int,
  @cve_tipo_campo  varchar(1),
  @num_renglon     int,
  @num_columna     int

  CREATE TABLE #FILEP 
  (Rowfile     varchar(max))

  CREATE TABLE #FILE 
  (id_renglon  int identity,
   Rowfile     varchar(max))

  DECLARE  @NunRegistros      int  =  0, 
           @RowCount          int  =  0,
		   @res_ini           int  =  0,
		   @res_fin           int  =  0,
		   @cont_columna      int  =  0 

  DECLARE @cve_tipo_archivo varchar(3),
          @extension        varchar(10),
          @b_separador      bit,
          @car_separador    varchar(1),
		  @posicion         int,
          @desc_archivo     varchar(100),
          @nom_archivo      varchar(20),
		  @cve_tipo_periodo varchar(1),
		  @path             varchar(100),
		  @pathcalc         varchar(100),
		  @cve_correcto     int = 0

  DECLARE @row_file         varchar(max) = ' ',
	      @row_fileo        varchar(max) = ' ',
		  @tipo_campo       varchar(1)   = ' ', 
          @campo            varchar(max) = ' '

  DECLARE @k_csv            varchar(3)  =  'CSV',
          @k_ascii          varchar(3)  =  'TXT',
		  @k_directorio     varchar(3)  =  'DIR',
		  @k_verdadero      bit         =  1,
		  @k_correcto       int         =  1,
		  @k_no_formato     int         =  2,
		  @k_no_archivo     int         =  3,
		  @k_error          varchar(1)  =  'E'

  DECLARE @sql              varchar(max)

  SELECT
  @tipo_info  = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
  @id_bloque  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
  @id_formato = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
  FROM FC_PROCESO  WHERE
  CVE_EMPRESA    = @pCveEmpresa    AND
  ID_PROCESO     = @pIdProceso
  BEGIN TRY
  EXEC spVerArchCarga
  @pIdCliente,
  @pCveEmpresa,
  @pCodigoUsuario,
  @pCveAplicacion,
  @pAnoPeriodo,
  @pIdProceso,
  @pFolioExe,	
  @pIdTarea,
  @tipo_info,
  @id_bloque,
  @id_formato,
  @cve_correcto OUT,
  @pathcalc OUT, 
  @cve_tipo_archivo OUT,
  @extension OUT,
  @b_separador OUT,
  @car_separador OUT,
  @num_campos OUT,
  @pBError  OUT,
  @pError OUT,
  @pMsgError OUT
  END TRY
 
  BEGIN CATCH 
  SET  @pError    =  '(E) Verifica File;'
  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
  EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  SET  @pBError  =  @k_verdadero
  RETURN
  END CATCH

  IF  @cve_correcto = @k_correcto
  BEGIN
    DELETE FROM FC_CARGA_COL_DATO  WHERE
	CVE_EMPRESA      =  @pCveEmpresa AND
    TIPO_INFORMACION =  @tipo_info   AND
	ID_BLOQUE        =  @id_bloque   AND
	ID_FORMATO       =  @id_formato  AND
	PERIODO          =  @pAnoPeriodo  

    DELETE FROM FC_CARGA_IND_DATO  WHERE
	CVE_EMPRESA      =  @pCveEmpresa AND
    TIPO_INFORMACION =  @tipo_info   AND
	ID_FORMATO       =  @id_formato  AND
	PERIODO          =  @pAnoPeriodo  

--	SELECT @pathcalc

    IF  @cve_tipo_archivo  IN (@k_ascii, @k_csv)
	BEGIN 
	  BEGIN TRY
      SET  @sql  =  
     'BULK INSERT #FILEP FROM ' + char(39) + @pathcalc + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
     ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'
      EXEC (@sql)
      END TRY

	  BEGIN CATCH
      SET  @pError    =  '(E) BULK COPY;'
	  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
      RETURN
	  END CATCH
    END
	ELSE
	BEGIN
      IF  @cve_tipo_archivo IN (@k_directorio)
      BEGIN
        BEGIN TRY
        EXEC spCargaDir
	    @pIdCliente,
        @pCveEmpresa,
        @pCodigoUsuario,
        @pCveAplicacion,
        @pAnoPeriodo,
        @pIdProceso,
        @pFolioExe,
        @pIdTarea,
		@pathcalc,
		@extension,
		@pError OUT,
        @pMsgError OUT
        END TRY

	    BEGIN CATCH
        SET  @pError    =  '(E) CARGA DIRECTORIO;'
	    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	    SET  @pBError  =  @k_verdadero
        RETURN
	    END CATCH
      END
	END

    INSERT INTO  #FILE (Rowfile)
    SELECT Rowfile FROM #FILEP

    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
--    SELECT * FROM #FILE
    SET @RowCount     = 1
    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT @row_file = Rowfile
      FROM   #FILE
	  WHERE  id_renglon  = @RowCount

	  IF SUBSTRING(@row_file,LEN(@row_file),LEN(@row_file)) <> @car_separador
	  BEGIN
	    UPDATE #FILE SET  Rowfile = @row_file + @car_separador
		WHERE  id_renglon  = @RowCount
	  END
      SET @RowCount      = @RowCount + 1
    END

------------------------------------------------------------------------------
-- Procesa Bloques de Cada Formato
-------------------------------------------------------------------------------

    DECLARE  @TBloque         TABLE
            (RowID            int  identity(1,1),
	         TIPO_INFORMACION int,
	         ID_BLOQUE        int,
	         NUM_RENG_INI     int,
	         NUM_RENG_FIN     int,
	         NUM_CAMPOS       int,
	         CADENA_FIN       varchar(3),
	         CVE_TIPO_BLOQUE  varchar(4),
	         CADENA_ENCA      nvarchar(15),
	         NUM_RENG_D_CAD   int)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT @TBloque   
	      (TIPO_INFORMACION,
	       ID_BLOQUE,
	       NUM_RENG_INI,
	       NUM_RENG_FIN,
	       NUM_CAMPOS,
	       CADENA_FIN,
	       CVE_TIPO_BLOQUE,
	       CADENA_ENCA,
	       NUM_RENG_D_CAD)
    SELECT 
    TIPO_INFORMACION,
    ID_BLOQUE,
    NUM_RENG_INI,
    NUM_RENG_FIN,
    NUM_CAMPOS,
    CADENA_FIN,
    CVE_TIPO_BLOQUE,
    CADENA_ENCA,
    NUM_RENG_D_CAD
    FROM  FC_CARGA_RENG_ENCA  WHERE
		  CVE_EMPRESA       =  @pCveEmpresa AND
		  TIPO_INFORMACION  =  @tipo_info   AND
		  ID_BLOQUE         =  @id_bloque
    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT 
      @tipo_info       =  TIPO_INFORMACION,
      @id_bloque       =  ID_BLOQUE,
      @num_reng_ini    =  NUM_RENG_INI,
      @num_reng_fin    =  NUM_RENG_FIN,
      @num_campos      =  NUM_CAMPOS,
      @cadena_fin      =  CADENA_FIN,
      @cve_tipo_bloque =  CVE_TIPO_BLOQUE,
      @cadena_enca     =  CADENA_ENCA,
      @num_reng_d_cad  =  NUM_RENG_D_CAD
	  FROM @TBloque
	  WHERE  RowID  =  @RowCount
--	  SELECT 'spCalIniFinReng'  --*

      BEGIN TRY 
      EXEC spCalIniFinReng
      @pIdCliente,
      @pCveEmpresa,
      @pCodigoUsuario,
      @pCveAplicacion,
      @pAnoPeriodo,
      @pIdProceso,
      @pFolioExe,
      @pIdTarea,
      @cve_tipo_bloque,
      @num_reng_ini,
      @num_reng_fin,
      @cadena_fin,
      @cadena_enca,
      @num_reng_d_cad,
      @res_ini OUT,
      @res_fin OUT, 
      @pError OUT,
      @pMsgError OUT
	  END TRY
	  BEGIN CATCH
      SET  @pError    =  '(E) CARGA INI FIN REG;'
	  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
      RETURN
	  END CATCH

	  BEGIN TRY
	  EXEC spCargaBloqCsvTxt
      @pIdCliente,
      @pCveEmpresa,
      @pCodigoUsuario,
      @pCveAplicacion,
      @pAnoPeriodo,
      @pIdProceso,
      @pFolioExe,
      @pIdTarea,
      @tipo_info,
	  @id_bloque,
	  @id_formato,
      @num_campos,
      @res_ini,
      @res_fin, 
      @pAnoPeriodo,
	  @cve_tipo_archivo, 
	  @b_separador,
	  @car_separador,
      @pError OUT,
      @pMsgError OUT
      END TRY

	  BEGIN CATCH
      SET  @pError    =  '(E) CARGA BLOQUE;'
	  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
      RETURN
	  END CATCH

	  SET @RowCount = @RowCount + 1
    END
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @NunRegistros

------------------------------------------------------------------------------
-- Procesa Campos Individuales de Cada Formato
-------------------------------------------------------------------------------

    DECLARE  @TCampoInd       TABLE
            (RowID            int  identity(1,1),
	         TIPO_INFORMACION int,
	         SECUENCIA        int,
             CVE_TIPO_BLOQUE  varchar(4),
	         CVE_TIPO_CAMPO   varchar(1),
	         NUM_RENGLON      int,
	         NUM_COLUMNA      int,
			 CADENA_ENCA      nvarchar(15),
			 NUM_RENG_D_CAD   int)


-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT @TCampoInd   
	(
	TIPO_INFORMACION,
	SECUENCIA,
    CVE_TIPO_BLOQUE,
	CVE_TIPO_CAMPO,
	NUM_RENGLON,
	NUM_COLUMNA,
	CADENA_ENCA,
	NUM_RENG_D_CAD)
    SELECT 
    TIPO_INFORMACION,
	SECUENCIA,
    CVE_TIPO_BLOQUE,
	CVE_TIPO_CAMPO,
	NUM_RENGLON,
	NUM_COLUMNA,
	CADENA_ENCA,
	NUM_RENG_D_CAD
	FROM  FC_CARGA_IND  WHERE
    CVE_EMPRESA       =  @pCveEmpresa AND
	TIPO_INFORMACION  =  @tipo_info  
    SET @NunRegistros = @@ROWCOUNT

-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1
--	select * from @TCampoInd
    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT 
      @tipo_info       =  TIPO_INFORMACION,
	  @secuencia       =  SECUENCIA,
      @cve_tipo_bloque =  CVE_TIPO_BLOQUE,
	  @cve_tipo_campo  =  CVE_TIPO_CAMPO,
	  @num_renglon     =  NUM_RENGLON,
	  @num_columna     =  NUM_COLUMNA,
	  @cadena_enca     =  CADENA_ENCA,
	  @num_reng_d_cad   = NUM_RENG_D_CAD
	  FROM @TCampoInd
	  WHERE  RowID  =  @RowCount

      BEGIN TRY
      EXEC spCalIniFinReng
      @pIdCliente,
      @pCveEmpresa,
      @pCodigoUsuario,
      @pCveAplicacion,
      @pAnoPeriodo,
      @pIdProceso,
      @pFolioExe,
      @pIdTarea,
      @cve_tipo_bloque,
      @num_renglon,
      @num_renglon,
      @cadena_fin,
      @cadena_enca,
      @num_reng_d_cad,
      @res_ini OUT,
      @res_fin OUT, 
      @pError OUT,
      @pMsgError OUT

	  END TRY

	  BEGIN CATCH
      SET  @pError    =  '(E) CARGA INI FIN REG;'
	  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
      RETURN
	  END CATCH
	  --SELECT CONVERT(VARCHAR(10), @res_ini)
	  --SELECT CONVERT(VARCHAR(10), @res_fin)

      SELECT @row_file = Rowfile FROM #FILE  WHERE
	  id_renglon  =  @res_ini

      SET  @cont_columna  =  1
	  
	  WHILE @num_columna >=  @cont_columna 
	  BEGIN
        IF  @cont_columna  >  1
	    BEGIN
	      SET  @row_file  =  @row_fileo 
	    END
        SELECT @tipo_campo = CVE_TIPO_CAMPO  FROM  FC_CARGA_IND  WHERE 
        CVE_EMPRESA       = @pCveEmpresa AND
        TIPO_INFORMACION  = @tipo_info  AND
        SECUENCIA   = @secuencia

		BEGIN TRY
        EXEC spObtCampoSep
             @pIdCliente,
             @pCveEmpresa,
             @pCodigoUsuario,
             @pCveAplicacion,
             @pAnoPeriodo,
             @pIdProceso,
             @pFolioExe,
             @pIdTarea,
             @row_file,
             @tipo_campo, 
             @car_separador, 
             @campo OUT, 
             @posicion OUT, 
             @row_fileo OUT,
             @pError OUT,
             @pMsgError OUT
	    END TRY
		 
	    BEGIN CATCH
        SET  @pError    =  '(E) OBT. CAMPO SEPARADO ;'
	    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	    SET  @pBError  =  @k_verdadero
        RETURN
	    END CATCH
        SET  @cont_columna  =  @cont_columna + 1
      END

      BEGIN TRY
	  INSERT  INTO FC_CARGA_IND_DATO
      (
      CVE_EMPRESA,
      TIPO_INFORMACION,
	  ID_FORMATO,
	  PERIODO,
      SECUENCIA,
      VAL_DATO
      ) 
      VALUES
      (
      @pCveEmpresa,
      @tipo_info,
	  @id_formato,
	  @pAnoPeriodo,
      @secuencia,
      @campo
      )
	  END TRY
	  BEGIN CATCH
      SET  @pError    =  '(E) OBT. CAMPO SEPARADO;'
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
      RETURN
	  END CATCH

	  SET @RowCount     = @RowCount + 1
    END 
  END
  ELSE
  BEGIN
    IF  @cve_correcto  =  @k_no_formato
	BEGIN
      SET  @pError    =  '(E) No Existe formato ' + ISNULL(@id_formato, 'NULO') + ' ;' 
	END
	ELSE
	BEGIN
      SET  @pError    =  '(E) No extste path periodo-formato ' +  isnull(@pathcalc, 'NULO') + ' ;'
	END
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	SET  @pBError  =  @k_verdadero  
  END
END