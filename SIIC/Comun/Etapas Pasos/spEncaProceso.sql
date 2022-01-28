USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spEncaProceso')
BEGIN
  DROP  PROCEDURE spEncaProceso
END
GO
-- EXEC spEncaProceso 1,'EGG','MARIO','SIIC',1,1,'202109',0,0,' ',' '

CREATE PROCEDURE [dbo].[spEncaProceso]  
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pIdEtapa         int,
@pIdPaso          int,
@pPeriodo         varchar(10),
@pFolioExe        int          OUT,
@pBError          bit          OUT,
@pError           varchar(80)  OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE @k_falso         bit  =  0,
          @k_verdadero     bit  =  1,
		  @k_warning       varchar(1)  =  'W',
		  @k_error         varchar(1)  =  'ER',
		  @k_correcto      varchar(2)  =  'CO',
		  @k_pendiente     varchar(2)  =  'PE'

  DECLARE @TProcMonitor TABLE (
          RowID            int IDENTITY(1, 1) NOT NULL, 
          CVE_EMPRESA      varchar(4),
		  ID_PROCESO       numeric(9),
		  NOM_PROCESO      varchar(50),
		  BASE_DATOS       varchar(20),
		  OWNER            varchar(20),
		  STORE_PROCEDURE  varchar(50)
   )
 
  DECLARE  @NunRegistros     int, 
           @RowCount         int

  DECLARE  @cve_empresa      varchar(4),
           @id_proceso       numeric(9),
		   @nom_proceso      varchar(50),
           @base_datos       varchar(20),
		   @owner            varchar(20),
		   @store_procedure  varchar(50)

  DECLARE  @id_tarea         numeric(9,0),
           @f_operacion      date,
		   @hora_inicio      varchar(10),
		   @hora_fin         varchar(10),
           @folio_exec       int,
           @sit_proceso      varchar(2),
           @num_reg_tran     int,
		   @b_error_int      bit,
		   @error_int        varchar(80),
		   @msg_error_int    varchar(80),
		   @b_val_periodo    bit

---------------------------

  SET  @b_val_periodo  =  @k_verdadero

  IF OBJECT_ID('tempdb..#PROCESO') IS NULL
  BEGIN
    CREATE TABLE #PROCESO 
   ( 
	RowID           int IDENTITY(1,1) NOT NULL,
    ID_ETAPA        int,
    ID_PASO         int,
    ID_PROCESO      numeric(9),
    SIT_EXEC        varchar(2),
	SEC_PROCESO     varchar(2)
   )
  END

-- En caso de no existir los registros de ETAPA/PASO del periodo los crea

  IF NOT EXISTS (SELECT 1 FROM FC_ETAPA_PERIODO WHERE  PERIODO  =  @pPeriodo  AND  CVE_EMPRESA = @pCveEmpresa  AND  ID_ETAPA  =  @pIdEtapa)
  BEGIN
    INSERT  FC_ETAPA_PERIODO  (PERIODO, CVE_EMPRESA, ID_ETAPA, SIT_ETAPA_PER) VALUES
	                          (@pPeriodo,@pCveEmpresa,@pIdEtapa, @k_pendiente)
  END

  IF NOT EXISTS (SELECT 1 FROM  FC_PASO_PERIODO WHERE  PERIODO  =  @pPeriodo  AND  CVE_EMPRESA = @pCveEmpresa  AND  ID_ETAPA  =  @pIdEtapa  AND
                                                           ID_PASO  =  @pIdPaso)
  BEGIN
    INSERT  FC_PASO_PERIODO  (PERIODO, CVE_EMPRESA, ID_ETAPA, ID_PASO, SIT_PASO_PER) VALUES
	                         (@pPeriodo,@pCveEmpresa,@pIdEtapa, @pIdPaso, @k_pendiente)
  END
 
  -- Actualiza Tabla TEMPORAL con la información de los procesos a ejecutar
  EXEC spObtProcPaso  
  @pCveEmpresa, 
  @pIdCliente,
  @pCodigoUsuario,
  @pCveAplicacion,
  @pPeriodo,
  @pIdEtapa,
  @pIdPaso,
  @pBError,
  @pError     OUT,
  @pMsgError  OUT

  IF  @pBError  =  @k_verdadero AND ISNULL(@pMsgError, ' ') <> ' '
  BEGIN
    RETURN
  END

  INSERT  @TProcMonitor (CVE_EMPRESA, ID_PROCESO, NOM_PROCESO, BASE_DATOS, OWNER, STORE_PROCEDURE)
  SELECT p.CVE_EMPRESA, p.ID_PROCESO, p.NOMBRE_PROCESO, p.BASE_DATOS, p.OWNER, p.STORE_PROCEDURE
  FROM   #PROCESO pp, FC_PROCESO p
  WHERE  p.CVE_EMPRESA     = @pCveEmpresa        AND
 		 pp.ID_PROCESO     = p.ID_PROCESO        
		 ORDER BY pp.SEC_PROCESO

  SET @NunRegistros = @@ROWCOUNT

  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN

  BEGIN TRY

    SELECT @cve_empresa =  CVE_EMPRESA, @id_proceso = ID_PROCESO, @nom_proceso  =  NOM_PROCESO, @base_datos = BASE_DATOS,  
	       @owner = OWNER, @store_procedure = STORE_PROCEDURE
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount

