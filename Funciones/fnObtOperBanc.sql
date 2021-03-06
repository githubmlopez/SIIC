USE [ADMON01]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtOperBanc')
BEGIN
  DROP  FUNCTION dbo.fnObtOperBanc
END
GO
CREATE FUNCTION [dbo].[fnObtOperBanc] 
(
@pTipoInfo     int,
@pPosIni       int,
@pPosFin       int,
@pCargAbono    varchar(1),
@pDescripcion  varchar(250)
)
RETURNS varchar(7)						  
AS
BEGIN

  DECLARE  @cve_operacion    varchar(7),
           @prim_palabra     varchar(30),
		   @b_posicion       bit = 0,
		   @b_palabra        bit = 0,
		   @b_like           bit = 0,
		   @b_default        bit = 0

  DECLARE  @k_verdadero      bit         =  1,
 		   @k_cargo          varchar(1)  =  'C',
		   @k_abono          varchar(1)  =  'A',
		   @k_no_aplica      int         =  0,
		   @k_posicion       varchar(1)  =  'P',
		   @k_prim_palabra   varchar(1)  =  'B',
		   @k_like           varchar(1)  =  'L',
		   @k_default        varchar(1)  =  'D',
		   @k_clave          varchar(1)  = 'C'

  IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
     TIPO_INFORMACION  =  @pTipoInfo    AND
     CVE_CARG_ABONO    =  @pCargAbono AND
	 TIPO_BUSQUEDA     =  @k_posicion)
  BEGIN
    IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
    TIPO_INFORMACION   =  @pTipoInfo     AND
    CVE_CARG_ABONO     =  @pCargAbono  AND
	TIPO_BUSQUEDA      =  @k_posicion  AND
    SUBSTRING(VALOR,@pPosIni, @pPosFin) =  SUBSTRING(@pDescripcion,@pPosIni, @pPosFin))
	BEGIN
	  SET @cve_operacion  =  @k_clave +
	 (SELECT TOP(1) CVE_TIPO_MOVTO FROM CI_OPER_BANCARIA  WHERE
      TIPO_INFORMACION =  @pTipoInfo    AND
      CVE_CARG_ABONO   =  @pCargAbono AND
	  TIPO_BUSQUEDA    =  @k_posicion AND
      SUBSTRING(VALOR,@pPosIni, @pPosFin) =  SUBSTRING(@pDescripcion,@pPosIni, @pPosFin))
      SET  @b_posicion  =  @k_verdadero
    END
  END  

  IF  @b_posicion  <>  @k_verdadero
  BEGIN

  IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
     TIPO_INFORMACION  =  @pTipoInfo    AND
     CVE_CARG_ABONO    =  @pCargAbono AND
	 TIPO_BUSQUEDA     =  @k_prim_palabra)
  BEGIN
     SET  @prim_palabra = SUBSTRING (@pDescripcion, 1, CHARINDEX(' ', @pDescripcion))
     IF EXISTS (SELECT 1 CVE_TIPO_MOVTO FROM CI_OPER_BANCARIA  WHERE
     TIPO_INFORMACION  =  @pTipoInfo        AND
     CVE_CARG_ABONO    =  @pCargAbono     AND
	 TIPO_BUSQUEDA     =  @k_prim_palabra AND
     VALOR             =  @prim_palabra)
	 BEGIN
	   SET @cve_operacion  = @k_clave +
	  (SELECT TOP(1) CVE_TIPO_MOVTO FROM CI_OPER_BANCARIA  WHERE
       TIPO_INFORMACION  =  @pTipoInfo        AND
       CVE_CARG_ABONO    =  @pCargAbono     AND
	   TIPO_BUSQUEDA     =  @k_prim_palabra AND
       VALOR             =  @prim_palabra)
       SET  @b_palabra   =  @k_verdadero
     END
  END
  END

  IF  @b_posicion  <>  @k_verdadero  AND  @b_palabra  <>  @k_verdadero
  BEGIN

  IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
     TIPO_INFORMACION  =  @pTipoInfo    AND
     CVE_CARG_ABONO    =  @pCargAbono AND
	 TIPO_BUSQUEDA     =  @k_like)
  BEGIN
    IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
    TIPO_INFORMACION =  @pTipoInfo        AND
    CVE_CARG_ABONO   =  @pCargAbono     AND
	TIPO_BUSQUEDA    =  @k_like         AND
    @pDescripcion  LIKE '%' + LTRIM(RTRIM(VALOR)) + '%')
	BEGIN
	  SET @cve_operacion  = @k_clave +
	 (SELECT TOP(1) CVE_TIPO_MOVTO FROM CI_OPER_BANCARIA  WHERE
      TIPO_INFORMACION  =  @pTipoInfo        AND
      CVE_CARG_ABONO    =  @pCargAbono     AND
	  TIPO_BUSQUEDA     =  @k_like         AND
      @pDescripcion  LIKE '%' + LTRIM(RTRIM(VALOR)) + '%')
      SET  @b_like      =  @k_verdadero
    END
  END
  END

  IF  @b_posicion  <>  @k_verdadero  AND  @b_palabra  <>  @k_verdadero  AND @b_like  <>  @k_verdadero
  BEGIN

  IF EXISTS (SELECT 1 FROM CI_OPER_BANCARIA  WHERE
     TIPO_INFORMACION  =  @pTipoInfo    AND
     CVE_CARG_ABONO    =  @pCargAbono AND
	 TIPO_BUSQUEDA     =  @k_default)
  BEGIN
    SET @cve_operacion  = @k_default +
   (SELECT TOP(1) CVE_TIPO_MOVTO FROM CI_OPER_BANCARIA  WHERE
    TIPO_INFORMACION  =  @pTipoInfo      AND
    CVE_CARG_ABONO    =  @pCargAbono     AND
	TIPO_BUSQUEDA     =  @k_default) 
    SET  @b_default   =  @k_verdadero
  END
  END

  IF  @b_posicion  <>  @k_verdadero  AND  @b_palabra  <>  @k_verdadero and @b_like  <>  @k_verdadero AND
      @b_default   <>  @k_verdadero
  BEGIN
    SET  @cve_operacion = ' '
  END
  
  RETURN(@cve_operacion)
END

