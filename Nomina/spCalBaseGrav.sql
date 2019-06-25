USE [ADNOMINA01]
GO
/* Calcula Base Gravable de Percepciones   */

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalBaseGrav')
BEGIN
  DROP  PROCEDURE  spCalBaseGrav
END
GO
--EXEC 'spAcumPeriodo' 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,' ',' '
CREATE PROCEDURE [dbo].[spCalBaseGrav]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pError           varchar(80)   OUT,
@pMsgError        varchar(400)  OUT

)
AS
BEGIN
  DECLARE @cve_concepto      varchar(4)    =  ' ',
          @imp_concepto      int           =  0,
		  @cve_tipo_cal_grav varchar(4)    =  ' ',
		  @num_umas_grab     int           =  0,
		  @b_exento          bit           =  0

  DECLARE @NunRegistros      int           =  0,
          @RowCount          int           =  0,
		  @uma               numeric(16,2) =  0,
		  @num_semanas       int           =  0,
		  @num_domingos      int           =  0,
		  @imp_base_excen    numeric(16,2) =  0,
		  @dias_ano          int           =  0,
		  @num_anos_antig    int           =  0,
		  @factor            int           =  0

  DECLARE @k_verdadero       bit  =  1,
          @k_falso           bit  =  0,
		  @k_percepcion      varchar(1)    =  'P',
		  @k_otr_ing         varchar(1)    =  'O',
          @k_uma_nor         varchar(4)    =  'UMNO',
		  @k_uma_dom         varchar(4)    =  'UMDO', 
		  @k_uma_serv        varchar(4)    =  'UMSE',
		  @k_uma_elev        varchar(4)    =  'UMEA',
		  @k_excento         varchar(4)    =  'EXCE'

-------------------------------------------------------------------------------
-- Obtener registros de Prenomina
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TPreNomina       TABLE
          (RowID             int  identity(1,1),
		   CVE_CONCEPTO      varchar(4),
		   IMP_CONCEPTO      numeric(16,2),
		   NUM_UMAS_GRAV     int,
		   CVE_TIPO_CAL_GRAV varchar(4))
		   
  INSERT  @TPreNomina (CVE_CONCEPTO, IMP_CONCEPTO, NUM_UMAS_GRAV, CVE_TIPO_CAL_GRAV)
  SELECT  p.CVE_CONCEPTO, p.IMP_CONCEPTO, c.NUM_UMAS_GRAV, CVE_TIPO_CAL_GRAV
  FROM    NO_PRE_NOMINA p, NO_CONCEPTO c
  WHERE   p.ANO_PERIODO     =  @pAnoPeriodo    AND
          p.ID_CLIENTE      =  @pIdCliente     AND
		  p.CVE_EMPRESA     =  @pCveEmpresa    AND
		  p.CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		  p.ID_EMPLEADO     =  @pIdEmpleado    AND
		  p.ID_CLIENTE      =  c.ID_CLIENTE    AND
		  p.CVE_EMPRESA     =  c.CVE_EMPRESA   AND
		  p.CVE_CONCEPTO    =  c.CVE_CONCEPTO  AND
		  c.CVE_TIPO_CONCEPTO IN (@k_percepcion, @k_otr_ing)

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------

  SET @RowCount     = 1

-- Obtener UMA de la Empresa

  SELECT  @uma  =  UMA, @dias_Ano = DIAS_ANO
  FROM    NO_EMPRESA e
  WHERE   e.ID_CLIENTE      =  @pIdCliente     AND
		  e.CVE_EMPRESA     =  @pCveEmpresa

-- Obtener número de Domingos u semanas del periodo

  SELECT  @num_domingos = NUM_DOMINGOS, @num_semanas  =  NUM_SEMANAS
  FROM    NO_PERIODO p
  WHERE   p.ANO_PERIODO     =  @pAnoPeriodo    AND
          p.ID_CLIENTE      =  @pIdCliente     AND
		  p.CVE_EMPRESA     =  @pCveEmpresa    AND
		  p.CVE_TIPO_NOMINA =  @pCveTipoNomina 

-- Obtener años de antiguedad del empleado

  SELECT  @num_anos_antig = NUM_ANOS_ANTIG
  FROM    NO_INF_EMP_PER i
  WHERE   i.ANO_PERIODO     =  @pAnoPeriodo    AND
          i.ID_CLIENTE      =  @pIdCliente     AND
		  i.CVE_EMPRESA     =  @pCveEmpresa    AND
		  i.CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		  i.ID_EMPLEADO     =  @pIdEmpleado
		   
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_concepto = CVE_CONCEPTO, @imp_concepto = IMP_CONCEPTO, @cve_tipo_cal_grav = CVE_TIPO_CAL_GRAV,
	@num_umas_grab  =  NUM_UMAS_GRAV
	FROM @TPreNomina  WHERE  RowID = @RowCount

	IF  @cve_tipo_cal_grav  <>  @k_excento
	BEGIN

      IF   @cve_tipo_cal_grav IN (@k_uma_nor,@k_uma_dom,@k_uma_serv,@k_uma_elev)
      BEGIN
	    SET @factor  =  1

        IF  @cve_tipo_cal_grav =  @k_uma_dom 
	    BEGIN
          SET  @factor  =  @num_domingos       
	    END

	    IF  @cve_tipo_cal_grav =  @k_uma_elev 
	    BEGIN
          SET  @factor  =  @dias_ano       
	    END

        IF  @cve_tipo_cal_grav =  @k_uma_elev 
	    BEGIN
          SET  @factor  =  @num_anos_antig       
	    END

        SET  @imp_base_excen  =  @num_umas_grab * @uma * @factor       

      END
	  ELSE
	  BEGIN
	    SET  @imp_base_excen  =  0
	  END

    END
    ELSE
	BEGIN
      SET  @imp_base_excen  =  @imp_concepto
	END

	SET @RowCount     = @RowCount + 1

  END
END