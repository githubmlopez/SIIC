USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spLanzaMonitor')
BEGIN
  DROP  PROCEDURE spLanzaMonitor
END
GO
-- EXEC spLanzaMonitor 1,'CU','MARIO','SIIC','201902','PRUEBA',0,0,' ',' '

CREATE PROCEDURE [dbo].[spLanzaMonitor]  
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(6),
@pCveMonitor      varchar(10),
@pIdProceso       numeric(9),
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
		  @k_error         varchar(1)  =  'E',
		  @k_correcta      varchar(2)  =  'CO',
		  @k_error_proc    varchar(2)  =  'ER',
		  @k_no_proc       varchar(2)  =  'NP',
		  @k_todos_proc    int         =  0,
		  @k_prim_tarea    int         =  1,
		  @k_aborta        varchar(1)  =  'A',
		  @k_ejecuta       varchar(1)  =  'E',
		  @k_depende       varchar(1)  =  'D'

  DECLARE @TEstMonitor TABLE (
          RowID           int IDENTITY(1,1) NOT NULL,
          ID_PROCESO      numeric(9,0),
		  STORE_PROCEDURE varchar(50),
		  NOMBRE_PROCESO  varchar(50),
          F_OPERACION     date,
          FOLIO_EJECUCION int,
          HORA_INICIO     varchar(10),
          HORA_FINAL      varchar(10),
          SIT_PROCESO     varchar(2))

  DECLARE @TProcMonitor TABLE (
          RowID            int IDENTITY(1, 1) NOT NULL, 
          CVE_EMPRESA      varchar(4),
		  ID_PROCESO       numeric(9),
		  NOM_PROCESO      varchar(50),
		  BASE_DATOS       varchar(20),
		  OWNER            varchar(20),
		  STORE_PROCEDURE  varchar(50),
		  STORE_PROC_DEP   varchar(50),
		  CVE_TIPO_PROC    varchar(1),
		  CVE_TIPO_MON     varchar(1)
   )
 
  DECLARE  @NunRegistros     int, 
           @RowCount         int

  DECLARE  @cve_empresa      varchar(4),
           @id_proceso       numeric(9),
		   @nom_proceso      varchar(50),
           @base_datos       varchar(20),
		   @owner            varchar(20),
		   @store_procedure  varchar(50),
		   @store_proc_dep   varchar(50),
		   @cve_tipo_proc    varchar(1),
		   @cve_tipo_mon     varchar(1),
		   @b_ejecuta        varchar(1),
		   @b_execute        varchar(1),
		   @b_error_int      varchar(1)

  DECLARE  @id_tarea         numeric(9,0),
           @f_operacion      date,
		   @hora_inicio      varchar(10),
		   @hora_fin         varchar(10),
           @folio_exec       int,
           @sit_proceso      varchar(2),
           @num_reg_tran     int,
		   @b_val_periodo    bit

  SELECT @pFolioExe = (SELECT FOLIO_EXE FROM FC_MONITOR WHERE CVE_EMPRESA =  @pCveEmpresa AND CVE_MONITOR = @pCveMonitor) + 1

  UPDATE FC_MONITOR SET FOLIO_EXE = FOLIO_EXE + 1 WHERE CVE_EMPRESA =  @pCveEmpresa AND CVE_MONITOR = @pCveMonitor

  INSERT @TEstMonitor (ID_PROCESO, STORE_PROCEDURE, NOMBRE_PROCESO, F_OPERACION, FOLIO_EJECUCION, HORA_INICIO, HORA_FINAL, SIT_PROCESO)
  SELECT p.ID_PROCESO, p.STORE_PROCEDURE, p.NOMBRE_PROCESO, GETDATE(), 0, ' ', ' ',  @k_no_proc
  FROM   FC_PROCESO p, FC_MONITOR_PROC mp
  WHERE  mp.CVE_EMPRESA  =  @pCveEmpresa  AND
         mp.CVE_MONITOR  =  @pCveMonitor  AND
		 MP.ID_PROCESO   =  P.ID_PROCESO  ORDER BY SEQ_EJECUCION

  INSERT  @TProcMonitor (CVE_EMPRESA, ID_PROCESO, NOM_PROCESO, BASE_DATOS, OWNER, STORE_PROCEDURE, STORE_PROC_DEP,
                         CVE_TIPO_PROC,  CVE_TIPO_MON)
  SELECT p.CVE_EMPRESA, p.ID_PROCESO, p.NOMBRE_PROCESO, p.BASE_DATOS, p.OWNER, p.STORE_PROCEDURE,
         mp.STORE_PROCEDURE, mp.CVE_TIPO_PROC, m.CVE_TIPO_MON 
  FROM   FC_MONITOR m, FC_MONITOR_PROC mp, FC_PROCESO p
  WHERE  m.CVE_EMPRESA     = mp.CVE_EMPRESA      AND
         m.CVE_MONITOR     = mp.CVE_MONITOR      AND
         m.CVE_EMPRESA     = @pCveEmpresa        AND
		 m.CVE_MONITOR     = @pCveMonitor        AND
         mp.CVE_EMPRESA    = p.CVE_EMPRESA       AND
 		 mp.ID_PROCESO     = p.ID_PROCESO        AND
		 mp.B_ACTIVO       = @k_verdadero        AND
		(@pIdProceso       = @k_todos_proc       OR
		 mp.ID_PROCESO     = @pIdProceso) ORDER BY mp.SEQ_EJECUCION

  SET @NunRegistros = @@ROWCOUNT

