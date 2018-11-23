USE ADMON01
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC spCreaBalaza N'C:\TEMP 2017\BALANZA.CSV'

ALTER PROCEDURE [dbo].[spObtCampo]  @pRowBalanzai VARCHAR(max), @pTipoCampo VARCHAR(1), 
                                       @pCampo VARCHAR(50) OUT, 
                                       @pRowBalanzao VARCHAR(max) OUT
AS
BEGIN


  DECLARE @b_despliega  bit
  
  DECLARE  @posicion         int
          
  DECLARE  @k_delimitador    varchar(1),
           @k_falso          bit,
           @k_verdadero      bit,
		   @k_numero         varchar(1),
		   @k_caracter       varchar(1)

  SET  @posicion       =  0
 
  SET  @k_verdadero    =  1
  SET  @k_falso        =  0
  SET  @k_delimitador  =  ','
  SET  @k_numero       =  'N'
  SET  @k_caracter     =  'C'
  
  SET @b_despliega = 1  
  

  IF  SUBSTRING(@pRowBalanzai,1,1) = char(34)
  BEGIN
	SET @k_delimitador = char(34)
	SET @pRowBalanzai  = SUBSTRING(@pRowBalanzai,2,LEN(@pRowBalanzai))
	SET @posicion    = charindex(char(34), @pRowBalanzai)
	SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowBalanzai,1,@posicion - 1)))
	SET @pRowBalanzao  = SUBSTRING(@pRowBalanzai,@posicion + 2,LEN(@pRowBalanzai))
  END
  ELSE
  BEGIN
	SET @k_delimitador = ','
	SET @posicion    = charindex(@k_delimitador, @pRowBalanzai)
	SET @pCampo = RTRIM(LTRIM(SUBSTRING(@pRowBalanzai,1,@posicion- 1)))
	SET @pRowBalanzao  = SUBSTRING(@pRowBalanzai,@posicion + 1,LEN(@pRowBalanzai))
  END
  
  IF  @pTipoCampo  =  @k_numero
  BEGIN 
    SET @pCampo  =  isnull(@pCampo,0)
    SET @pCampo  =  REPLACE(@pCampo,' ','0')
	SET @pCampo  =  REPLACE(@pCampo,',','')
  END


END
