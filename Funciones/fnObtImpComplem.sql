USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnObtImpComplem]    Script Date: 08/06/2018 03:58:07 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnObtImpComplem]
(
@pCveEmpresa   varchar(4),
@pAnoMes       varchar(6),
@pCveChequera  varchar(6),
@pFOperacion   date,
@pIdMovto      int,
@pCveMoneda    varchar(4),
@pImpMovto  numeric(16,2))
RETURNS numeric(16,2)
-- WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE  @k_pesos   varchar(1) =  'P',
           @k_dolares varchar(1) =  'D'

  DECLARE  @imp_complemento  numeric(16,2) =  0,
           @ano_mes          varchar(6),
		   @cve_chequera     varchar(6),
		   @id_movto         int,
   		   @cve_moneda_r     varchar(1),
		   @imp_movto_r      numeric(16,2)

  IF  @pCveMoneda   =  @k_dolares
  BEGIN
	IF  EXISTS  (SELECT 1 FROM CI_TRASP_BANCARIO  WHERE  
	             ANO_MES            =  @pAnoMes       AND
				 CVE_CHEQUERA       =  @pCveChequera  AND
				 ID_MOVTO_BANCARIO  =  @pIdMovto)     
    BEGIN
	  SELECT @ano_mes  =  ANO_MES_R,  @cve_chequera  =  CVE_CHEQUERA_R, @id_movto  =  ID_MOVTO_BANCARIO_R,
	          @cve_moneda_r   =  ch.CVE_MONEDA, @imp_movto_r = m.IMP_TRANSACCION
	         FROM CI_TRASP_BANCARIO t, CI_CHEQUERA ch, CI_MOVTO_BANCARIO m WHERE  
	              t.ANO_MES              =  @pAnoMes        AND
		          t.CVE_CHEQUERA         =  @pCveChequera   AND
			      t.ID_MOVTO_BANCARIO    =  @pIdMovto       AND
				  t.CVE_CHEQUERA_R       =  ch.CVE_CHEQUERA AND
				  t.ANO_MES_R            =  m.ANO_MES       AND
				  t.CVE_CHEQUERA_R       =  m.CVE_CHEQUERA  AND
				  t.ID_MOVTO_BANCARIO_R  =  m.ID_MOVTO_BANCARIO   

	  IF   @cve_moneda_r =  @k_pesos
      BEGIN
		SET  @imp_complemento  =   @imp_movto_r - @pImpMovto
	  END
      ELSE
	  BEGIN
		SET  @imp_complemento  = (@pImpMovto *
		     dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @pFOperacion)) - @pImpMovto
	  END
	END  
    ELSE
	BEGIN
      SET  @imp_complemento  = (@pImpMovto *
	       dbo.fnObtTipoCambC(@pCveEmpresa, @pAnoMes, @pFOperacion)) - @pImpMovto
	END
  END
  ELSE
  BEGIN
    SET  @imp_complemento = 0
  END
  RETURN  @imp_complemento
END

