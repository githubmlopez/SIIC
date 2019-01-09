USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spGenDiasVac '201712'

ALTER PROCEDURE [dbo].[spLanzaMonInd]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6),
                                       @pCveMonitor  varchar(10)
AS
BEGIN

  DECLARE @k_falso         bit  =  0,
          @k_verdadero     bit  =  1,
		  @k_todos_proc    int         =  0

  CREATE TABLE #ESTMONITOR (
  RowID           int IDENTITY(1,1) NOT NULL,
  CVE_INDICADOR   varchar(10),
  DESC_INDICADOR  varchar (50),
  ID_PROCESO      numeric(9,0),
  CODIGO_USUARIO  varchar(20),
  IMP_PIVOTE      numeric(16,2),
  IMP_SECUNDARIO  numeric(16,2),
  SIT_PROCESO     varchar(2))

  DECLARE @TProcMonitor TABLE (
          RowID            int IDENTITY(1, 1), 
          CVE_EMPRESA      varchar(4),
		  CVE_MONITOR      varchar(10)
  )
 
  DECLARE  @NunRegistros     int, 
           @RowCount         int

  DECLARE  @utl_fol_tarea    int,
           @sit_tarea        varchar(2)

  INSERT  @TProcMonitor (CVE_EMPRESA, CVE_MONITOR)
  SELECT m.CVE_EMPRESA, mi.CVE_INDICADOR 
  FROM CI_MONITOR m, CI_MON_INDICA mi, CI_INDICADOR i
  WHERE  m.CVE_EMPRESA    = mi.CVE_EMPRESA      AND
         m.CVE_MONITOR    = mi.CVE_MONITOR      AND
	     mi.CVE_EMPRESA   = i.CVE_EMPRESA       AND
	     mi.CVE_INDICADOR = i.CVE_INDICADOR     AND
         m.CVE_MONITOR    = @pCveEmpresa        AND
		 m.CVE_MONITOR    = @pCveMonitor   

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa =  CVE_EMPRESA, @cve_monitor = CVE_MONITOR
    FROM   @TProcMonitor
    WHERE  RowID = @RowCount
     
    EXEC  spEstatMonInd  @pCveEmpresa, @pAnoMes, pCveMonitor     

  IF object_id('tempdb..#ESTMONITOR') IS  NOT NULL 
  BEGIN
    SELECT * FROM #ESTMONITOR
    DROP  TABLE  #ESTMONITOR
  END
END