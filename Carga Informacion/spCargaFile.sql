USE CARGAINF
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGAINF.sys.procedures WHERE Name =  'spCargaFile')
BEGIN
  DROP  PROCEDURE spCargaFile
END
GO
-- exec spCargaFile 1,1,'MARIO', 1, 'CU',1,'201812', ' ', ' '
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
  DECLARE
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
          @desc_archivo     varchar(100),
          @nom_archivo      varchar(20),
		  @cve_tipo_periodo varchar(1),
		  @path             varchar(50)

  DECLARE @row_file         varchar(max) = ' ',
	      @row_fileo        varchar(max) = ' ',
		  @tipo_campo       varchar(1)   = ' ', 
          @campo            varchar(max) = ' '

  DECLARE @k_csv            varchar(3)  =  'CSV',
          @k_ascii          varchar(3)  =  'TXT'

  DECLARE @sql              varchar(max)

  IF  EXISTS(SELECT 1 FROM FC_FORMATO WHERE
             ID_CLIENTE  =  @pIdCliente  AND
			 CVE_EMPRESA =  @pCveEmpresa AND
			 ID_FORMATO  =  @pIdFormato)
  BEGIN
    DELETE FROM FC_CARGA_COL_DATO  WHERE
    ID_CLIENTE  =  @pIdCliente  AND
	CVE_EMPRESA =  @pCveEmpresa AND
	ID_FORMATO  =  @pIdFormato  AND
	PERIODO     =  @pPeriodo  

    DELETE FROM FC_CARGA_IND_DATO  WHERE
    ID_CLIENTE  =  @pIdCliente  AND
	CVE_EMPRESA =  @pCveEmpresa AND
	ID_FORMATO  =  @pIdFormato  AND
	PERIODO     =  @pPeriodo  

    SELECT 
	@cve_tipo_archivo  =  f.CVE_TIPO_ARCHIVO, @desc_archivo = f.DESC_ARCHIVO,
	@nom_archivo = f.NOM_ARCHIVO, @cve_tipo_periodo = f.CVE_TIPO_PERIODO,
	@path = f.PATHS
	FROM FC_FORMATO f WHERE
    ID_CLIENTE  =  @pIdCliente  AND
	CVE_EMPRESA =  @pCveEmpresa AND
	ID_FORMATO  =  @pIdFormato
    
    SET @path = LTRIM(@path + @nom_archivo + @pPeriodo) + '.' + @cve_tipo_archivo

--	SELECT @path

    IF  @cve_tipo_archivo  IN (@k_ascii, @k_csv)
	BEGIN 
      SET  @sql  =  
     'BULK INSERT #FILEP FROM ' + char(39) + @path + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
     ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'
    END
    EXEC (@sql)

    INSERT INTO  #FILE (Rowfile)
    SELECT Rowfile FROM #FILEP

--    SELECT * FROM #FILE

------------------------------------------------------------------------------
-- Procesa Bloques de Cada Formato
-------------------------------------------------------------------------------

    DECLARE  @TBloque        TABLE
            (RowID           int  identity(1,1),
	         ID_FORMATO      int,
	         ID_BLOQUE       int,
	         NUM_RENG_INI    int,
	         NUM_RENG_FIN    int,
	         NUM_CAMPOS      int,
	         CADENA_FIN      varchar(3),
	         CVE_TIPO_BLOQUE varchar(4),
	         CADENA_ENCA     nvarchar(15),
	         NUM_RENG_D_CAD  int)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT @TBloque   
	      (ID_FORMATO,
	       ID_BLOQUE,
	       NUM_RENG_INI,
	       NUM_RENG_FIN,
	       NUM_CAMPOS,
	       CADENA_FIN,
	       CVE_TIPO_BLOQUE,
	       CADENA_ENCA,
	       NUM_RENG_D_CAD)
    SELECT 
    ID_FORMATO,
    ID_BLOQUE,
    NUM_RENG_INI,
    NUM_RENG_FIN,
    NUM_CAMPOS,
    CADENA_FIN,
    CVE_TIPO_BLOQUE,
    CADENA_ENCA,
    NUM_RENG_D_CAD
    FROM  FC_CARGA_RENG_ENCA  WHERE
          ID_CLIENTE  =  @pIdCliente  AND
		  CVE_EMPRESA =  @pCveEmpresa AND
		  ID_FORMATO  =  @pIdFormato  
    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT 
      @id_formato      =  ID_FORMATO,
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

      EXEC spCalIniFinReng 
      @pIdProceso,	
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pIdFormato,
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

	  --SELECT CONVERT(VARCHAR(10), @res_ini)
	  --SELECT CONVERT(VARCHAR(10), @res_fin)

	  EXEC spCargaBloqCsv 
      @pIdProceso,	
      @pIdTarea,
      @pCodigoUsuario,
      @pIdCliente,
      @pCveEmpresa,
      @pIdFormato,
      @id_bloque,
      @num_campos,
      @res_ini,
      @res_fin, 
      @pPeriodo, 
      @pError OUT,
      @pMsgError OUT

	  SET @RowCount = @RowCount + 1
    END