-- Dependiendo de las politicas determina si el proceso debe ejecutarse

	SET  @pBError   =  @k_falso
	SET  @pError    =  ' '
	SET  @pMsgError = ' ' 

    EXEC spVerCondProc 
    @pCveEmpresa,
    @pIdCliente,
    @pCodigoUsuario,
    @pCveAplicacion,
    @pIdEtapa,
    @pIdPaso,
    @pPeriodo,
    @id_proceso,
    @pBError     OUT,
    @pError      OUT,
    @pMsgError   OUT 

    IF  @pBError  =  @k_verdadero 
    BEGIN
      RETURN
    END

	SET  @b_error_int   =  @k_falso
    SET  @error_int     =  ' '
    SET  @msg_error_int =  ' '

	SELECT ' Proceso ' + CONVERT(VARCHAR(5), @id_proceso)

    EXEC  spLanzaProcCont   
    @pIdCliente,
    @pCveEmpresa,
    @pCodigoUsuario,
    @pCveAplicacion,
    @pPeriodo,
    @id_proceso,
    @k_verdadero,
    @folio_exec      OUT,
	@k_falso,
	@hora_inicio     OUT,
	@hora_fin        OUT,
	@b_error_int     OUT,
    @error_int       OUT,
    @msg_error_int   OUT 
 
    SELECT 'FOLIO ' + CONVERT(VARCHAR(5), @folio_exec)

  -- Determina si existió error en el procedimiento ejecutado

  	 SELECT * FROM FC_PROCESO p, FC_PROC_EXEC ex, FC_TAREA t, FC_TAREA_EVENTO ev WHERE
	 p.CVE_EMPRESA      =  @pCveEmpresa   AND
	 P.ID_PROCESO       =  @id_proceso    AND
	 ex.CVE_EMPRESA     =  p.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  p.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  @folio_exec    AND
	 ex.CVE_EMPRESA     =  t.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  t.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  @folio_exec    AND
	 ex.FOLIO_EXEC      =  t.FOLIO_EXEC   AND
	 t.CVE_EMPRESA      =  ev.CVE_EMPRESA AND
	 t.ID_PROCESO       =  ev.ID_PROCESO  AND
	 t.FOLIO_EXEC       =  ev.FOLIO_EXEC  AND
	 ev.CVE_TIPO_EVENTO =  @k_error 


     IF  EXISTS
	(SELECT 1 FROM FC_PROCESO p, FC_PROC_EXEC ex, FC_TAREA t, FC_TAREA_EVENTO ev WHERE
	 p.CVE_EMPRESA      =  @pCveEmpresa   AND
	 P.ID_PROCESO       =  @id_proceso    AND
	 ex.CVE_EMPRESA     =  p.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  p.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  @folio_exec    AND
	 ex.CVE_EMPRESA     =  t.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  t.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  @folio_exec    AND
	 ex.FOLIO_EXEC      =  t.FOLIO_EXEC   AND
	 t.CVE_EMPRESA      =  ev.CVE_EMPRESA AND
	 t.ID_PROCESO       =  ev.ID_PROCESO  AND
	 t.FOLIO_EXEC       =  ev.FOLIO_EXEC  AND
	 ev.CVE_TIPO_EVENTO =  @k_error)      OR  @b_error_int  =  @k_verdadero 
	 BEGIN
 	   SET  @pBError       = @k_verdadero
	   SET  @sit_proceso  =  @k_error
	   SET  @RowCount     = @NunRegistros + 1 
	 END
     ELSE
	 BEGIN
	   SET   @sit_proceso  =  @k_correcto
       SET   @RowCount = @RowCount + 1
     END

	 EXEC spCreaProcExePaso
	 @pCveEmpresa,
     @pIdEtapa,
     @pIdPaso,
     @pPeriodo,
     @id_proceso,
     @folio_exec,    
     @sit_proceso ,
     @pBError       OUT,
     @pError        OUT,
     @pMsgError     OUT 

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) Ejecutar Etapa/Paso'
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SET  @pBError   =  @k_verdadero
  END CATCH 

  END

  IF OBJECT_ID(N'tempdb..#PROCESO') IS NOT NULL
  BEGIN
    DROP TABLE #PROCESO
  END
  
END
