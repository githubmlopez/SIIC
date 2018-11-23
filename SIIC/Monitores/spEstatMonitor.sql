USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
-- EXEC spEstatMonitor  'CU', '201804', 'E1VALIDA', 0

ALTER PROCEDURE [dbo].[spEstatMonitor]  (@pCveEmpresa varchar(4), @pAnoMes  varchar(6),  @pCveMonitor varchar(10), @pIdProceso numeric(9,0))
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

  DECLARE @TProcMonitor TABLE (
          RowID            int IDENTITY(1, 1), 
          CVE_EMPRESA      varchar(4),
		  ID_PROCESO       numeric(9),
		  NOM_PROCESO      varchar(100),
		  STORE_PROCEDURE  varchar(50)
  )
   
  DECLARE  @NunRegistros     int, 
           @RowCount         int

  DECLARE  @cve_empresa      varchar(4),
           @id_proceso       numeric(9),
		   @nom_proceso      varchar(100),
		   @store_procedure  varchar(50)

  DECLARE  @id_tarea         numeric(9,0),
           @f_operacion      date,
		   @hora_inicio      varchar(10),
		   @hora_fin         varchar(10),
		   @codigo_usuario   varchar(20),
		   @num_reg_tran     int

  DECLARE  @utl_fol_tarea    int,
           @sit_tarea        varchar(2)

  IF object_id('tempdb..#ESTMONITOR') IS  NULL 
  BEGIN
    CREATE TABLE #ESTMONITOR (
    RowID           int IDENTITY(1,1) NOT NULL,
    ID_PROCESO      numeric(9,0),
    NOM_PROCESO     varchar (100),
    ID_TAREA        numeric(9,0),
    F_OPERACION     date,
    STORE_PROCEDURE varchar(50),
    HORA_INICIO     varchar(10),
    HORA_FINAL      varchar(10),
    CODIGO_USUARIO  varchar(20),
	NUM_REGISTROS   int,
    SIT_PROCESO     varchar(2))
  END

  INSERT  @TProcMonitor (CVE_EMPRESA, ID_PROCESO, NOM_PROCESO, STORE_PROCEDURE)
  SELECT p.CVE_EMPRESA, p.ID_PROCESO,  LTRIM(SUBSTRING(PARAMETRO,1,4) + ' ' + p.NOMBRE_PROCESO), p.STORE_PROCEDURE 
  FROM CI_MONITOR m, FC_GEN_PROCESO p, FC_MON_PROCESO mp
  WHERE  m.CVE_EMPRESA    = mp.CVE_EMPRESA      AND
         m.CVE_MONITOR    = mp.CVE_MONITOR      AND
	     mp.CVE_EMPRESA   = p.CVE_EMPRESA       AND
	     mp.ID_PROCESO    = p.ID_PROCESO        AND
         m.CVE_EMPRESA    = @pCveEmpresa        AND
		 m.CVE_MONITOR    = @pCveMonitor        AND
		(@pIdProceso      = @k_todos_proc       OR
		 mp.ID_PROCESO     = @pIdProceso)  ORDER BY mp.SEQ_EJECUCION 		         

--  SELECT * FROM @TProcMonitor

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa =  CVE_EMPRESA, @id_proceso = ID_PROCESO, @nom_proceso  =  NOM_PROCESO, 
	       @store_procedure = STORE_PROCEDURE
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount

    IF  EXISTS(SELECT  1 FROM  FC_GEN_TAREA t
               WHERE  t.CVE_EMPRESA  =  @pCveEmpresa  AND 
	                  t.ID_PROCESO   =  @id_proceso   AND
	   	              t.ANO_MES_PROC =  @pAnoMes) 
    BEGIN
      SELECT @utl_fol_tarea  =  MAX(ID_TAREA)
	  FROM   FC_GEN_TAREA t
      WHERE  t.CVE_EMPRESA    =  @pCveEmpresa  AND 
	         t.ID_PROCESO     =  @id_proceso   AND
	         t.ANO_MES_PROC   =  @pAnoMes

      SET  @utl_fol_tarea  =  ISNULL(@utl_fol_tarea,0)
--	  select ' ult folio ' +  CONVERT(VARCHAR(10), @id_proceso), ' ', CONVERT(VARCHAR(10), @utl_fol_tarea)
      SELECT  @id_tarea  =  t.ID_TAREA, @f_operacion  =  t.F_OPERACION, @hora_inicio  =  t.HORA_INICIO,
	          @hora_fin  =  t.HORA_FINAL, @codigo_usuario =  t.CODIGO_USUARIO, @num_reg_tran = t.NUM_REGISTROS
	  FROM  FC_GEN_TAREA t
      WHERE  t.CVE_EMPRESA    =  @pCveEmpresa    AND 
	         t.ID_PROCESO     =  @id_proceso     AND
	         t.ID_TAREA       =  @utl_fol_tarea  AND
			 t.ANO_MES_PROC   =  @pAnoMes         
			  
  	  IF  NOT EXISTS(SELECT  1  FROM  FC_GEN_TAREA_EVENTO te
	             WHERE  te.CVE_EMPRESA     =  @pCveEmpresa    AND
				        te.ID_PROCESO      =  @id_proceso     AND
						te.ID_TAREA        =  @utl_fol_tarea  AND
						te.CVE_TIPO_EVENTO IN (@k_warning, @k_error)) 
      BEGIN
--	    SELECT  'LA TAREA ESTA CORRECTA'
		SET  @sit_tarea  =  @k_correcta 
	  END
      ELSE
	  BEGIN
--	    SELECT 'LA TAREA SE GENERO CON ERRORES'
		SET  @sit_tarea  =  @k_error_proc
	  END      	  
	END
	ELSE
	BEGIN
      SET  @id_tarea       =  0
	  SET  @f_operacion    =  NULL
	  SET  @hora_inicio    =  ' '
	  SET  @hora_fin       =  ' '
      SET  @codigo_usuario =  ' '
	  SET  @sit_tarea  =  @k_no_proc
	END
      
    INSERT  #ESTMONITOR (ID_PROCESO, NOM_PROCESO, ID_TAREA, F_OPERACION, STORE_PROCEDURE, HORA_INICIO, HORA_FINAL,
		                      CODIGO_USUARIO, NUM_REGISTROS, SIT_PROCESO)  VALUES
           (@id_proceso,
		    @nom_proceso, 
		    @id_tarea,
		    @f_operacion,      
		    @store_procedure,
		    @hora_inicio,
		    @hora_fin,
		    @codigo_usuario,
			@num_reg_tran,
		    @sit_tarea)
          
    SET   @RowCount = @RowCount + 1
  END
  SELECT * FROM #ESTMONITOR
END