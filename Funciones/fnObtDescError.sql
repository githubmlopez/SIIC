USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET NOCOUNT ON
GO
alter FUNCTION [dbo].[fnObtDescError] (@pBaseDatos varchar(10), @pNumError varchar(4), @pIdioma varchar(5), 
                                        @pCveTipoEntidad varchar(5), @pCveEntidad varchar(20), @pCveEtiqueta varchar(20),
										@pEtiqueta varchar(50))
RETURNS varchar(80)
AS
BEGIN
  DECLARE  @k_no_dato varchar(1)  =  ' '

  DECLARE  @desc_error  varchar(80),
           @etiqueta    varchar(50)

  IF  ISNULL(@pCveTipoEntidad, @k_no_dato)  =  @k_no_dato
  BEGIN
    SET @etiqueta  =  @k_no_dato
  END
  ELSE
  BEGIN
    IF  EXISTS (SELECT 1 FROM INF_ETIQUETA WHERE 
        BASE_DATOS       = @pBaseDatos      AND
	    CVE_TIPO_ENTIDAD = @pCveTipoEntidad AND
	    CVE_ENTIDAD      = @pCveEntidad     AND
	    CVE_IDIOMA       = @pIdioma         AND
	    CVE_ETIQUETA     = @pCveEtiqueta)
    BEGIN
	  SET  @etiqueta  =
	  (SELECT SUBSTRING(TX_ETIQUETA,1,30) FROM INF_ETIQUETA WHERE 
        BASE_DATOS       = @pBaseDatos      AND
	    CVE_TIPO_ENTIDAD = @pCveTipoEntidad AND
	    CVE_ENTIDAD      = @pCveEntidad     AND
	    CVE_IDIOMA       = @pIdioma         AND
	    CVE_ETIQUETA     = @pCveEtiqueta)
	END
    ELSE
	BEGIN
	  SET @etiqueta  =  ISNULL(@pEtiqueta, @k_no_dato)
-- 	  SET @etiqueta  =  'No existe'

	END
  END

  IF  EXISTS(SELECT 1 FROM FC_MSG_ERROR WHERE 
             NUM_ERROR  =  @pNumError   AND
			 CVE_IDIOMA =  @pIdioma)
  BEGIN
    SET  @desc_error  =  (SELECT DESC_ERROR FROM FC_MSG_ERROR WHERE 
                          NUM_ERROR  =  @pNumError  AND
			              CVE_IDIOMA =  @pIdioma)
  END
  ELSE
  BEGIN
    SET @desc_error  = 'ERROR?????'
  END
    
  SET  @desc_error =  LTRIM(REPLACE (@desc_error,'@',@etiqueta))
  RETURN @desc_error
END

