USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
--exec spBorraIndicadores 'CU', 'MARIO', '201804', 12, 361, ' ', ' '
ALTER PROCEDURE [dbo].[spBorraIndicadores]  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                       @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
		    				           @pMsgError varchar(400) OUT
AS                                        
BEGIN
  DECLARE  @k_chequera     varchar(2)  =  'CH'

  DECLARE  @cve_indicador      varchar(10),
           @cve_tipo_indicador varchar(2),
		   @imp_pivote         numeric(16,2),
		   @imp_secundario     numeric(16,2)

  DECLARE  @NunRegistros   int, 
           @RowCount       int

  DECLARE  @TIndPeriodo       TABLE
          (RowID              int  identity(1,1),
		   CVE_INDICADOR      varchar(10),
		   CVE_TIPO_INDICADOR varchar(2),
		   IMP_PIVOTE         numeric(16,2),
		   iMP_SECUNDARIO     numeric(16,2))
  
  INSERT @TIndPeriodo (CVE_INDICADOR, CVE_TIPO_INDICADOR, IMP_PIVOTE, iMP_SECUNDARIO)  
  SELECT i.CVE_INDICADOR, i.CVE_TIPO_INDICADOR,ip.IMP_PIVOTE, ip.IMP_SECUNDARIO  FROM CI_INDICADOR i, CI_INDICA_PERIODO ip
  WHERE  i.CVE_INDICADOR       =  ip.CVE_INDICADOR   AND
         i.CVE_EMPRESA         =  @pCveEmpresa       AND
         ip.ANO_MES            =  @pAnoMes     
 
  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN         
    SELECT  @cve_indicador = CVE_INDICADOR, @cve_tipo_indicador = CVE_TIPO_INDICADOR,
	        @imp_pivote = IMP_PIVOTE, @imp_secundario = iMP_SECUNDARIO  FROM  @TIndPeriodo 
			WHERE  RowID  =  @RowCount       
    IF  (@cve_tipo_indicador  =  @k_chequera) OR (@imp_pivote = 0 AND @imp_secundario = 0)  
	BEGIN
	  DELETE  FROM  CI_INDICA_PERIODO  WHERE  CVE_EMPRESA   =  @pCveEmpresa  AND ANO_MES = @pAnoMes  AND
	                                          CVE_INDICADOR =  @cve_indicador
	END  
    ELSE
	BEGIN
      UPDATE CI_INDICA_PERIODO  SET IMP_SECUNDARIO = 0 WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND ANO_MES = @pAnoMes  
	END
    SET @RowCount     = @RowCount + 1
  END
END	     