USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--DROP PROCEDURE spCalIndCuenta
ALTER PROCEDURE [dbo].[spCalIndCuenta]  @pCveEmpresa varchar(4), @pAnoMes varchar(6), @pCveIndicador varchar(10),
                                        @pTotIndicador  numeric(16,2) OUTPUT
AS
BEGIN
  DECLARE  @cve_empresa    varchar(4),
           @cve_indicador  varchar(10),
           @cta_contable   varchar(30),
           @nivel          int,
           @cve_cargo      varchar(2),
           @cve_abono      varchar(2),
		   @cve_sdo_inicial varchar(2),
		   @cve_tipo_calc   varchar(1)
		   
		  
  DECLARE  @NunRegistros   int, 
           @RowCount       int,
		   @tot_cargos     numeric(16,2)  =  0,
		   @tot_abonos     numeric(16,2)  =  0,
		   @ano_mes_ant    varchar(6),
		   @ano            int,
		   @mes            int,
		   @sdo_inicio_mes numeric(16,2)

  DECLARE  @k_verdadero   bit         =  1,
           @k_falso       bit         =  0,
		   @k_suma        varchar(2)  =  'SU',
		   @k_resta       varchar(2)  =  'RE',
		   @k_no_aplica   varchar(2)  =  'NA',
		   @k_activo      varchar(1)  =  'A',
		   @k_poliza      varchar(1)  =  'P',
		   @k_cuenta      varchar(1)  =  'C',
           @k_enero        int        =  1,
           @k_diciembre    int        =  12,
		   @k_ult_nivel    int        =  12,
		   @k_no_nivel     int        =  0

  DECLARE @TCuentas TABLE (
          RowID           int IDENTITY(1, 1), 
		  CVE_EMPRESA     varchar(4),
          CVE_INDICADOR   varchar(10),
          CTA_CONTABLE    varchar(30),
		  NIVEL           int,
          CVE_CARGO       varchar(2),
          CVE_ABONO       varchar(2),
		  CVE_SDO_INICIAL varchar(2),
		  CVE_TIPO_CAL    varchar(1))

  SET  @ano  =  CONVERT(INT,SUBSTRING(@pAnoMes,1,4))
  SET  @mes  =  CONVERT(INT,SUBSTRING(@pAnoMes,5,2))

  IF  @mes  <>  @k_enero
  BEGIN
    SET  @mes  =  @mes - 1
  END
  ELSE
  BEGIN
    SET  @ano  =  @ano  -  1
	SET  @mes  =  @k_diciembre
  END

  SET  @ano_mes_ant  =  dbo.fnArmaAnoMes (@ano, @mes)
