USE CARGADOR
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCargaBloqCsvTxt')
BEGIN
  DROP  PROCEDURE spCargaBloqCsvTxt
END
GO
-- exec spCargaBloqCsv 1,1,'MARIO', 1, 'CU',1,'201804', ' ', ' '
CREATE PROCEDURE [dbo].[spCargaBloqCsvTxt] 
(
@pIdProceso      numeric(9),	
@pIdTarea        numeric(9),
@pCodigoUsuario  varchar(20),
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pTipoInfo       int,
@pIdBloque       int,
@pIdFormato      int,
@pNumCampos      int,
@pResIni         int ,
@pResFin         int, 
@pPeriodo        varchar(8),
@pCveTipoArchivo varchar(3),
@pBSeparador     bit,
@pCarSeparador   varchar(1), 
@pError          varchar(80) OUT,
@pMsgError       varchar(400) OUT
)
AS
BEGIN
  --CREATE TABLE #FILEP 
  --(id_renglon  int identity,
  -- Rowfile     varchar(max))

  DECLARE  @NunRegistros  int          = 0, 
           @RowCount      int          = 0,  
	       @row_file      varchar(max) = ' ',
	       @row_fileo     varchar(max) = ' ',
		   @num_columna   int          = 0,
		   @tipo_campo    varchar(1)   = ' ', 
           @campo         varchar(max) = ' ',
		   @posicion      int = 0,
		   @pos_ini       int,
		   @pos_fin       int

  DECLARE  @k_csv         varchar(3) = 'CSV',
           @k_txt         varchar(3) = 'TXT',
		   @k_directorio  varchar(3) = 'DIR',
		   @k_verdadero   bit        = 1,
		   @k_falso       bit        = 1
------------------------------------------------------------------------------
-- Procesa Carga Registro de Cada Bloque
-------------------------------------------------------------------------------

  DECLARE  @TBloque    TABLE
          (RowId       int identity,
           Rowfile     varchar(max))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TBloque   
	    (Rowfile)
  SELECT  Rowfile  FROM  #FILE  WHERE
  id_renglon  BETWEEN @pResIni  AND  @pResFin
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @row_file = Rowfile
	FROM   @TBloque
	WHERE  RowID  =		@RowCount
--	SELECT 'CICLO'
    SET  @num_columna  =  1
--	SELECT 'NUM CAMPOS' + 
--	CONVERT(VARCHAR(10), @pNumCampos)
	WHILE @pNumCampos >=  @num_columna 
	BEGIN
      IF  @num_columna  >  1
	  BEGIN
	    SET  @row_file  =  @row_fileo 
	  END
--	  SELECT 'CICLO COL ' + CONVERT(VARCHAR(10), @num_columna )
      SELECT @tipo_campo = CVE_TIPO_CAMPO, @pos_ini = POS_INICIAL, @pos_fin = POS_FINAL
	  FROM  FC_CARGA_POSIC  WHERE 
	  ID_CLIENTE        = @pIdCliente  AND
      CVE_EMPRESA       = @pCveEmpresa AND
      TIPO_INFORMACION  = @pTipoInfo   AND
      ID_BLOQUE         = @pIdBloque   AND
	  NUM_COLUMNA       = @num_columna    

      IF  @pCveTipoArchivo  =  @k_csv OR  @pCveTipoArchivo  = @k_directorio OR
	     (@pCveTipoArchivo  =  @k_txt AND @pBSeparador = @k_verdadero)
	  BEGIN
        EXEC spObtCampoSep
             @pIdProceso,
             @pIdTarea,
             @pCodigoUsuario,
             @pIdCliente,
             @pCveEmpresa,
             @row_file,
             @tipo_campo,
			 @pCarSeparador, 
             @campo OUT,
			 @posicion OUT, 
             @row_fileo OUT,
             @pError OUT,
             @pMsgError OUT
--      SELECT ' CAMPO ' + @campo

      END
	  ELSE
	  BEGIN
        EXEC spObtCampoTxt
             @pIdProceso,
             @pIdTarea,
             @pCodigoUsuario,
             @pIdCliente,
             @pCveEmpresa,
             @row_file,
             @tipo_campo,
			 @pos_ini,
			 @pos_fin, 
             @campo OUT, 
             @pError OUT,
             @pMsgError OUT

	  END

      INSERT  INTO FC_CARGA_COL_DATO
	  (
	  ID_CLIENTE,
	  CVE_EMPRESA,
	  TIPO_INFORMACION,
	  ID_BLOQUE,
	  ID_FORMATO,
	  PERIODO,
	  NUM_REGISTRO,
	  NUM_COLUMNA,
	  VAL_DATO
	  ) 
	  VALUES
	  (
	  @pIdCliente,
	  @pCveEmpresa,
	  @pTipoInfo,
	  @pIdBloque,
	  @pIdFormato,
	  @pPeriodo,
	  @RowCount,
	  @num_columna,
	  @campo
	  )

      SET  @num_columna  =  @num_columna + 1
    END 
	SET @RowCount = @RowCount + 1
  END
END
