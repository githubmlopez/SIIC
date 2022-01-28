USE ADMON01
GO
/****** Carga de información de CFDI (xml)  a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCfdiBaseDatos')
BEGIN
  DROP  PROCEDURE spCfdiBaseDatos
END
GO
--EXEC spCfdiBaseDatos 1,'CU','MARIO','SIIC','202002',202,1,1,'CXP',' ',' ',0,' ',' '
CREATE PROCEDURE dbo.spCfdiBaseDatos
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pXmlCfdi         xml,
@pNomArchivo      varchar(250),
@pBError          bit OUT,
@pError           varchar(80) OUT, 
@pMsgError        varchar(400) OUT

)
AS
BEGIN
  DECLARE
  @id_concepto       int,
  @b_error_cfdi      bit

  DECLARE @xml            xml,
          @hDoc           int, 
		  @sql            nvarchar(MAX),
		  @num_folio      int,
		  @ft_timbrado    datetime,
		  @uuid           varchar(36),
		  @cve_tipo       varchar(4),
		  @tipo_comprob   varchar(1),
		  @seccion        varchar(20)

  DECLARE @k_verdadero   bit         = 1,
          @k_falso       bit         = 0,
          @k_error       varchar(1)  = 'E',
		  @k_fol_cpto    varchar(4)  = 'CPCD',
		  @k_pendiente   varchar(2)  = 'PE',
		  @k_pago        varchar(1)  = 'P',
		  @k_egreso      varchar(1)  = 'E'


  BEGIN TRY

  SET @xml = @pXmlCfdi         

  EXEC sp_xml_preparedocument @hDoc OUTPUT, @xml,
  '<Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" 
    xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital"
	xmlns:implocal="http://www.sat.gob.mx/implocal"
	xmlns:pago10="http://www.sat.gob.X|mx/Pagos"/>'
---- Obtiene sello del documento

  EXEC spCfdObtDatos @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                     @pIdTarea, @hdoc, @uuid OUT, @cve_tipo OUT, @tipo_comprob OUT, @pBError, @pError, @pMsgError

  UPDATE CFDI_XML_CTE_PERIODO  SET CVE_TIPO_COMP = @tipo_comprob  WHERE 
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ANO_MES      =  @pAnoPeriodo  AND
  CVE_TIPO     =  @pCveTipo     AND
  NOM_ARCHIVO  =  @pNomArchivo

  IF  NOT EXISTS (SELECT 1 FROM  CFDI_COMPROBANTE  WHERE
                                 CVE_EMPRESA  =  @pCveEmpresa  AND
                                 ANO_MES      =  @pAnoPeriodo  AND
                                 CVE_TIPO     =  @pCveTipo     AND
                                 UUID         =  @uuid)
  BEGIN

--  SELECT 'spCfdInCfdiComprobante'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Comprobante                                                                          --
----------------------------------------------------------------------------------------------------------------------
    SET  @b_error_cfdi = @k_falso
    EXEC spCfdInCfdiComprobante @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                @pIdTarea, @hdoc, @uuid, @pCveTipo, @pNomArchivo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
    IF   @b_error_cfdi  =  @k_verdadero 
	BEGIN
      INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
      SET  @pBError      = @k_verdadero
	END
--	SELECT * FROM CFDI_COMPROBANTE WHERE ANO_MES = '201901'
--SELECT 'spCfdInCfdEmisor'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Emisor                                                                               --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdEmisor       @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END
--SELECT 'spCfdInCfdReceptor'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación del Receptor                                                                             --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdReceptor     @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdProdServ'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Productos y Servicios                                                                 --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdProdServ     @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdComplemento'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Complemento                                                                          --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdComplemento  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo,@b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdImpuestoS'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de ImpuestoS                                                                             --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdImpuestoS    @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdTrasladoS'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de TrasladoS                                                                             --
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdTrasladoS    @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdImpLocalS'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de ImpLocalS                                                                            --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdImpLocalS    @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInCfdRetencionS'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de RetencionS                                                                            --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdRetencionS    @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END
--SELECT 'spCfdInCfdTraslado'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Trasladado                                                                            --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdTraslado     @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END

--SELECT 'spCfdInRetenido'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de Retenido                                                                              --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdRetenido     @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END


--SELECT 'spCfdInCfdImpLocal'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación de ImpLocal                                                                              --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      EXEC spCfdInCfdImpLocal     @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                  @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
      IF   @b_error_cfdi  =  @k_verdadero 
      BEGIN
        INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
        SET  @pBError      = @k_verdadero
	  END
    END
----------------------------------------------------------------------------------------------------------------------
-- Verificación para proceso de Pagos (Tipo P)                                                                                   --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      IF  @tipo_comprob  =  @k_pago
      BEGIN
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación PagoS                                                                                    --
----------------------------------------------------------------------------------------------------------------------
--SELECT 'spCfdInCfdPagoS'
        IF   @b_error_cfdi  =  @k_falso 
	    BEGIN
          EXEC spCfdInCfdPagoS       @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                     @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
          IF   @b_error_cfdi  =  @k_verdadero 
          BEGIN
            INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
            SET  @pBError      = @k_verdadero
	      END
        END
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación Pago                                                                                     --
----------------------------------------------------------------------------------------------------------------------
        IF   @b_error_cfdi  =  @k_falso 
	    BEGIN
          EXEC spCfdInCfdPago        @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                     @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
          IF   @b_error_cfdi  =  @k_verdadero 
          BEGIN
            INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
            SET  @pBError      = @k_verdadero
	      END
        END
--SELECT 'spCfdInCfdPagoRelac'
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación PagoRelac                                                                                     --
----------------------------------------------------------------------------------------------------------------------
        IF   @b_error_cfdi  =  @k_falso 
	    BEGIN
          EXEC spCfdInCfdPagoRelac   @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                   @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
          IF   @b_error_cfdi  =  @k_verdadero 
          BEGIN
            INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
            SET  @pBError      = @k_verdadero
	      END
        END
      END
    END
----------------------------------------------------------------------------------------------------------------------
-- Verificación para proceso de Pagos (Tipo E)                                                                      --
----------------------------------------------------------------------------------------------------------------------
    IF   @b_error_cfdi  =  @k_falso 
	BEGIN
      IF  @tipo_comprob  =  @k_egreso
      BEGIN
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación RelacionadoS                                                                             --
----------------------------------------------------------------------------------------------------------------------
        IF   @b_error_cfdi  =  @k_falso 
	    BEGIN
          EXEC spCfdInCfdRelacionadoS  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                       @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
          IF   @b_error_cfdi  =  @k_verdadero 
          BEGIN
            INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
            SET  @pBError      = @k_verdadero
	      END
        END
----------------------------------------------------------------------------------------------------------------------
-- Carga de la infromación Relacionado                                                                              --
----------------------------------------------------------------------------------------------------------------------
        IF   @b_error_cfdi  =  @k_falso 
	    BEGIN
          EXEC spCfdInCfdRelacionado  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @pFolioExe,
                                      @pIdTarea, @hdoc, @uuid, @pCveTipo, @b_error_cfdi OUT, @pError OUT, @pMsgError OUT
          IF   @b_error_cfdi  =  @k_verdadero 
          BEGIN
            INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
            SET  @pBError      = @k_verdadero
	      END
        END
      END
    END
    
    EXEC sp_xml_removedocument @hDoc

  END

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) Carga CFDI ' + @pNomArchivo + ' ' + isnull(@seccion, 'nulo') 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    INSERT INTO #TvpError  VALUES (@k_error, @pError, @pMsgError)
	SET  @pBError  =  @k_verdadero
  END CATCH

END

