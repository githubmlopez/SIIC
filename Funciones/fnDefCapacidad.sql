USE [INFRA]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnDefCapacidad')
BEGIN
  DROP  FUNCTION fnDefCapacidad
END
GO
ALTER FUNCTION [dbo].[fnDefCapacidad] 
(
@pCveAplicacion varchar(10), @pCve_forma varchar(20), @pCvePerfil varchar(20), @pCveCapacidad varchar(50), @pValorCapacidad bit, @pCveFormaDet varchar(1),
@NomCampo varchar(30)
)
RETURNS bit
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @k_forma   varchar(1) = 'F',
           @k_Detalle varchar(1) = 'D',
		   @resultado bit
  
  IF  @pCveFormaDet  =  @k_forma
  BEGIN
    IF EXISTS (SELECT 1 FROM FC_SEG_PERFIL_FORMA  WHERE  CVE_APLICACION = @pCveAplicacion AND CVE_FORMA = @pCve_forma AND 
	                                                     CVE_PERFIL = @pCvePerfil  AND CVE_CAPACIDAD = @pCveCapacidad)
	BEGIN
      SET @resultado =  0
	END
	ELSE
	BEGIN
	  SET @resultado = @pValorCapacidad
	END
  
  END
  ELSE
  BEGIN
    IF @pCveFormaDet  =  @k_Detalle
    BEGIN
      IF EXISTS (SELECT 1 FROM FC_SEG_PERFIL_CAMPO  WHERE  CVE_APLICACION = @pCveAplicacion AND CVE_FORMA = @pCve_forma AND  NOM_CAMPO = @NomCampo AND 
	                                                       CVE_PERFIL = @pCvePerfil  AND CVE_CAPACIDAD = @pCveCapacidad)
	  BEGIN
        SET @resultado = 0
	  END
	  ELSE
	  BEGIN
	    SET @resultado =  @pValorCapacidad
	  END
  
    END
  END
  RETURN @resultado
END

