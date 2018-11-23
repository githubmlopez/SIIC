USE [ADMON01]
GO

--exec spTranFacturacion 'CU', 'MARIO', '201601', 1, 130, ' ', ' '
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE spPrepPagoParcial  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                   @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
	 							   @pMsgError varchar(400) OUT
AS
BEGIN
  DECLARE  @k_parcial  varchar(2)  =  'CP',
           @k_activa   varchar(1)  =  'A',
		   @k_error    varchar(1)  =  'E'

  DECLARE  @num_registros int,
           @row_count     int,
		   @imp_movtos    numeric(12,2),
		   @imp_mov_acum  numeric(12,2)

  DECLARE  @cve_empresa     varchar(4),
           @serie           varchar(6),
		   @id_cxc          int,
		   @id_concilia_cxc int
  
  DECLARE  @imp_acum_b_Peso  numeric(12,2),
           @imp_acum_i_peso  numeric(12,2),
           @imp_acum_n_peso  numeric(12,2),
		   @imp_acum_b_dolar numeric(12,2),
	       @imp_acum_i_dolar numeric(12,2),
		   @imp_acum_n_dolar numeric(12,2),
		   @cve_moneda       varchar(1)	  

    
  DECLARE @PARCIALES TABLE (RowID int IDENTITY(1, 1), CVE_EMPRESA varchar(4), SERIE varchar(6), ID_CXC int, ID_CONCILIA_CXC int)
   
  INSERT  INTO @PARCIALES (CVE_EMPRESA, SERIE, ID_CXC, ID_CONCILIA_CXC)
  SELECT CVE_EMPRESA, SERIE, ID_CXC, ID_CONCILIA_CXC 
  FROM  CI_FACTURA f
  WHERE f.SIT_CONCILIA_CXC    =  @k_parcial           AND
		f.SIT_TRANSACCION     =  @k_activa            

  SET @num_registros = @@ROWCOUNT
  SET @row_count     = 1
  SET @imp_movtos    = 0

  WHILE @row_count <= @num_registros
  BEGIN
    SELECT @cve_empresa =  CVE_EMPRESA, @serie = SERIE, @id_cxc  =  ID_CXC, @id_concilia_cxc = ID_CONCILIA_CXC
    FROM @PARCIALES
    WHERE RowID = @row_count

    BEGIN TRY
	
	  DELETE FROM  CI_PAG_ACUM_FACT
	         WHERE ANO_MES      =  @pAnoMes      AND
		  	       CVE_EMPRESA  =  @cve_empresa  AND
			  	   SERIE        =  @serie        AND
				   ID_CXC       =  @id_cxc
	
      EXEC  spAcumMovtosBanc  @id_concilia_cxc, @pAnoMes,
	                          @imp_acum_b_Peso OUT, @imp_acum_i_peso,
                              @imp_acum_n_peso OUT, @imp_acum_b_dolar OUT,
						      @imp_acum_i_dolar OUT, @imp_acum_n_dolar	OUT, @cve_moneda OUT	  

	  IF  @imp_acum_n_peso <>  0  OR  @imp_acum_n_dolar  <>  0
	  BEGIN
	    INSERT  INTO CI_PAG_ACUM_FACT  (ANO_MES, CVE_EMPRESA, SERIE, ID_CXC, CVE_MONEDA, IMP_ACUM_B_PESO, IMP_ACUM_I_PESO,
		                                IMP_ACUM_N_PESO, IMP_ACUM_B_DOLAR, IMP_ACUM_I_DOLAR, IMP_ACUM_N_DOLAR)  VALUES
	    (@pAnoMes, @cve_empresa, @serie, @id_cxc, @cve_moneda, @imp_acum_b_Peso, @imp_acum_i_peso,
         @imp_acum_n_peso, @imp_acum_b_dolar, @imp_acum_i_dolar, @imp_acum_n_dolar)
      END
	END TRY

	BEGIN CATCH
      SET  @pError    =  'Error de Ejecucion Proceso Prepara Anticipados'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END CATCH

	SET @row_count = @row_count + 1

  END
END