--  SELECT ' ENTRO A CUENTAS '
  INSERT INTO @TCuentas (CVE_EMPRESA, CVE_INDICADOR, CTA_CONTABLE, NIVEL,
                         CVE_CARGO, CVE_ABONO, CVE_SDO_INICIAL, CVE_TIPO_CAL)
  SELECT CVE_EMPRESA, CVE_INDICADOR, CTA_CONTABLE, NIVEL, CVE_CARGO, CVE_ABONO, CVE_SDO_INICIAL, CVE_TIPO_CALC
  FROM   CI_IND_CUENTA 
  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  CVE_INDICADOR  =  @pCveIndicador  
  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_empresa = CVE_EMPRESA, @cve_indicador = CVE_INDICADOR, @cta_contable = CTA_CONTABLE, @nivel = NIVEL,
           @cve_cargo = CVE_CARGO, @cve_abono = CVE_ABONO, @cve_sdo_inicial = CVE_SDO_INICIAL, @cve_tipo_calc = CVE_TIPO_CAL
    FROM   @TCuentas
    WHERE RowID = @RowCount
	
	SET  @tot_cargos  =  0
	SET  @tot_abonos  =  0

	IF  @nivel  =  @k_no_nivel
	BEGIN
      SET @nivel  =  @k_ult_nivel
	END
  
    IF  @cve_tipo_calc = @k_poliza
	BEGIN
	  SELECT @tot_cargos = SUM(IMP_DEBE), @tot_abonos = SUM(IMP_HABER)  FROM  CI_DET_POLIZA p 
	  WHERE  CVE_EMPRESA  = @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
	        (SELECT  e.SIT_POLIZA  FROM CI_ENCA_POLIZA e  WHERE
		     e.CVE_EMPRESA  = p.CVE_EMPRESA  AND  e.ANO_MES  = p.ANO_MES  AND  e.CVE_POLIZA  =  p.CVE_POLIZA  AND
		   	 e.ID_ENCA_POLIZA  =  p.ID_ENCA_POLIZA)  =  @k_activo   AND
			 p.CVE_POLIZA  IN 
		    (SELECT  CVE_POLIZA  FROM CI_IND_POLIZA  WHERE
		     CVE_EMPRESA    =  @pCveEmpresa   AND
		 	 CVE_INDICADOR  =  @pCveIndicador)  AND
			 SUBSTRING(CTA_CONTABLE,1,@nivel)  =  SUBSTRING(@cta_contable,1,@nivel)
      SET @tot_cargos = ISNULL(@tot_cargos,0)
      SET @tot_abonos = ISNULL(@tot_abonos,0)
    END
	ELSE
	BEGIN
	  IF  @cve_tipo_calc = @k_cuenta
	  BEGIN
       SELECT 'CTA ' + SUBSTRING(@cta_contable,1,@nivel)
	    SELECT @tot_cargos = SUM(IMP_DEBE), @tot_abonos = SUM(IMP_HABER)  FROM  CI_DET_POLIZA p 
	    WHERE  CVE_EMPRESA  = @pCveEmpresa  AND  ANO_MES  =  @pAnoMes AND
			   SUBSTRING(CTA_CONTABLE,1,@nivel) = SUBSTRING(@cta_contable,1,@nivel)
        SET @tot_cargos = ISNULL(@tot_cargos,0)
		SET @tot_abonos = ISNULL(@tot_abonos,0)

  SELECT 'DEBE '
  SELECT CONVERT(VARCHAR(16), @tot_cargos) 		
  SELECT 'HABER' 
  SELECT CONVERT(VARCHAR(16), @tot_abonos) 		
	  END
	  ELSE
	  BEGIN
        SET  @tot_cargos  = 0
		SET  @tot_abonos  = 0	  
	  END
	END 
    
	IF  EXISTS (SELECT 1 FROM CI_BALANZA_OPERATIVA WHERE CTA_CONTABLE = 
	                          SUBSTRING(@cta_contable,1,@nivel) + '-00'  AND  ANO_MES  =  @ano_mes_ant)  AND 
							  @cve_sdo_inicial <> @k_no_aplica
    BEGIN
--	  SELECT 'VOY SDO ' + CONVERT(VARCHAR(4), @nivel) 
	  SET @sdo_inicio_mes = (SELECT SDO_FINAL FROM CI_BALANZA_OPERATIVA WHERE CTA_CONTABLE = 
	                         SUBSTRING(@cta_contable,1,@nivel) + '-00' AND  ANO_MES  =  @ano_mes_ant)
	  SET @sdo_inicio_mes = ISNULL(@sdo_inicio_mes,0)
--	  SELECT 'SDO ' + CONVERT(VARCHAR(16), @sdo_inicio_mes) 						  
 	END
	ELSE
	BEGIN
      SET @sdo_inicio_mes  =  0
	END
			 
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

--    SELECT  'SL CTA (CC) ' + isnull(CONVERT(VARCHAR(10), @tot_cargos),'99')

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
	    SET  @sdo_inicio_mes  =  @sdo_inicio_mes * -1 
	  END
	END
--    SELECT  'SL CTA (AC) ' + isnull(CONVERT(VARCHAR(10), @tot_abonos),'99')

	SET  @pTotIndicador  =  @pTotIndicador + @tot_cargos  +  @tot_abonos + @sdo_inicio_mes
--	SELECT CONVERT(VARCHAR(4), @nivel) 
	
    SET @RowCount = @RowCount + 1

  END                                                                                             
END