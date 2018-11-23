USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
GO
-- DECLARE @total numeric(16,2)
--EXEC spCalIndChequera 'CU', '201804', 'TRA437', @total OUT
-- SELECT 'TOTAL ' + CONVERT(VARCHAR(10), @total)
--DROP PROCEDURE spCalIndChequera
ALTER PROCEDURE [dbo].[spCalIndChequera]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pCveIndicador varchar(10),
                                          @pTotIndicador numeric(16,2) OUTPUT
                                          
AS
BEGIN
  DECLARE  @cve_empresa     varchar(4),
           @cve_indicador   varchar(10),
           @cve_chequera    varchar(6),
           @cve_cargo       varchar(2),
           @cve_abono       varchar(2),
		   @cve_sdo_inicial varchar(2),
		   @sdo_inicio_mes  numeric(12,2)
		  
  DECLARE  @NunRegistros    int, 
           @RowCount        int,
		   @tot_cargos      numeric(16,2)  =  0,
		   @tot_abonos      numeric(16,2)  =  0,
		   @tot_indicador   numeric(16,2)  =  0

  DECLARE  @k_verdadero     bit         =  1,
           @k_falso         bit         =  0,
		   @k_suma          varchar(2)  =  'SU',
		   @k_resta         varchar(2)  =  'RE',
		   @k_no_aplica     varchar(2)  =  'NA',
		   @k_activo        varchar(1)  =  'A',
		   @k_cargo         varchar(1)  =  'C',
		   @k_abono         varchar(1)  =  'A'

  DECLARE @Tchequera TABLE (
          RowID           int IDENTITY(1, 1), 
		  CVE_EMPRESA     varchar(4),
          CVE_INDICADOR   varchar(10),
          CVE_CHEQUERA    varchar(6),
          CVE_CARGO       varchar(2),
          CVE_ABONO       varchar(2),
		  CVE_SDO_INICIAL varchar(2),
		  SDO_INICIO_MES  numeric(12,2))

  INSERT INTO @Tchequera (CVE_EMPRESA, CVE_INDICADOR, CVE_CHEQUERA,
                          CVE_CARGO, CVE_ABONO, CVE_SDO_INICIAL, SDO_INICIO_MES)
  SELECT i.CVE_EMPRESA, i.CVE_INDICADOR, i.CVE_CHEQUERA, i.CVE_CARGO, i.CVE_ABONO, i.CVE_SDO_INICIAL, ch.SDO_INICIO_MES
  FROM   CI_IND_CHEQUERA i, CI_CHEQUERA_PERIODO ch
  WHERE  i.CVE_EMPRESA    =  @pCveEmpresa    AND 
         i.CVE_INDICADOR  =  @pCveIndicador  AND
		 i.CVE_CHEQUERA   =  ch.CVE_CHEQUERA AND
		 ch.ANO_MES       =  @pAnoMes

  SET @NunRegistros = @@ROWCOUNT
--  SELECT 'SL REG PROC CH ' + CONVERT(varchar(10),@NunRegistros)

  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa = CVE_EMPRESA, @cve_indicador = CVE_INDICADOR, @cve_chequera = CVE_CHEQUERA,
           @cve_cargo = CVE_CARGO, @cve_abono = CVE_ABONO, @cve_sdo_inicial = CVE_SDO_INICIAL, @sdo_inicio_mes = SDO_INICIO_MES
    FROM   @Tchequera
    WHERE RowID = @RowCount

	SET  @tot_cargos  =  0
	SET  @tot_abonos  =  0

	SELECT @tot_cargos = SUM(IMP_TRANSACCION)
	FROM  CI_MOVTO_BANCARIO m 
	WHERE  m.ANO_MES  =  @pAnoMes  AND  m.CVE_CHEQUERA  =  @cve_chequera  AND  CVE_CARGO_ABONO  =  @k_cargo AND
	[dbo].[fnVerIndMovto] (@pCveEmpresa, @cve_indicador, m.CVE_CHEQUERA, m.CVE_TIPO_MOVTO, SIT_CONCILIA_BANCO)  =  @k_verdadero              

    SET  @tot_cargos  =  ISNULL(@tot_cargos,0) 

--    SELECT  'SL sum(C) ' + isnull(CONVERT(VARCHAR(10), @tot_cargos),'99')

	SELECT @tot_abonos = SUM(IMP_TRANSACCION)
	FROM  CI_MOVTO_BANCARIO m 
	WHERE  m.ANO_MES  =  @pAnoMes  AND  m.CVE_CHEQUERA  =  @cve_chequera  AND  CVE_CARGO_ABONO  =  @k_abono AND
	[dbo].[fnVerIndMovto] (@pCveEmpresa, @cve_indicador, m.CVE_CHEQUERA, m.CVE_TIPO_MOVTO, SIT_CONCILIA_BANCO)  =  @k_verdadero              

	SET  @tot_abonos  =  ISNULL(@tot_abonos,0) 
--    SELECT  'SL sum(A) ' + isnull(CONVERT(VARCHAR(10), @tot_abonos),'99')
	
    IF  @cve_cargo  =  @k_no_aplica
	BEGIN
	  SET  @tot_cargos  = 0
	END 
	ELSE
	BEGIN
	  IF  @cve_cargo  =  @k_resta
	  BEGIN
	    SET  @tot_cargos  =  @tot_cargos * -1 
	  END
	END

--    SELECT  'SL (CC) ' + isnull(CONVERT(VARCHAR(10), @tot_cargos),'99')

    IF  @cve_abono  =  @k_no_aplica
	BEGIN
	  SET  @tot_abonos  = 0
	END 
	ELSE
	BEGIN
	  IF  @cve_abono  =  @k_resta
	  BEGIN
	    SET  @tot_abonos  =  @tot_abonos * -1 
	  END
	END

	IF  @cve_sdo_inicial  =  @k_no_aplica
	BEGIN
	  SET   @sdo_inicio_mes  =  0
	END 
	ELSE
	BEGIN
	  IF  @cve_abono  =  @k_resta
	  BEGIN
	    SET  @sdo_inicio_mes  =  @tot_abonos * -1 
	  END
	END
--    SELECT  'SL (AC) ' + isnull(CONVERT(VARCHAR(10), @tot_abonos),'99')

	SET  @pTotIndicador  =   @pTotIndicador + @tot_cargos  +  @tot_abonos  +  @sdo_inicio_mes

    SET @RowCount = @RowCount + 1

  END                                                                                             
END