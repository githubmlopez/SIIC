USE [ADNOMINA01]
GO
/****** Calcula Informacion del Bimestre Anterior para Ingresos Variables ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCalcInfBimAnt] (@pIdCliente       int,
                                          @pCveEmpresa      varchar(4),
										  @pIdEmpleado      int,
								          @pCveTipoNomina   varchar(2),
									      @pAnoPeriodo      varchar(6),
                                          @pSalBimAnt       numeric(16,2) OUT,
										  @pSdoDiaBimAnt    numeric(16,2) OUT,
                        				  @pDiasBimAnt      int OUT,
                                          @pIncapBimAnt     int OUT,
										  @pFaltasBimAnt    int OUT)

AS
BEGIN
  DECLARE  @ano_bimestre       varchar(4)     =  ' ',
           @num_bimestre       varchar(2)     =  ' ',
           @cve_bim_ant        varchar(6)     =  ' ',
		   @ano_periodo        varchar(6)     =  ' ',
           @dias_bim_ant       int            =  0,
		   @acum_percep        numeric(16,2)  =  0,
		   @dias_incap         int            =  0,
		   @dias_falta         int            =  0

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_prim_bim         varchar(2)     =  '01'
  DECLARE  @k_ult_bim          varchar(2)     =  '06',
           @k_verdadero        bit            =  1

  IF EXISTS(
  SELECT 1 FROM NO_PERIODO p  WHERE 
  p.ID_CLIENTE      = @pIdCliente      AND
  p.CVE_EMPRESA     = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
  p.ANO_PERIODO     = @pAnoPeriodo)      
  BEGIN
      SELECT @ano_bimestre =  SUBSTRING(p.CVE_BIMESTRE,1,4), @num_bimestre = SUBSTRING(p.CVE_BIMESTRE,5,2)
	  FROM NO_PERIODO p  WHERE 
      p.ID_CLIENTE      = @pIdCliente      AND
      p.CVE_EMPRESA     = @pCveEmpresa     AND
      p.CVE_TIPO_NOMINA = @pCveTipoNomina  AND
      p.ANO_PERIODO     = @pAnoPeriodo      
  END
  ELSE
  BEGIN
    SET  @ano_bimestre    =  ' '
	SET  @num_bimestre    =  ' '
  END

  IF  @num_bimestre  =  @k_prim_bim
  BEGIN
    SET  @cve_bim_ant  =  CONVERT(VARCHAR(4),CONVERT(INT,@ano_bimestre) - 1)  +
	                      @k_ult_bim
  END
  ELSE
  BEGIN
    SET  @cve_bim_ant  =  @ano_bimestre  +
	replicate ('0',(02 - len(CONVERT(INT,@num_bimestre) -1))) + convert(varchar, CONVERT(INT,@num_bimestre -1))
  END

-------------------------------------------------------------------------------
-- Calculo de periodos del bimestre anterior
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TPeriodo         TABLE
          (RowID             int  identity(1,1),
		   ANO_PERIODO       varchar(6))

  INSERT  @TPeriodo(ANO_PERIODO) 
  SELECT  p.ANO_PERIODO
  FROM    NO_PERIODO p
  WHERE
  p.ID_CLIENTE       = @pIdCliente      AND
  p.CVE_EMPRESA      = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
  p.ID_CVE_BIMESTRE  = @cve_bim_ant

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_periodo = ANO_PERIODO
	FROM   @TPeriodo  WHERE  RowID = @RowCount

	SET @acum_percep  =  0

    SELECT  @acum_percep = isnull(SUM(n.IMP_CONCEPTO),0)
    FROM    NO_NOMINA n
    WHERE
    p.ID_CLIENTE       = @pIdCliente      AND
    p.CVE_EMPRESA      = @pCveEmpresa     AND
    p.CVE_TIPO_NOMINA  = @pCveTipoNomina  AND
    p.ANO_PERIODO      = @ano_periodo     AND
	p.CVE_CONCEPTO     IN
	(SELECT c.CVE_CONCEPTO FROM NO_CONCEPTO c WHERE
	 c.ID_CLIENTE      = @pIdCliente      AND
     c.CVE_EMPRESA     = @pCveEmpresa     AND
	 c.B_GRABABLE      = @k_verdadero) 

    SET  @pSdoDiaBimAnt  =  @pSdoDiaBimAnt  + @acum_percep

    EXEC spCalNumIncap  @pIdCliente,
                        @pCveEmpresa,
		                @pIdEmpleado,
			            @pCveTipoNomina,
					    @pAnoPeriodo,
					    @dias_incap  OUT

    SET  @pIncapBimAnt  =  @pIncapBimAnt  +  @dias_incap

    SET @RowCount     = @RowCount + 1

  END

  EXEC spCalNumFaltas  @pIdCliente,
                       @pCveEmpresa,
	                   @pIdEmpleado,
		               @pCveTipoNomina,
			           @pAnoPeriodo,
					   @pFaltasBimAnt  OUT

  SET  @pDiasBimAnt   =  ISNULL((SELECT DIAS_BIMESTRE FROM NO_BIMESTRE  WHERE CVE_BIMESTRE = @cve_bim_ant),0)
  SET  @pSdoDiaBimAnt =  @sdo_bim_ant / @pDiasBimAnt
END

