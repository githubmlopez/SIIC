USE CARGADOR
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spVerArchivos')
BEGIN
  DROP  PROCEDURE spVerArchivos
END
GO
-- exec spVerArchivos 9,1,'MARIO',1,'CU','CARGAINF',1,'201906',' ',' '
CREATE PROCEDURE [dbo].[spVerArchivos] 
(
@pIdProceso     numeric(9),		
@pIdTarea       numeric(9),
@pCodigoUsuario varchar(20),
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pEtapa         int,
@pPeriodo       varchar(8), 
@pError         varchar(80) OUT,
@pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE  @cve_correcto     int,
           @tipo_info        int,
           @id_formato       int,
           @pathcalc         varchar(100), 
           @cve_tipo_archivo varchar(3),
		   @extension        varchar(10),
           @b_separador      bit,
           @car_separador    varchar(1),
		   @id_bloque        int,
		   @NunRegistros     int, 
           @RowCount1        int,
		   @NunRegistros1    int, 
           @RowCount         int,
		   @sql              varchar(max),
		   @num_campos       int,
		   @rowfile          varchar(max)

  DECLARE  @k_verdadero      bit = 1,
           @k_falso          bit = 0,
           @k_correcto       int = 1,
		   @k_csv            varchar(3)  =  'CSV',
           @k_ascii          varchar(3)  =  'TXT',
		   @k_directorio     varchar(3)  =  'DIR',
		   @k_error_carga    varchar(1)  =  '2'

  CREATE TABLE #FILEP 
  (Rowfile     varchar(max))

  DECLARE @TvpFile TABLE
 (
  RowID              int identity(1,1),
  Rowfile            varchar(max)
 )
   DECLARE @TvpArchivos TABLE
 (
   RowID              int identity(1,1),
   TIPO_INFORMACION   int,
   ID_BLOQUE          int,
   ID_FORMATO         int,
   DESC_ARCHIVO       varchar(50),
   PATH               varchar(100),
   CVE_EXISTE         int,
   CVE_CARGA          int,
   REGISTROS          int
  )

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT  INTO  @TvpArchivos 
  SELECT
  TIPO_INFORMACION,
  ID_BLOQUE,
  ID_FORMATO,
  DESC_ARCHIVO,
  ' ',
  0,
  0,
  0
  FROM FC_FORMATO
  FC_FORMATO        WHERE
  ID_CLIENTE        =  @pIdCliente   AND
  CVE_EMPRESA       =  @pCveEmpresa  AND
  ETAPA             =  @pEtapa
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
--  SELECT * FROM  @TvpArchivos 
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @tipo_info = TIPO_INFORMACION, @id_formato = ID_FORMATO, @id_bloque = ID_BLOQUE FROM @TvpArchivos
	WHERE  RowID  =  @RowCount

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

    UPDATE @TvpArchivos SET CVE_EXISTE = @cve_correcto, PATH =  @pathcalc WHERE  RowID  =   @RowCount
 
    IF  @cve_correcto  =  @k_correcto
	BEGIN
      IF  @cve_tipo_archivo  IN (@k_ascii, @k_csv)  AND  @b_separador = @k_verdadero
	  BEGIN 
        DELETE FROM #FILEP
        SET  @sql  =  
       'BULK INSERT #FILEP FROM ' + char(39) + @pathcalc + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
       ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'
        BEGIN TRY
          EXEC (@sql)
	      UPDATE @TvpArchivos SET CVE_CARGA = @cve_correcto  WHERE  RowID  =   @RowCount
 	      UPDATE @TvpArchivos SET REGISTROS =
		 (SELECT COUNT(*) FROM #FILEP)
		  WHERE  RowID  =   @RowCount
        END TRY

        BEGIN CATCH
          UPDATE @TvpArchivos SET CVE_CARGA = @k_error_carga  WHERE  RowID  =   @RowCount
          UPDATE @TvpArchivos SET REGISTROS = 0  WHERE  RowID  =   @RowCount
	    END CATCH
      END

	END

    SET @RowCount     =   @RowCount + 1
  END

  SELECT * FROM  @TvpArchivos 

END

