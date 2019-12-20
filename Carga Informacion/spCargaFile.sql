USE CARGADOR
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCargaFile')
BEGIN
  DROP  PROCEDURE spCargaFile
END
GO
-- exec spCargaFile 15,1,'MARIO',1,'CU','CARGAINF','201906',' ',' '
CREATE PROCEDURE [dbo].[spCargaFile] 
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pPeriodo       varchar(8), 
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
  FROM FC_GEN_PROCESO  WHERE
  ID_CLIENTE     = @pIdCliente     AND
  CVE_EMPRESA    = @pCveEmpresa    AND
  CVE_APLICACION = @pCveAplicacion AND
  ID_PROCESO     = @pIdProceso

  EXEC spVerArchCarga 
  @pIdProceso,	
  @pIdTarea,
  @pCodigoUsuario,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pPeriodo, 
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
  @pError OUT,
  @pMsgError OUT

  BEGIN TRY

  IF  @cve_correcto = @k_correcto
  BEGIN
--    SELECT 'CORRECTO ' 
    DELETE FROM FC_CARGA_COL_DATO  WHERE
    ID_CLIENTE       =  @pIdCliente  AND
	CVE_EMPRESA      =  @pCveEmpresa AND
    TIPO_INFORMACION =  @tipo_info   AND
	ID_BLOQUE        =  @id_bloque   AND
	ID_FORMATO       =  @id_formato  AND
	PERIODO          =  @pPeriodo  

    DELETE FROM FC_CARGA_IND_DATO  WHERE
    ID_CLIENTE       =  @pIdCliente  AND
	CVE_EMPRESA      =  @pCveEmpresa AND
    TIPO_INFORMACION =  @tipo_info   AND
	ID_FORMATO       =  @id_formato  AND
	PERIODO          =  @pPeriodo  

--	SELECT @pathcalc

    IF  @cve_tipo_archivo  IN (@k_ascii, @k_csv)
	BEGIN 
      SET  @sql  =  
     'BULK INSERT #FILEP FROM ' + char(39) + @pathcalc + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
     ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'
      EXEC (@sql)
    END
	ELSE
	BEGIN
      IF  @cve_tipo_archivo IN (@k_directorio)
      BEGIN
        EXEC spCargaDir
	    @pIdProceso,	
        @pIdTarea,
        @pCodigoUsuario,
        @pIdCliente,
        @pCveEmpresa,
        @pCveAplicacion,
		@pathcalc,
		@extension,
		@pError OUT,
        @pMsgError OUT
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
          ID_CLIENTE        =  @pIdCliente  AND
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

      EXEC spCalIniFinReng 
      @pIdProceso,	
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pPeriodo,
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

	  EXEC spCargaBloqCsvTxt 
      @pIdProceso,	
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @tipo_info,
	  @id_bloque,
	  @id_formato,
      @num_campos,
      @res_ini,
      @res_fin, 
      @pPeriodo,
	  @cve_tipo_archivo, 
	  @b_separador,
	  @car_separador,
      @pError OUT,
      @pMsgError OUT

	  SET @RowCount = @RowCount + 1
    END
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @NunRegistros

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
    ID_CLIENTE        =  @pIdCliente  AND
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

      EXEC spCalIniFinReng 
      @pIdProceso,	
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pPeriodo,
      @cve_tipo_bloque,
      @num_renglon,
      @num_renglon,
      ' ',
      @cadena_enca,
      @num_reng_d_cad,
      @res_ini OUT,
      @res_fin OUT, 
      @pError OUT,
      @pMsgError OUT

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
	    ID_CLIENTE        = @pIdCliente  AND
        CVE_EMPRESA       = @pCveEmpresa AND
        TIPO_INFORMACION  = @tipo_info  AND
        SECUENCIA   = @secuencia
        EXEC spObtCampoSep
             @pIdProceso,
             @pIdTarea,
             @pCodigoUsuario,
             @pIdCliente,
             @pCveEmpresa,
             @row_file,
             @tipo_campo, 
             @car_separador, 
             @campo OUT, 
             @posicion OUT, 
             @row_fileo OUT,
             @pError OUT,
             @pMsgError OUT

        SET  @cont_columna  =  @cont_columna + 1
      END

      INSERT  INTO FC_CARGA_IND_DATO
      (
      ID_CLIENTE,
      CVE_EMPRESA,
      TIPO_INFORMACION,
	  ID_FORMATO,
	  PERIODO,
      SECUENCIA,
      VAL_DATO
      ) 
      VALUES
      (
      @pIdCliente,
      @pCveEmpresa,
      @tipo_info,
	  @id_formato,
	  @pPeriodo,
      @secuencia,
      @campo
      )
	  SET @RowCount     = @RowCount + 1
    END 
  END
  ELSE
  BEGIN
    IF  @cve_correcto  =  @k_no_formato
	BEGIN
      SET  @pError    =  'No Existe el formato Especificado ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
	END
	ELSE
	BEGIN
      SET  @pError    =  'No extste archivo-directorio para el periodo-formato ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
	END
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
--    SELECT @pMsgError 
    EXECUTE spCreaTareaEvento 
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_error,
    @pError,
    @pMsgError
  END
  END TRY
  BEGIN CATCH
    SET  @pError    =  'Error de Ejecucion Proceso Carga File ' + ISNULL(ERROR_PROCEDURE(), 'NULO ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), 'NULO '))
--   SELECT @pMsgError 
    EXECUTE spCreaTareaEvento 
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_error,
    @pError,
    @pMsgError
  END CATCH
END




