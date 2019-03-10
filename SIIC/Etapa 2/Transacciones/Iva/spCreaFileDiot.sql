USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-- exec spCreaFileDiot'CU', 'MLOPEZ', '201901', 1, 2, ' ', ' '
ALTER PROCEDURE [dbo].[spCreaFileDiot]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6) -- , 
--                                         @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
--								           @pMsgError varchar(400) OUT
AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @rfc               varchar(15),
           @imp_tot_bruto     int,
		   @imp_tot_iva       int,
		   @cve_tipo_oper     varchar(2),
		   @cve_tipo          varchar(1)

  DECLARE  @k_proveedor       varchar(1)  =  'E',
           @k_otros           varchar(2)  =  '85',
		   @k_verdadero       bit         =  1

-------------------------------------------------------------------------------
-- Verificación de Tipos de Conciliación
-------------------------------------------------------------------------------

  DECLARE  @TDiot             TABLE
          (RowID              int  identity(1,1),
		   RFC                varchar(15),
		   IMP_TOT_BRUTO      int,
		   IMP_TOT_IVA        int,
		   CVE_TIPO_OPERACION varchar(2))
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TDiot  (RFC, IMP_TOT_IVA, IMP_TOT_BRUTO, CVE_TIPO_OPERACION)  
  SELECT RFC, ABS(SUM(ROUND(IMP_IVA,0,1))), ABS(SUM(ROUND(IMP_BRUTO,0,1))), ' ' FROM CI_PERIODO_IVA 
  WHERE  ANO_MES_ACRED = @pAnoMes    AND
         IMP_IVA       > 0           AND
		 B_ACREDITADO  = @k_verdadero
  GROUP BY RFC
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @rfc = RFC, @imp_tot_bruto =  ROUND(IMP_TOT_BRUTO,0,1), @imp_tot_iva = ROUND(IMP_TOT_IVA,0,1), @cve_tipo_oper = CVE_TIPO_OPERACION
	FROM @TDiot
	WHERE  RowID  =  @RowCount

	SELECT @cve_tipo = (SELECT TOP(1) CVE_TIPO FROM CI_PERIODO_IVA WHERE RFC = @rfc)

    UPDATE @TDiot SET CVE_TIPO_OPERACION =
	                ISNULL((SELECT TOP (1) CVE_TIPO_OPERACION  FROM CI_PERIODO_IVA WHERE RFC = @rfc),'**') WHERE RFC = @rfc
    SET @RowCount = @RowCount + 1
  END
--  SELECT * FROM @TDiot
  SELECT '04' + CHAR(124) + CVE_TIPO_OPERACION +  CONVERT(VARCHAR(1),CHAR(124)) + 
  RFC +  CONVERT(VARCHAR(1),CHAR(124)) + '' + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) +
  CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(16),IMP_TOT_BRUTO) + CONVERT(VARCHAR(1),CHAR(124)) +
  CONVERT(VARCHAR(1),CHAR(124)) + 
  CONVERT(VARCHAR(16),IMP_TOT_IVA) +
  CONVERT(VARCHAR(1),CHAR(124)) + 
  CONVERT(VARCHAR(1),CHAR(124)) + 
  CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) +
  CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + 
  CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) + CONVERT(VARCHAR(1),CHAR(124)) +
  CONVERT(VARCHAR(1),CHAR(124))
  FROM @TDiot

END