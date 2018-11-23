USE ADMON01
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC spCargaBalaza 'CU', '201803' 

CREATE PROCEDURE [dbo].[spCargaBalaza] @pCveEmpresa varchar(4), @pAnoMes varchar(6)
AS
BEGIN

  CREATE TABLE #BALANZAP 
  (RowBalanza     varchar(500))

  CREATE TABLE #BALANZA 
  (id_renglon     int identity,
   RowBalanza     varchar(500))

  CREATE TABLE #BAL_EXTRAC
  (cuenta         varchar(100),
   nom_cliente    varchar(100),
   sdo_inicial    numeric(12,2),
   imp_cargos     numeric(12,2),
   imp_abonos     numeric(12,2),
   sdo_final      numeric(12,2))

  CREATE TABLE #PARAMETRO
  (paths          varchar(50),
   inicio         int,
   fin            int,
   num_campos     int,
   type_campos    varchar(6)) 

  DECLARE @paths        varchar(50),
          @inicio       int,
          @fin          int,
          @num_campos   int,
          @type_campos  varchar(6) 

  DECLARE @b_despliega  bit,
          @tipo_campo   varchar(1)

  DECLARE  @rowbalanza       varchar(500),
           @rowbalanzao      varchar(500),
           @cuenta           varchar(100),
           @nom_cliente      varchar(100),
		   @sdo_inicial      varchar(100),
    	   @imp_cargos       varchar(100),
		   @imp_abonos       varchar(100),
		   @sdo_final        varchar(100)

  DECLARE  @posicion         int,
           @sql              varchar(max),
		   @cont_campo       int
         
  DECLARE  @k_posic_valida   varchar(1),
           @k_delimitador    varchar(1),
           @k_falso          bit,
           @k_verdadero      bit,
		   @k_abierto        varchar(1)  =  'A'
		   @k_automatica     varchar(2)  =  'AU'
		   @k_pendiente      varchar(1)  =  'P'

  SET  @posicion       =  0
 
  SET  @k_posic_valida = '-'
  SET  @k_verdadero    =  1
  SET  @k_falso        =  0
  SET  @k_delimitador  =  ','
  
  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA  WHERE CVE_EMPRESA  =  @pCveEmpresa   AND  ANO_MES  =  @pAnoMes)  =  @k_abierto
  BEGIN
    DELETE  FROM CI_BALANZA_OPERATIVA  WHERE  ANO_MES  =  @pAnoMes
  END

  INSERT INTO #PARAMETRO (paths, inicio, fin, num_campos, type_campos) 
 (SELECT
  XMLSource.value('(Parametros/Path)[1]', 'VARCHAR(max)') as path,
  XMLSource.value('(Parametros/Inicio)[1]', 'INT') as inicio,
  XMLSource.value('(Parametros/Fin)[1]', 'INT') as fin,
  XMLSource.value('(Parametros/NumCampos)[1]', 'INT') as numcampos,
  XMLSource.value('(Parametros/TypeCampos)[1]', 'VARCHAR(6)') as typecampos
  FROM (
    SELECT bulkColumn,
    cast(bulkcolumn as XML)  as XMLSource
    FROM OPENROWSET(BULK 'C:\ERP 01\Configuracion\XML\Contabilidad\EXTBALANZA.xml',SINGLE_BLOB)
    AS servers
    ) as T1)

  SELECT @paths        = paths,
         @inicio      = inicio,
         @fin         = fin,
         @num_campos  = num_campos,
         @type_campos = type_campos
  FROM #PARAMETRO

  SET  @sql  =  
  'BULK INSERT #BALANZAP FROM ' + char(39) + @paths + char(39) + ' WITH (DATAFILETYPE =' + char(39) + 'CHAR' + char(39) +
  ',' + 'CODEPAGE = ' + char(39) + 'ACP' + char(39) + ')'

  EXEC(@sql)

  SELECT @sql

 -- SELECT ' ORIGINAL '
 -- SELECT * FROM #BALANZAP

  INSERT INTO #BALANZA (RowBalanza) 
  SELECT RowBalanza FROM #BALANZAP
--  SELECT * FROM #BALANZAP 

--  SELECT ' IDENTITY '

