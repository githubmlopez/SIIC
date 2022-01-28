USE ADMON01
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spCargaCfdi 1,'EGG','MARIO','SIIC','202009',3,1,1,0,' ',' '
CREATE OR ALTER PROCEDURE [dbo].[spCargaCfdi]
  (
  @pIdCliente     int,
  @pCveEmpresa    varchar(4),
  @pCodigoUsuario varchar(20),
  @pCveAplicacion varchar(10),
  @pAnoPeriodo    varchar(6),
  @pIdProceso     numeric(9),
  @pFolioExe      int,
  @pIdTarea       numeric(9),
  @pBError        bit OUT,
  @pError         varchar(80) OUT,
  @pMsgError      varchar(400) OUT
)
AS
BEGIN
  DECLARE @NunRegistros  int, 
          @RowCount      int,
          @NunRegistros2 int, 
          @RowCount2     int,
          @pTipoInfo     int,
          @pIdBloque     int,
          @pIdFormato    int,
          @xml_cfdi      xml,
		  @nom_archivo   varchar(250)

  DECLARE @cve_tipo      varchar(4),
          @cont_regist   int

  DECLARE @cve_tipo_archivo varchar(3),
          @cve_correcto     bit = 0,
          @tipo_error       varchar(1),
          @b_error_int      bit

  DECLARE @k_verdadero   bit         = 1,
          @k_falso       bit         = 0,
          @k_activa      varchar(2)  = 'A',
          @k_error       varchar(1)  = 'E',
          @k_cerrado     varchar(1)  = 'C'

  CREATE TABLE #TvpError
  (
    RowID int IDENTITY(1,1) NOT NULL,
    TIPO_ERROR VARCHAR(1),
    ERROR VARCHAR(80),
    MSG_ERROR varchar (400)
  )

  DECLARE  @TvpError  TABLE   
 (
    RowID int IDENTITY(1,1) NOT NULL,
    TIPO_ERROR VARCHAR(1),
    ERROR VARCHAR(80),
    MSG_ERROR varchar (400)
 )
  IF  (SELECT SIT_PERIODO
  FROM CI_PERIODO_CONTA
  WHERE CVE_EMPRESA = @pCveEmpresa
    AND ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado
  BEGIN
    BEGIN TRY

    SELECT
    @cve_tipo  = SUBSTRING(PARAMETRO,1,6)
    FROM  FC_PROCESO
    WHERE CVE_EMPRESA = @pCveEmpresa
      AND ID_PROCESO  = @pIdProceso
	  
 -------------------------------------------------------------------------------
 -- Definición de temporal de xml's
 -------------------------------------------------------------------------------
    DECLARE  @TArchXml       TABLE
          (RowID int identity(1,1),
           XML_CFDI    xml,
		   NOM_ARCHIVO varchar(250) )

  -----------------------------------------------------------------------------------------------------
  -- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
  -----------------------------------------------------------------------------------------------------
    INSERT @TArchXml
          (XML_CFDI, NOM_ARCHIVO)
    SELECT XML_CFDI, NOM_ARCHIVO
    FROM CFDI_XML_CTE_PERIODO
    WHERE  CVE_EMPRESA  =  @pCveEmpresa AND
           ANO_MES      =  @pAnoPeriodo AND
           CVE_TIPO     =  @cve_tipo
    SET @NunRegistros = @@ROWCOUNT
  -----------------------------------------------------------------------------------------------------
    SET @RowCount     = 1

    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT @xml_cfdi = XML_CFDI, @nom_archivo = NOM_ARCHIVO
      FROM @TArchXml
      WHERE  RowID  =  @RowCount

      SET @b_error_int     = @k_falso
      BEGIN TRAN
        EXEC  spCfdiBaseDatos
        @pIdCliente,
        @pCveEmpresa,
        @pCodigoUsuario,
        @pCveAplicacion,
        @pAnoPeriodo,
        @pIdProceso,
        @pFolioExe,
        @pIdTarea,
        @cve_tipo,
        @xml_cfdi,
		@nom_archivo,
	    @b_error_int OUT,
        @pError OUT,
        @pMsgError OUT

        -- Verificación de transacción
        IF  @b_error_int  =  @k_verdadero
	    BEGIN
          SET  @pBError  =  @k_verdadero
        END

        IF  @@TRANCOUNT > 0
        BEGIN
          IF  @b_error_int  =  @k_verdadero
	      BEGIN
            INSERT INTO @TvpError
                  (TIPO_ERROR, ERROR, MSG_ERROR)
            SELECT TIPO_ERROR, ERROR, MSG_ERROR
            FROM #TvpError
            ROLLBACK TRAN
          END
	      ELSE
	      BEGIN
            COMMIT TRAN
          END
        END
      SET @RowCount = @RowCount +  1
    END
    END TRY

	BEGIN CATCH
      SET  @pError    =  '(E) Carga CFDI ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      select @pMsgError
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
	  SET  @pBError  =  @k_verdadero
	END CATCH
  END
  ELSE
  BEGIN
    SET  @pError    =  '(E) Periodo Cerrado ** ' + @pAnoPeriodo + ' ' + ISNULL(ERROR_PROCEDURE(), ' ')
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET  @pBError  =  @k_verdadero
  END

  SET @NunRegistros2 = (SELECT COUNT(*)
  FROM @TvpError )

  IF  @NunRegistros2 >  0
  BEGIN
    SET  @pBError  =  @k_verdadero
  END

  SET @RowCount2 =  1

  WHILE @RowCount2 <= @NunRegistros2
  BEGIN
    SELECT @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR
    FROM @TvpError
    WHERE  RowID = @RowCount2
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET @RowCount2 =  @RowCount2  +  1
  END
END
GO
