USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION dbo.fnObtSitCxC  (@pIdConciliaCXC int, @pAnoMes varchar(6))
RETURNS varchar(2)						  
AS
BEGIN
  DECLARE @num_registros     int,
          @row_count         int,
          @ano_mes           varchar(6),
		  @f_operacion       date,
		  @cve_moneda        varchar(1),
		  @imp_operacion     numeric(16,2),
		  @sit_concilia      varchar(2)

  DECLARE @sit_conc_real     varchar(2),
          @b_pagos_antes     bit,
		  @b_pagos_despues   bit

  DECLARE @imp_oper_peso     numeric(16,2)
  
  DECLARE @k_dolar           varchar(1)   =  'D',
          @k_cxc             varchar(3)   =  'CXC',
		  @k_conc_total      varchar(2)   =  'CC',
		  @k_conc_error      varchar(2)   =  'CE',
		  @k_conc_antes      varchar(2)   =  'CA',
		  @k_conc_despues    varchar(2)   =  'CD',
          @k_conc_ambos      varchar(2)   =  'CB',
		  @k_no_concilia     varchar(2)   =  'NC',
		  @k_n_conc_antes    varchar(2)   =  'NA',
		  @k_n_conc_despues  varchar(2)   =  'ND',
		  @k_n_conc_ambos    varchar(2)   =  'NB',
		  @k_otra            varchar(2)   =  'OT',
		  @k_verdadero       bit          =  1,
		  @k_falso           bit          =  0
  
-- @k_conc_total


  DECLARE @PAGOS TABLE (RowID int IDENTITY(1, 1), ano_mes varchar(6),f_operacion date, cve_moneda varchar(1), 
                        imp_operacion numeric(12,2), sit_concilia varchar(2))
  
  INSERT INTO @PAGOS  (ano_mes, f_operacion, cve_moneda, imp_operacion, sit_concilia)
  SELECT cc.ANOMES_PROCESO, m.F_OPERACION, ch.CVE_MONEDA, m.IMP_TRANSACCION, f.SIT_CONCILIA_CXC 
  FROM  CI_FACTURA f, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE f.ID_CONCILIA_CXC     =  @pIdConciliaCXC      AND
        f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC   AND
		cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
		m.CVE_CHEQUERA	      =  ch.CVE_CHEQUERA      AND
		m.CVE_TIPO_MOVTO      =  @k_cxc               

  SET @num_registros   = @@ROWCOUNT
  SET @row_count       = 1
  SET @imp_oper_peso   = 0
  SET @b_pagos_antes   = 0
  SET @b_pagos_despues = 0

  IF  @num_registros  <>  0
  BEGIN

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @ano_mes = ano_mes,  @f_operacion =  f_operacion, @cve_moneda = cve_moneda, @imp_operacion  =  imp_operacion, @sit_concilia = sit_concilia
    FROM @PAGOS
    WHERE RowID = @row_count

	SET @b_pagos_antes   = 0
    SET @b_pagos_despues = 0

    IF  @ano_mes  >  @pAnoMes
	BEGIN
	  SET  @b_pagos_despues =  @k_verdadero  
	END  
	IF  @ano_mes  <=  @pAnoMes
	BEGIN
	  SET  @b_pagos_antes   =  @k_verdadero
	END
    SET @row_count = @row_count + 1
  END 

  IF @sit_concilia  IN  (@k_conc_total, @k_conc_error) AND @b_pagos_antes =  @k_verdadero AND  @b_pagos_despues  =  @k_falso
  BEGIN
    SET  @sit_conc_real  =  @k_conc_antes
  END
  ELSE
  BEGIN
     IF @sit_concilia  IN  (@k_conc_total, @k_conc_error) AND @b_pagos_antes =  @k_falso AND  @b_pagos_despues  =  @k_verdadero
     BEGIN
	   SET  @sit_conc_real  =  @k_conc_despues
	 END
     ELSE
	 BEGIN
	   IF @sit_concilia  IN  (@k_conc_total, @k_conc_error) AND @b_pagos_antes =  @k_verdadero AND  @b_pagos_despues  =  @k_verdadero
       BEGIN
	     SET  @sit_conc_real  =  @k_conc_ambos
	   END
	   ELSE
	   BEGIN
	     IF @sit_concilia  IN  (@k_no_concilia) AND @b_pagos_antes =  @k_falso AND @b_pagos_despues =  @k_falso
		 BEGIN
		   SET  @sit_conc_real  =  @k_no_concilia
		 END
		 BEGIN
		   IF  @sit_concilia  IN  (@k_no_concilia) AND @b_pagos_antes =  @k_verdadero  AND  @b_pagos_despues  =  @k_falso
		   BEGIN 
		     SET  @sit_conc_real  =  @k_n_conc_antes
		   END
		   ELSE
		   BEGIN
		     IF  @sit_concilia  IN  (@k_no_concilia) AND @b_pagos_antes =  @k_falso  AND  @b_pagos_despues  =  @k_verdadero  
             BEGIN
			   SET  @sit_conc_real  =  @k_n_conc_despues
			 END
			 ELSE
			 BEGIN
			   IF  @sit_concilia  IN  (@k_no_concilia) AND @b_pagos_antes =  @k_verdadero  AND  @b_pagos_despues  =  @k_verdadero
			   BEGIN
                 SET  @sit_conc_real  =  @k_n_conc_ambos
			   END
			   ELSE
			   BEGIN
      		     SET  @sit_conc_real  =  @k_otra
			   END
			 END
		   END
		 END
	   END
	 END
  END

  END
  ELSE
  BEGIN
    SET  @sit_conc_real  =  @k_no_concilia
  END
  RETURN @sit_conc_real
END

