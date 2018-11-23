USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
-- Proceso que valida integridad de la información en general
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E0M1INMES', 0
-- Proceso que compara la facturación contra el CONTPAQ y verifica los saldos bancarios
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E1M1RERP', 0
-- Porceso que genera las transacciones previo a la generación de pólizas
-- El proceso incluye una validación de la información generada
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201809', 'E2M1GTRAN',0
-- Proceso generación de póliza contables
-- El proceso incluye una validación de la información generada
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E3M1GPOL', 0
-- Proceso que carga la información de los diferentes indicadores
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E4M1GINDIC', 0
-- Proceso que muestra los resultados de los indicadores y reporte las diferencias
-- Si todo esta correcto se deben general pólizas para COI
--EXEC spEstatMonInd  'CU', '201805', 'MLOPEZ'
--Proceso que genera la inmación de la balanza previa 
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E5M1REVEFI', 0
-- Porceso que concilia la balanza previa con Balanza del COI
-- Antes de correr este proceso se debe general actualizar pólizas en el COI y general balanza
--EXEC spLanzaMonitor 'CU', 'MLOPEZ', '201805', 'E6M1COCOI', 0

ALTER PROCEDURE [dbo].[spLanzaMonitor]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6),
                                        @pCveMonitor  varchar(10), @pIdProceso  numeric(9,0)
AS
BEGIN

  DECLARE @k_falso         bit  =  0,
          @k_verdadero     bit  =  1,
		  @k_warning       varchar(1)  =  'W',
		  @k_error         varchar(1)  =  'E',
		  @k_correcta      varchar(2)  =  'CO',
		  @k_error_proc    varchar(2)  =  'ER',
		  @k_no_proc       varchar(2)  =  'NP',
		  @k_todos_proc    int         =  0

  CREATE TABLE #ESTMONITOR (
  RowID           int IDENTITY(1,1) NOT NULL,
  ID_PROCESO      NUMERIC(9,0),
  NOM_PROCESO     varchar(100),
  ID_TAREA        numeric(9,0),
  F_OPERACION     date,
  STORE_PROCEDURE varchar(50),
  HORA_INICIO     varchar(10),
  HORA_FINAL      varchar(10),
  CODIGO_USUARIO  varchar(20),
  NUM_REGISTROS   int, 
  SIT_PROCESO     varchar(2))

  DECLARE @TProcMonitor TABLE (
          RowID            int IDENTITY(1, 1), 
          CVE_EMPRESA      varchar(4),
		  ID_PROCESO       numeric(9),
		  NOM_PROCESO      varchar(50),
		  STORE_PROCEDURE  varchar(50)
  )
 
  DECLARE  @NunRegistros     int, 
           @RowCount         int

  DECLARE  @cve_empresa      varchar(4),
           @id_proceso       numeric(9),
		   @nom_proceso      varchar(50),
		   @store_procedure  varchar(50)

  DECLARE  @id_tarea         numeric(9,0),
           @f_operacion      date,
		   @hora_inicio      varchar(10),
		   @hora_fin         varchar(10),
		   @codigo_usuario   varchar(20)

  DECLARE  @utl_fol_tarea    int,
           @sit_tarea        varchar(2)

  INSERT  @TProcMonitor (CVE_EMPRESA, ID_PROCESO, NOM_PROCESO, STORE_PROCEDURE)
  SELECT p.CVE_EMPRESA, p.ID_PROCESO,  p.NOMBRE_PROCESO, p.STORE_PROCEDURE 
  FROM CI_MONITOR m, FC_MON_PROCESO mp, FC_GEN_PROCESO p
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
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa =  CVE_EMPRESA, @id_proceso = ID_PROCESO, @nom_proceso  =  NOM_PROCESO, 
	       @store_procedure = STORE_PROCEDURE	
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount
     
    EXEC  spLanzaProceso  @id_proceso, @pCveEmpresa, @pCveUsuario,
                          @pAnoMes, @store_procedure 
--    EXEC  spEstatMonitor  @pCveEmpresa, @pAnoMes, @pCveMonitor, @id_proceso     

	IF  EXISTS(SELECT 1 FROM #ESTMONITOR m WHERE 
		m.ID_PROCESO  =  @id_proceso       AND
		m.SIT_PROCESO IN(@k_warning, @k_error))
	BEGIN
	  SET  @NunRegistros  =  @NunRegistros -- + 1
	END   

    SET   @RowCount = @RowCount + 1
  END

  IF object_id('tempdb..#ESTMONITOR') IS  NOT NULL 
  BEGIN
    DELETE FROM #ESTMONITOR
    EXEC  spEstatMonitor @pCveEmpresa, @pAnoMes, @pCveMonitor, @k_todos_proc     

    SELECT  t.ANO_MES_PROC, p.ID_PROCESO, p.NOMBRE_PROCESO, e.CVE_TIPO_EVENTO, e.MSG_ERROR
    FROM FC_MON_PROCESO m, FC_GEN_PROCESO p, FC_GEN_TAREA t, FC_GEN_TAREA_EVENTO e 
    WHERE m.CVE_EMPRESA  =  @pCveEmpresa    AND
          m.CVE_MONITOR  =  @pCveMonitor    AND
	      m.CVE_EMPRESA  =  p.CVE_EMPRESA   AND
	      m.ID_PROCESO   =  p.ID_PROCESO    AND
	      p.CVE_EMPRESA  =  t.CVE_EMPRESA   AND
	      p.ID_PROCESO   =  t.ID_PROCESO    AND
	      t.ANO_MES_PROC =  @pAnoMes        AND
	      t.CVE_EMPRESA  =  e.CVE_EMPRESA   AND
	      t.ID_PROCESO   =  e.ID_PROCESO    AND
	      t.ID_TAREA     =  e.ID_TAREA      AND
		  t.ID_TAREA     =
		  (SELECT MAX(ID_TAREA) FROM FC_GEN_TAREA ta WHERE ta.CVE_EMPRESA = @pCveEmpresa AND ta.ID_PROCESO = p.ID_PROCESO  AND
		                             t.ANO_MES_PROC = @pAnoMes)

 --   IF  @@ROWCOUNT  > 0
	--BEGIN
	--END

	DROP  TABLE  #ESTMONITOR
  END
END