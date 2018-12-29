USE CARGADOR
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCargaBloqCsv')
BEGIN
  DROP  PROCEDURE spCargaBloqCsv
END
GO
-- exec spCargaBloqCsv 1,1,'MARIO', 1, 'CU',1,'201804', ' ', ' '
CREATE PROCEDURE [dbo].[spCargaBloqCsv] 
(
@pIdProceso     numeric(9),	
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pIdFormato     int,
@pIdBloque      int,
@pNumCampos     int,
@pResIni        int ,
@pResFin        int, 
@pPeriodo       varchar(8), 
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  SELECT 'ENTRO CARGA BLOQUE'
  --CREATE TABLE #FILEP 
  --(id_renglon  int identity,
  -- Rowfile     varchar(max))

  DECLARE  @NunRegistros  int          = 0, 
           @RowCount      int          = 0,  
	       @row_file      varchar(max) = ' ',
	       @row_fileo     varchar(max) = ' ',
		   @num_columna   int          = 0,
		   @tipo_campo    varchar(1)   = ' ', 
           @campo         varchar(max) = ' '
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
--  select * from @TBloque
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @row_file = Rowfile
	FROM   @TBloque
	WHERE  RowID  =		@RowCount
--	SELECT 'CICLO'
    SET  @num_columna  =  1
	SELECT 'NUM CAMPOS' + 
	CONVERT(VARCHAR(10), @pNumCampos)
	WHILE @pNumCampos >=  @num_columna 
	BEGIN
      IF  @num_columna  >  1
	  BEGIN
	    SET  @row_file  =  @row_fileo 
	  END
	  SELECT 'CICLO COL ' + CONVERT(VARCHAR(10), @num_columna )
      SELECT @tipo_campo = CVE_TIPO_CAMPO  FROM  FC_CARGA_POSIC  WHERE 
	  ID_CLIENTE  = @pIdCliente  AND
      CVE_EMPRESA = @pCveEmpresa AND
      ID_FORMATO  = @pIdFormato  AND
      ID_BLOQUE   = @pIdBloque   AND
	  NUM_COLUMNA = @num_columna    
	  select 'tipo campo ' + @tipo_campo
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

      INSERT  INTO FC_CARGA_COL_DATO
	  (
	  ID_CLIENTE,
	  CVE_EMPRESA,
	  ID_FORMATO,
	  ID_BLOQUE,
	  PERIODO,
	  NUM_REGISTRO,
	  NUM_COLUMNA,
	  VAL_DATO
	  ) 
	  VALUES
	  (
	  @pIdCliente,
	  @pCveEmpresa,
	  @pIdFormato,
	  @pIdBloque,
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
