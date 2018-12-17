USE [ADNOMINA01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spLanzaMonitor')
BEGIN
  DROP  PROCEDURE spLanzaMonitor
END
GO

--EXEC spLanzaMonitor 1,'CU','NOMINA','MLOPEZ', '201803', 'S','MONITOR1', 0
CREATE PROCEDURE [dbo].[spLanzaMonitor]  
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCveAplicacion varchar(10),
@pCodigoUsuario varchar(10),
@pAnoPeriodo    varchar(6),
@pCveTipoNomina varchar(2),
@pCveMonitor    varchar(10),
@pIdProceso     numeric(9,0)
)

--@pIdProceso       int,
--@pIdTarea         int,
--@pCveUsuario      varchar(10),
--@pIdCliente       int,
--@pCveEmpresa      varchar(4),
--@pCveAplicacion   varchar(10),
--@pCveUsuario      varchar(10),
--@pCveTipoNomina   varchar(2),
--@pAnoPeriodo      varchar(6),
--@pError           varchar(80) OUT,
--@pMsgError        varchar(400) OUT

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
  FROM FC_MONITOR m, FC_MON_PROCESO mp, FC_GEN_PROCESO p
  WHERE  m.ID_CLIENTE      = @pIdCliente         AND
		 m.CVE_EMPRESA     = @pCveEmpresa        AND
		 m.CVE_APLICACION  = @pCveAplicacion     and
		 m.CVE_MONITOR     = @pCveMonitor        AND
         m.ID_CLIENTE      = mp.ID_CLIENTE       AND
         m.CVE_EMPRESA     = mp.CVE_EMPRESA      AND
         m.CVE_APLICACION  = mp.CVE_APLICACION   AND
         m.CVE_MONITOR     = mp.CVE_MONITOR      AND
         mp.ID_CLIENTE     = p.ID_CLIENTE        AND
         mp.CVE_EMPRESA    = p.CVE_EMPRESA       AND
		 mp.CVE_APLICACION = p.CVE_APLICACION    AND
 		 mp.ID_PROCESO     = p.ID_PROCESO        AND
		 mp.B_ACTIVO       = @k_verdadero        AND
		(@pIdProceso       = @k_todos_proc       OR
		 mp.ID_PROCESO     = @pIdProceso) ORDER BY mp.SEQ_EJECUCION

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

-- SELECT * FROM @TProcMonitor
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa =  CVE_EMPRESA, @id_proceso = ID_PROCESO, @nom_proceso  =  NOM_PROCESO, 
	       @store_procedure = STORE_PROCEDURE	
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount
     
    EXEC  spLanzaProceso  
    @pCveMonitor,
    @id_proceso,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCodigoUsuario,
    @pAnoPeriodo,
    @pCveTipoNomina,
    @store_procedure
--    EXEC  spEstatMonitor  @pCveEmpresa, @pAnoMes, @pCveMonitor, @id_proceso     
--    SELECT 'SALGO LANZA PROCESO'
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
    EXEC  spEstatMonitor
	@pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pAnoPeriodo,
    @pCveTipoNomina,
    @pCveMonitor,
    @pIdProceso
--    SELECT 'SALGO ESTAT MONITOR'
    SELECT  t.ANO_MES_PROC, p.ID_PROCESO, p.NOMBRE_PROCESO, e.CVE_TIPO_EVENTO, e.MSG_ERROR
    FROM FC_MON_PROCESO m, FC_GEN_PROCESO p, FC_GEN_TAREA t, FC_GEN_TAREA_EVENTO e 
    WHERE m.ID_CLIENTE      =  @pIdCliente      AND
	      m.CVE_EMPRESA     =  @pCveEmpresa     AND
          m.CVE_APLICACION  =  @pCveAplicacion  AND
          m.CVE_MONITOR     =  @pCveMonitor     AND
	      m.ID_CLIENTE      =  p.ID_CLIENTE     AND
		  m.CVE_EMPRESA     =  p.CVE_EMPRESA    AND
		  m.CVE_APLICACION  =  p.CVE_APLICACION AND
	      m.ID_PROCESO      =  p.ID_PROCESO     AND
	      p.ID_CLIENTE      =  t.ID_CLIENTE     AND
		  p.CVE_EMPRESA     =  t.CVE_EMPRESA    AND
		  p.CVE_APLICACION  =  t.CVE_APLICACION AND
	      p.ID_PROCESO      =  t.ID_PROCESO     AND
	      t.ANO_MES_PROC    =  @pAnoPeriodo     AND
          t.ID_CLIENTE      =  e.ID_CLIENTE     AND
	      t.CVE_EMPRESA     =  e.CVE_EMPRESA    AND
		  t.CVE_APLICACION  =  e.CVE_APLICACION AND
	      t.ID_PROCESO      =  e.ID_PROCESO     AND
	      t.ID_TAREA        =  e.ID_TAREA       AND
		  t.ID_TAREA        =
		  (SELECT MAX(ID_TAREA) FROM FC_GEN_TAREA ta WHERE
		   ta.ID_CLIENTE     = @pIdCliente     AND 
		   ta.CVE_EMPRESA    = @pCveEmpresa    AND
		   ta.CVE_APLICACION = @pCveAplicacion AND
		   ta.ID_PROCESO     = p.ID_PROCESO    AND
		   t.ANO_MES_PROC    = @pAnoPeriodo)

 --   IF  @@ROWCOUNT  > 0
	--BEGIN
	--END

	DROP  TABLE  #ESTMONITOR
  END
END