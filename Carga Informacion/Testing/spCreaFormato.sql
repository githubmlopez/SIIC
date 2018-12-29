USE [CARGADOR]
GO
/****** Crea Formato para carga ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spCreaFormato')
BEGIN
  DROP  PROCEDURE spCreaFormato
END
GO
--EXEC spCreaFormato 2,1,'MARIO',1,'CU','CARGADOR','NO_EMPLEADO',' ',' ' 
CREATE PROCEDURE [dbo].[spCreaFormato] 
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pTabla           varchar(15),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_csv             varchar(3)  =  'CSV',
		   @k_tipo_periodo    varchar(1)  =  'D',
  		   @k_pos_ini_eof     varchar(4)  =  'PIEF',
		   @k_entero          varchar(3)  =  'int',
		   @k_numerico        varchar(7)  =  'numeric',
		   @k_varchar         varchar(7)  =  'varchar',
		   @k_nvarchar        varchar(8)  =  'nvarchar',
		   @k_decimal         varchar(7)  =  'decimal',
		   @k_bit             varchar(3)  =  'bit',
		   @k_date            varchar(4)  =  'date',
		   @k_date_time       varchar(8)  =  'datetime',
		   @k_numero          varchar(1)  =  'N',
		   @k_caracter        varchar(1)  =  'C',
		   @k_fecha           varchar(1)  =  'D',
 		   @k_car_err         varchar(1)  =  'E'
  
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
           @formato           int,
           @nom_archivo       varchar(30),
		   @desc_archivo      varchar(30),
		   @path              varchar(50),
		   @num_carac         varchar(1),
		   @num_campos        int

  DECLARE  @nom_tabla         varchar(30),
		   @nom_campo         varchar(30),
		   @tipo_campo        varchar(20),
		   @longitud          int,
		   @enteros           int,
		   @decimales         int,
		   @posicion          int,
		   @b_nulo            bit,
		   @b_identity        bit

  DECLARE  @sql               nvarchar(max)

  SELECT @nom_archivo = NOM_TABLA, @desc_archivo = DESC_TABLA, @formato = CONVERT(INT,SINONIMO)
         FROM DICDATOS.dbo.FC_TABLA_EX 
		 WHERE NOM_TABLA = @pTabla


  DELETE FROM FC_CARGA_POSIC  WHERE ID_CLIENTE  = @pIdCliente   AND
                                        CVE_EMPRESA = @pCveEmpresa  AND
								        ID_FORMATO  = @formato


  DELETE FROM FC_CARGA_RENG_ENCA  WHERE ID_CLIENTE  = @pIdCliente   AND
                                        CVE_EMPRESA = @pCveEmpresa  AND
								        ID_FORMATO  = @formato

  DELETE FROM FC_FORMATO  WHERE ID_CLIENTE    = @pIdCliente   AND
                                CVE_EMPRESA   = @pCveEmpresa  AND
								ID_FORMATO    = @formato
  INSERT INTO  FC_FORMATO 
  (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  CVE_TIPO_ARCHIVO,
  DESC_ARCHIVO,
  NOM_ARCHIVO,
  CVE_TIPO_PERIODO,
  PATHS
  )
  VALUES
  (
  @pIdCliente,
  @pCveEmpresa,
  @formato,
  @k_csv,
  @desc_archivo,
  @nom_archivo,
  @k_tipo_periodo,
  @path
  )

  SET  @num_campos  =
 (SELECT COUNT(*) FROM  DICDATOS.dbo.FC_TABLA_COLUMNA
  WHERE  NOM_TABLA  =  @pTabla)

  INSERT INTO  FC_CARGA_RENG_ENCA 
  (
  ID_CLIENTE,
  CVE_EMPRESA,
  ID_FORMATO,
  ID_BLOQUE,
  NUM_RENG_INI,
  NUM_RENG_FIN,
  NUM_CAMPOS,
  CADENA_FIN,
  CVE_TIPO_BLOQUE,
  NUM_RENG_D_CAD,
  CADENA_ENCA
  )
  VALUES
  (
  @pIdCliente,
  @pCveEmpresa,
  @formato,
  1,
  1,
  0,
  @num_campos,
  ' ',
  @k_pos_ini_eof,
  0,
  ' '
  )


-------------------------------------------------------------------------------
-- Carga de la tabla FC_CARGA_POSIC
-------------------------------------------------------------------------------

  DECLARE  @TColumna       TABLE
          (RowID            int  identity(1,1),
		   NOM_TABLA        varchar(30),
		   NOM_CAMPO        varchar(30),
		   TIPO_CAMPO       varchar(20),
		   LONGITUD         int,
		   ENTEROS          int,
		   DECIMALES        int,
		   POSICION         int,
		   B_NULO           bit,
		   B_IDENTITY       bit)
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TColumna  (NOM_TABLA,NOM_CAMPO,TIPO_CAMPO,LONGITUD,ENTEROS,DECIMALES,POSICION,
		             B_NULO,B_IDENTITY)  
  SELECT NOM_TABLA,NOM_CAMPO,TIPO_CAMPO,LONGITUD,ENTEROS,DECIMALES,POSICION,
		 B_NULO,B_IDENTITY  FROM  DICDATOS.dbo.FC_TABLA_COLUMNA
  WHERE  NOM_TABLA  =  @pTabla
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @nom_tabla = NOM_TABLA, @nom_campo = NOM_CAMPO, @tipo_campo = TIPO_CAMPO,
	       @longitud = LONGITUD, @enteros = ENTEROS, @decimales = DECIMALES,
		   @posicion = POSICION, @b_nulo = B_NULO, @b_identity = B_IDENTITY
		   FROM @TColumna
	WHERE  RowID  =  @RowCount

	IF  @tipo_campo IN (@k_entero, @k_numerico, @k_decimal, @k_bit)
	BEGIN
	  SET @num_carac = @k_numero
	END
	ELSE
	BEGIN
      IF  @tipo_campo IN (@k_varchar, @k_nvarchar)
	  BEGIN
	    SET @num_carac = @k_caracter
	  END
      ELSE
	  BEGIN
        IF  @tipo_campo IN (@k_date, @k_date_time)
        BEGIN
	      SET @num_carac = @k_fecha
        END
        ELSE
		BEGIN
          SET @num_carac = @k_car_err
		END
	  END
	END

	INSERT INTO FC_CARGA_POSIC 
	(ID_CLIENTE,
	 CVE_EMPRESA,
	 ID_FORMATO,
	 ID_BLOQUE,
	 NUM_COLUMNA,
	 POS_INICIAL,
	 POS_FINAL,
	 DESC_CAMPO,
	 CVE_TIPO_CAMPO) VALUES
	(@pIdCliente,
     @pCveEmpresa,
	 @formato,
	 1,
	 @posicion,
	 0,
	 0,
	 @nom_campo,
     @num_carac)

	SET @RowCount     =  @RowCount + 1
  END
END