--  SELECT * FROM #BALANZA

  IF  @inicio  <>  0
  BEGIN
    DELETE FROM #BALANZA WHERE id_renglon < @inicio OR id_renglon > @fin 
  END

  INSERT INTO #BALANZAP (RowBalanza) 
  SELECT RowBalanza FROM #BALANZAP
 -- SELECT * FROM #BALANZA  

--  SELECT ' DEPURADO '

  
--  SELECT * FROM #BALANZA

  -- CHAR(10) Nueva Línea (LF)    CHAR(13) Control de Carro (CR)

  UPDATE #BALANZA SET RowBalanza = REPLACE(RowBalanza,CHAR(13),' ')
  UPDATE #BALANZA SET RowBalanza = REPLACE(RowBalanza,CHAR(10),' ')

  SET @rowbalanza   = ' '

  DECLARE balanza_cursor CURSOR FOR SELECT RowBalanza FROM #BALANZA
  OPEN balanza_cursor

  FETCH balanza_cursor INTO @rowbalanza 

  SET @b_despliega = 1  

  WHILE (@@fetch_status = 0 )
  BEGIN

    SET @cont_campo  =  0
    SET @cuenta  =  ' '
	SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @cuenta OUT, 
                                  @rowbalanzao OUT

	SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
    SET  @rowbalanza  =  @rowbalanzao

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @nom_cliente OUT, 
                                  @rowbalanzao OUT

    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowbalanza  =  @rowbalanzao

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @sdo_inicial OUT, 
                                  @rowbalanzao OUT
	
    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowbalanza  =  @rowbalanzao

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @imp_cargos OUT, 
                                  @rowbalanzao OUT

    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowbalanza  =  @rowbalanzao

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @imp_abonos OUT, 
                                  @rowbalanzao OUT

    SET @cont_campo  =  @cont_campo + 1
	SET  @tipo_campo = SUBSTRING(@type_campos,@cont_campo,1)
	SET  @rowbalanza  =  @rowbalanzao

    EXEC spObtCampo  @rowbalanza, @tipo_campo, 
                                  @sdo_final OUT, 
                                  @rowbalanzao OUT

    BEGIN TRY

    IF  NOT EXISTS (SELECT 1 FROM CI_CAT_CTA_CONT WHERE CVE_EMPRESA = @pCveEmpresa AND CTA_CONTABLE = @cuenta)
	BEGIN
	  INSERT CI_CAT_CTA_CONT (CVE_EMPRESA, CTA_CONTABLE, DESC_CTA_CONT, CVE_REFERENCIA, SIT_CUENTA) VALUES
	                         (@pCveEmpresa, @cuenta, @nom_cliente, @k_automatica, @k_pendiente)
	END  

	INSERT INTO CI_BALANZA_OPERATIVA
	           (CVE_EMPRESA,
			    ANO_MES,
				CTA_CONTABLE,
				SDO_INICIAL,
				IMP_CARGO,
				IMP_ABONO,
				SDO_FINAL,
				SDO_INICIAL_C,
				IMP_CARGO_C,
				IMP_ABONO_C,
				SDO_FINAL_C,
				B_BALANZA)
	VALUES     (
	            @pCveEmpresa,
				@pAnoMes,
				@cuenta, 
	            CONVERT(NUMERIC(12,2),@sdo_inicial),
	            CONVERT(NUMERIC(12,2),@imp_cargos),
			    CONVERT(NUMERIC(12,2),@imp_abonos),
			    CONVERT(NUMERIC(12,2),@sdo_final),
				0,
				0,
				0,
				0,
				@k_verdadero) 

    FETCH balanza_cursor INTO  @rowbalanza
  END            

--  SELECT * FROM #BALANZA
  close balanza_cursor

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE balanza_cursor
      DEALLOCATE balanza_cursor
 
    IF object_id('tempdb..#BALANZA') IS NOT NULL 
    BEGIN
      DROP TABLE #BALANZA
    END
    IF object_id('tempdb..#BALANZA') IS NOT NULL 
    BEGIN
      DROP TABLE #BALANZA
    END
    IF object_id('tempdb..#BAL_EXTRAC') IS NOT NULL 
    BEGIN
      DROP TABLE #BAL_EXTRAC
    END

    SET  @pError    =  'Error de Ejecucion Proceso Transacciones Facturacion'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END