------------------------------------------------------------------------------
-- Procesa Campos Individuales de Cada Formato
-------------------------------------------------------------------------------

    DECLARE  @TCampoInd      TABLE
            (RowID           int  identity(1,1),
	         ID_FORMATO      int,
	         SECUENCIA       int,
             CVE_TIPO_BLOQUE varchar(4),
	         CVE_TIPO_CAMPO  varchar(1),
	         NUM_RENGLON     int,
	         NUM_COLUMNA     int,
			 CADENA_ENCA     nvarchar(15),
			 NUM_RENG_D_CAD  int)

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
    INSERT @TCampoInd   
	(
	ID_FORMATO,
	SECUENCIA,
    CVE_TIPO_BLOQUE,
	CVE_TIPO_CAMPO,
	NUM_RENGLON,
	NUM_COLUMNA,
	CADENA_ENCA,
	NUM_RENG_D_CAD)
    SELECT 
    ID_FORMATO,
	SECUENCIA,
    CVE_TIPO_BLOQUE,
	CVE_TIPO_CAMPO,
	NUM_RENGLON,
	NUM_COLUMNA,
	CADENA_ENCA,
	NUM_RENG_D_CAD
	FROM  FC_CARGA_IND  WHERE
    ID_CLIENTE  =  @pIdCliente  AND
    CVE_EMPRESA =  @pCveEmpresa AND
	ID_FORMATO  =  @pIdFormato  
    SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT 
      @id_formato      =  ID_FORMATO,
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
      @pIdFormato,
      @pPeriodo,
      @cve_tipo_bloque,
      @num_renglon,
      0,
      @cadena_fin,
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
--	  SELECT 'CICLO COL ' + CONVERT(VARCHAR(10), @num_columna )
      SELECT @tipo_campo = CVE_TIPO_CAMPO  FROM  FC_CARGA_IND  WHERE 
	    ID_CLIENTE  = @pIdCliente  AND
        CVE_EMPRESA = @pCveEmpresa AND
        ID_FORMATO  = @pIdFormato  AND
        SECUENCIA   = @secuencia
      EXEC spObtCampoCsv
           @pIdProceso,
           @pIdTarea,
           @pCodigoUsuario,
           @pIdCliente,
           @pCveEmpresa,
           @pIdFormato,
           @row_file,
           @tipo_campo, 
           @campo OUT, 
           @row_fileo OUT,
           @pError OUT,
           @pMsgError OUT
        SET  @cont_columna  =  @cont_columna + 1
      END

      INSERT  INTO FC_CARGA_IND_DATO
      (
      ID_CLIENTE,
      CVE_EMPRESA,
      ID_FORMATO,
	  PERIODO,
      SECUENCIA,
      VAL_DATO
      ) 
      VALUES
      (
      @pIdCliente,
      @pCveEmpresa,
      @pIdFormato,
	  @pPeriodo,
      @secuencia,
      @campo
      )
	  SET @RowCount     = @RowCount + 1
    END 
  END
END

--    BEGIN CATCH
--      SELECT ' ENTRE A CATCH ' 
--	  SELECT CONVERT(VARCHAR(10), @num_reg_proc)
--	  SELECT @rowbalanza
--      IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
--      BEGIN
--	    CLOSE balanza_cursor
--        DEALLOCATE balanza_cursor
--      END

--      IF object_id('tempdb..#BALANZA') IS NOT NULL 
--      BEGIN
--        DROP TABLE #BALANZA
--      END

--      IF object_id('tempdb..#BALANZAP') IS NOT NULL 
--      BEGIN
--        DROP TABLE #BALANZAP
--      END

--      IF object_id('tempdb..#BAL_EXTRAC') IS NOT NULL 
--      BEGIN
--        DROP TABLE #BAL_EXTRAC
--      END

--      SET  @pError    =  'Error de Ejecucion Proceso Gen. Balanza COI ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
--      SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
--      SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
--    END CATCH

--END