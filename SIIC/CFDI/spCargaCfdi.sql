USE [ADMON01]
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCargaCfdi')
BEGIN
  DROP  PROCEDURE spCargaCfdi
END
GO

--EXEC spCargaCfdi 'CU','MARIO','201906',146,1,' ',' '
CREATE PROCEDURE [dbo].[spCargaCfdi]
(
--@pIdProceso       numeric(9),
--@pIdTarea         numeric(9),
--@pCodigoUsuario   varchar(20),
--@pIdCliente       int,
--@pCveEmpresa      varchar(4),
--@pCveAplicacion   varchar(10),
--@pIdFormato       int,
--@pIdBloque        int,
--@pAnoPeriodo      varchar(6),
--@pError           varchar(80) OUT,
--@pMsgError        varchar(400) OUT
--)
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @NunRegistros  int, 
          @RowCount      int,
          @pIdCliente    int,
          @pTipoInfo     int,
          @pIdBloque     int,
          @pIdFormato    int,
		  @nom_archivo   varchar(250)

  DECLARE @cve_tipo      varchar(4),
          @cont_regist   int

  DECLARE @cve_tipo_archivo varchar(3),
          @b_separador      bit,
          @car_separador    varchar(1),
		  @posicion         int,
          @path             nvarchar(100),
		  @pathcalc         nvarchar(250),
		  @pathparam        varchar(250),
		  @cve_correcto     bit = 0

  DECLARE @k_verdadero   bit         = 1,
          @k_activa      varchar(2)  = 'A',
		  @k_error       varchar(1)  = 'E',
		  @k_cve_factura varchar(4)  = 'FACT',
		  @k_cve_CXP     varchar(4)  = 'CXP',
		  @k_fmt_factura int         = 10,
		  @k_fmt_cxp     int         = 20,
		  @k_cerrado     varchar(1)  = 'C'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado
  BEGIN
    BEGIN TRY

    SELECT
    @pIdCliente = CONVERT(INT,SUBSTRING(PARAMETRO,1,6)),
    @pTipoInfo  = CONVERT(INT,SUBSTRING(PARAMETRO,7,6)),
    @pIdBloque  = CONVERT(INT,SUBSTRING(PARAMETRO,13,6)),
    @pIdFormato = CONVERT(INT,SUBSTRING(PARAMETRO,19,6))
    FROM  FC_GEN_PROCESO WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso

	SELECT @path = PATHS FROM CARGADOR.dbo.FC_FORMATO WHERE
    ID_CLIENTE       = @pIdCliente  AND
	CVE_EMPRESA      = @pCveEmpresa AND
	TIPO_INFORMACION = @pTipoInfo   AND
	ID_BLOQUE        = @pIdBloque   AND
	ID_FORMATO       = @pIdFormato

    SET @path =  @path + 
    CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdCliente))) + CONVERT(VARCHAR, @pIdCliente))) + '\' +
    @pCveEmpresa + '\' +
    CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pTipoInfo))) + CONVERT(VARCHAR, @pTipoInfo)))  + '\' + 
    CONVERT(VARCHAR(6), (replicate ('0',(06 - len(@pIdFormato))) + CONVERT(VARCHAR, @pIdFormato))) 
    SET @pathcalc  = @path + '\' + @pAnoPeriodo

	IF  @pIdFormato  =  @k_fmt_factura
	BEGIN
	  SET  @cve_tipo  =  @k_cve_factura
	END
	ELSE
	BEGIN
      IF  @pIdFormato  =  @k_fmt_cxp
      BEGIN
	    SET  @cve_tipo  =  @k_cve_CXP
	  END
	  ELSE
	  BEGIN
        SET @cve_tipo   =  ' '
	  END
	END

	IF  @cve_tipo IN (@k_cve_factura, @k_cve_CXP)
	BEGIN
-------------------------------------------------------------------------------
-- Definición de temporal de nombres de archivo
-------------------------------------------------------------------------------
      DECLARE  @TArchXml       TABLE
              (RowID           int  identity(1,1),
		       NOM_ARCHIVO     varchar(250))
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
      INSERT @TArchXml  (NOM_ARCHIVO)  
      SELECT NOM_ARCHIVO  
      FROM   CFDI_XML_CTE_PERIODO  
      WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND
	         ANO_MES      =  @pAnoPeriodo  AND
	         CVE_TIPO     =  @cve_tipo     
      SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
      SET @RowCount     = 1

--	  SELECT * FROM @TArchXml

      WHILE @RowCount <= @NunRegistros
      BEGIN
        SELECT @nom_archivo = NOM_ARCHIVO FROM @TArchXml
        WHERE  RowID  =  @RowCount
 
		SET @pathparam = @pathcalc + '\' + @nom_archivo

        EXEC  spCfdiBaseDatos
        @pCveEmpresa,
        @pCodigoUsuario,
        @pAnoPeriodo,
        @pIdProceso,
        @pIdTarea,
        @cve_tipo,
        @nom_archivo,
        @pathparam,
        @pError OUT,
        @pMsgError OUT

	    SET @RowCount = @RowCount +  1
      END
      EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @RowCount
    END
    ELSE
	BEGIN
	  SET  @pError    =  'Error en formato ' + isnull(@cve_tipo,'nulo') + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END
    END TRY
	BEGIN CATCH
      SET  @pError    =  'Error Carga CFDI ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      SELECT @pMsgError
--      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
	END CATCH
  END
  ELSE
  BEGIN
    SET  @pError    =  'Periodo Cerrado ' + @pAnoPeriodo + ' ' + ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

