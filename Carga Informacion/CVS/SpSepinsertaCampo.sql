USE [CARGADOR]
GO
/****** Calcula dias de vacaciones del Empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'SpSeparaCampos')
BEGIN
  DROP  FUNCTION SpSeparaCampos
END
GO
--EXEC  SpSepinsertaCampo 5, ',', 
CREATE PROCEDURE [dbo].[SpSepinsertaCampo]  
(
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pTipoInfo       int,
@pIdBloque       int,
@pNumCampos      int,
@pCarSeparador   varchar(1),
@pRowFile        varchar(max)
)
AS
BEGIN
  DECLARE  @NunRegistros  int          = 0, 
		   @num_columna   int          = 0,
           @campo         varchar(max) = ' ',
		   @tipo_Campo    varchar(1)
		   

  DECLARE  @k_verdadero   bit        = 1,
		   @k_falso       bit        = 1,
		   @k_numero      varchar(1) = 'N'

------------------------------------------------------------------------------
-- Campos separados
-------------------------------------------------------------------------------

  DECLARE  @TCampo    TABLE
          (RowId       int identity,
           Campo       varchar(max))

  INSERT INTO @TCampo
  SELECT * FROM STRING_SPLIT (@pRowFile, @pCarSeparador)   
  SET  @num_columna  =  1
  WHILE @pNumCampos >=  @num_columna 
  BEGIN
    SELECT @campo   =  Campo FROM  @TCampo

    SELECT @tipo_campo = CVE_TIPO_CAMPO
	FROM  FC_CARGA_POSIC  WHERE 
	ID_CLIENTE        = @pIdCliente  AND
    CVE_EMPRESA       = @pCveEmpresa AND
    TIPO_INFORMACION  = @pTipoInfo   AND
    ID_BLOQUE         = @pIdBloque   AND
	NUM_COLUMNA       = @num_columna  

    IF  @tipo_Campo   =  @k_numero
    BEGIN 
      SET @pRowFile   =  isnull(@campo,0)
      SET @pRowFile   =  REPLACE(@campo,' ','0')
      SET @pRowFile   =  REPLACE(@campo,',','')
      SET @pRowFile   =  REPLACE(@campo,'$','')
    END
    SET  @num_columna  =  @num_columna + 1
  END
  
END

