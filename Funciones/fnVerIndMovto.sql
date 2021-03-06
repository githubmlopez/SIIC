USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnVerIndMovto] (@pCveEmpresa varchar(4), @pCveIndicador varchar(10), @pCveChequera varchar(6),
                                       @pCveTipoMovto varchar(6), @pSitConciliaBanco varchar(2))
RETURNS bit
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @NunRegistros        int, 
           @RowCount            int,
		   @b_resultado         bit  =  0,
		   @cve_tipo_movto      varchar(6),
		   @sit_concilia_banco  varchar(2)

  DECLARE  @k_verdadero         bit  =  1,
           @k_falso             bit  =  0,
		   @k_no_aplica         varchar(2)  =  'NA'

  DECLARE  @TIndMovto      TABLE
          (RowID           int  identity(1,1),
           CVE_TIPO_MOVTO       varchar(6),
		   SIT_CONCILIA_BANCO   varchar(2))

  INSERT @TIndMovto (CVE_TIPO_MOVTO, SIT_CONCILIA_BANCO)  
  SELECT CVE_TIPO_MOVTO, SIT_CONCILIA_BANCO  FROM CI_IND_MOVIMIENTO  WHERE
  CVE_EMPRESA    =  @pCveEmpresa    AND
  CVE_INDICADOR  =  @pCveIndicador  AND
  CVE_CHEQUERA   =  @pCveChequera   AND
  CVE_TIPO_MOVTO =  @pCveTipoMovto     

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  IF  @NunRegistros  =  0
  BEGIN
    SET  @b_resultado  =  @k_falso
  END
  ELSE
  BEGIN
    WHILE @RowCount <= @NunRegistros
    BEGIN
      SELECT @cve_tipo_movto = CVE_TIPO_MOVTO, @sit_concilia_banco = SIT_CONCILIA_BANCO FROM @TIndMovto
      IF  @sit_concilia_banco  =   @k_no_aplica  
	  BEGIN
	    SET  @b_resultado  =  @k_verdadero
		SET @RowCount = @NunRegistros
	  END
      ELSE
	  BEGIN
        IF  SUBSTRING(@sit_concilia_banco,1,1)  =   SUBSTRING(@pSitConciliaBanco,1,1)  
	    BEGIN
	      SET  @b_resultado  =  @k_verdadero
		  SET @RowCount = @NunRegistros
	    END
	  END
      SET @RowCount = @RowCount + 1
    END
  END
  RETURN  @b_resultado
END

