USE  ADMON01 
GO
/****** Object:  StoredProcedure  dbo . spCargaFactXml     Script Date: 11/09/2019 04:04:03 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spGenTareasXml')
BEGIN
  DROP  PROCEDURE spGenTareasXml
END
GO
--EXEC dbo.spGenTareasXml 2,'EGG','MARIO','SIIC','201812',202,37,1,0,' ',' '
CREATE PROCEDURE  dbo.spGenTareasXml 
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
  DECLARE  @ruta_s3  varchar(250)

  DECLARE  @k_verdadero varchar(1)    =   1,
           @k_falso     varchar(1)    =   0, 
           @k_ruta_s3   varchar(250)  =  'RUTS3',
		   @k_cerrado   varchar(1)    =  'C',
		   @k_error     varchar(1)    =  'E',
		   @k_emisor    varchar(6)    =  'CFDIEM',
		   @k_receptor  varchar(6)    =  'CFDIRE',
		   @k_cxc       varchar(4)    =  'CFDIEM',
		   @k_cxp       varchar(4)    =  'CFDIRE'
        
  DECLARE @TRutas TABLE 
 (
  RowID           int IDENTITY(1,1),
  NOM_ARCH_S3     varchar(250),
  NOM_ARCHIVO     varchar(250)
 )

  DECLARE @TTareas TABLE 
 (
  TASK_ID         int,
  TASK_TABLE      varchar(100),
  LIFE_CICLE      varchar(100),
  CREATED_AT      datetime,
  LAST_UPDATED    datetime,
  SE_OBJECT_AM    varchar(250),
  OVERWRITE_FILE  bit,
  TASK_PROGRESS   int,
  TASK_INFO       varchar(100),
  FILE_PATH       varchar(250)
 )


  DECLARE @NunRegistros  int, 
          @RowCount      int,
          @pTipoInfo     int,
          @pIdBloque     int,
          @pIdFormato    int,
          @nom_arch_s3   varchar(250),
          @nom_archivo   varchar(250)


  IF  (SELECT SIT_PERIODO
  FROM CI_PERIODO_CONTA
  WHERE CVE_EMPRESA = @pCveEmpresa
    AND ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado
  BEGIN
    BEGIN TRY

    SELECT
    @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
    @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
    @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,13,6))
	FROM FC_PROCESO
    WHERE CVE_EMPRESA = @pCveEmpresa
    AND ID_PROCESO    = @pIdProceso

    SELECT @ruta_s3 = VALOR_ALFA  FROM
    CI_PARAMETRO  WHERE CVE_EMPRESA = @pCveEmpresa  AND  CVE_PARAMETRO  =  @k_ruta_s3
    --'arn:aws:s3:::pruebas-bd/'

    INSERT  @TRutas
    SELECT  @ruta_s3 + CVE_EMPRESA + '/' + ANO_MES + '/' + IIF(CVE_TIPO = @k_cxp, @k_receptor, @k_emisor) + '/' + NOM_ARCHIVO,
            dbo.fnObtDirProceso(@pIdCliente, CVE_EMPRESA, @pTipoInfo, @pIdBloque, @pIdFormato, @pIdProceso, '\\', @k_verdadero) + '\' + NOM_ARCHIVO 
    FROM CFDI_XML_CTE_PERIODO 
    WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
    ANO_MES            =  @pAnoPeriodo

    SELECT @NunRegistros = (SELECT COUNT(*) FROM @TRutas)

	SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT @nom_arch_s3  =  NOM_ARCH_S3, @nom_archivo  =  NOM_ARCHIVO
      FROM   @TRutas
      WHERE  
	  RowID  =  @RowCount
--      INSERT @TTareas
	  EXEC msdb.dbo.rds_download_from_s3
	       @s3_arn_of_file = @nom_arch_s3,
	       @rds_file_path  = @nom_archivo,
	       @overwrite_file=1

      SET @RowCount =  @RowCount  +  1 
    END

    END TRY

	BEGIN CATCH

    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Carga Xmls  ' + ISNULL(CONVERT(VARCHAR(8), @pFolioExe),'NULO')  
    SET  @pMsgError =  @pError +  ' ' + ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError

	END CATCH
  END
  ELSE
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) Periodo cerrado ' + ISNULL(@pAnoPeriodo,'NULO')  
    SET  @pMsgError =  @pError +  ISNULL (SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

-- CXP - FORMATO POR PROCESO
-- borrado de archivos dentro del directorio D:\S3\
-- EXEC msdb.dbo.rds_delete_from_filesystem
--     @rds_file_path='D:\S3\',
--     @force_delete=1;


-- proceso de RDS que copia el archivo de S3 al filesystem con root en D:\S3\
--EXEC msdb.dbo.rds_download_from_s3
--	    @s3_arn_of_file='arn:aws:s3:::pruebas-bd/EGG/201812/CFDIRE/0b2915ef-f66a-4b39-8f0b-e3ad7f6c8407.xml',
--	    @rds_file_path='D:\S3\fmt\000002\EGG\000009\000020\0b2915ef-f66a-4b39-8f0b-e3ad7f6c8407.xml',
--	    @overwrite_file=1

---- query que revisa el estatus de la tarea que regresa el procedure previo
--SELECT * FROM msdb.dbo.rds_fn_task_status(NULL, 20);