--  SELECT * FROM @TProcMonitor

  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN

  BEGIN TRY

    SELECT @cve_empresa =  CVE_EMPRESA, @id_proceso = ID_PROCESO, @nom_proceso  =  NOM_PROCESO, @base_datos = BASE_DATOS,  
	       @owner = OWNER, @store_procedure = STORE_PROCEDURE, @store_proc_dep = STORE_PROC_DEP, @cve_tipo_proc = CVE_TIPO_PROC,
		   @cve_tipo_mon = CVE_TIPO_MON	
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount

	SET @b_ejecuta =  @k_falso

-- Dependiendo de las politicas determina si el proceso debe ejecutarse

	IF  @cve_tipo_proc =  @k_ejecuta  
	BEGIN
	  SET  @b_ejecuta  =  @k_verdadero
	END
	ELSE
	BEGIN
	  IF  @cve_tipo_proc =  @k_depende 
	  BEGIN
	    IF  (SELECT SIT_PROCESO FROM  @TEstMonitor  WHERE STORE_PROCEDURE  =  @store_proc_dep)  =  @k_correcta
		BEGIN
          SET  @b_ejecuta  =  @k_verdadero
		END     
	  END
	END

	SET @b_execute   =  @k_falso
	SET @folio_exec  =  0
	SET @hora_inicio =  ' '
	SET @hora_fin    =  ' '

    IF  @b_ejecuta   =  @k_verdadero
	BEGIN
      SET @b_execute    =  @k_verdadero
      SET @b_error_int  =  @k_falso
  	  EXEC  spLanzaProceso   
      @pIdCliente,
      @pCveEmpresa,
      @pCodigoUsuario,
      @pCveAplicacion,
      @pAnoPeriodo,
      @id_proceso,
	  @b_val_periodo,
	  @folio_exec OUT,
	  @hora_inicio OUT,
	  @hora_fin OUT,
	  @b_error_int OUT,
      @pError OUT,
      @pMsgError OUT
    END
    ELSE
	BEGIN
      SET @b_error_int =  @k_falso
	  SET @b_execute   =  @k_falso
	END

-- Determina si existió error en el procedimiento ejecutado
    SET @sit_proceso  =  @k_no_proc
    IF  EXISTS
	(SELECT 1 FROM FC_PROCESO p, FC_PROC_EXEC ex, FC_TAREA t, FC_TAREA_EVENTO ev WHERE
	 p.CVE_EMPRESA      =  @pCveEmpresa   AND
	 P.ID_PROCESO       =  @id_proceso    AND
	 ex.CVE_EMPRESA     =  p.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  p.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  @folio_exec    AND
	 ex.CVE_EMPRESA     =  t.CVE_EMPRESA  AND
	 ex.ID_PROCESO      =  t.ID_PROCESO   AND
	 ex.FOLIO_EXEC      =  t.FOLIO_EXEC   AND
	 t.CVE_EMPRESA      =  ev.CVE_EMPRESA AND
	 t.ID_PROCESO       =  ev.ID_PROCESO  AND
	 t.FOLIO_EXEC       =  ev.FOLIO_EXEC  AND
	 ev.CVE_TIPO_EVENTO =  @k_error)      OR  @b_error_int  =  @k_verdadero 
	 BEGIN
       SET  @pBError     = @k_verdadero
	   SET  @sit_proceso = @k_error_proc
	 END
	 ELSE
	 BEGIN
       IF   @b_execute =  @k_verdadero
	   BEGIN
	     SET  @sit_proceso = @k_correcta
       END
	 END

    SET  @f_operacion  =  GETDATE()
--	SELECT 'PROC ' + CONVERT(varchar(10), @id_proceso) + ' ' + @sit_proceso
	UPDATE @TEstMonitor 
	SET  FOLIO_EJECUCION  = @folio_exec, HORA_INICIO  =  @hora_inicio, HORA_FINAL = @hora_fin, 
	SIT_PROCESO = @sit_proceso
	WHERE ID_PROCESO  =  @id_proceso

	IF  @sit_proceso =  @k_error_proc  AND  @cve_tipo_mon  =  @k_aborta
	BEGIN
      -- Forza al temino del ciclo
      SET   @RowCount = @NunRegistros + 1
	END
    ELSE
	BEGIN
      SET   @RowCount = @RowCount + 1
    END

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) Ejecutar monitor'
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SET  @pBError   =  @k_verdadero
  END CATCH 

  END

  INSERT  INTO FC_MONITOR_EXEC (CVE_EMPRESA, CVE_MONITOR, FOLIO_EXEC, ID_PROCESO, STORE_PROCEDURE, NOMBRE_PROCESO, F_OPERACION,
                           FOLIO_EXEC_PROC, HORA_INICIO, HORA_FINAL,  SIT_PROCESO)
  SELECT  @pCveEmpresa, @pCveMonitor, @pFolioExe, ID_PROCESO, STORE_PROCEDURE, NOMBRE_PROCESO, F_OPERACION, FOLIO_EJECUCION, HORA_INICIO,
          HORA_FINAL, SIT_PROCESO FROM @TEstMonitor
END