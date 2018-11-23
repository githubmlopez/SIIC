	 USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[spCalDatosCXCtaEvento]    Script Date: 01/10/2016 07:51:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter  PROCEDURE [dbo].[spCalDatosCXC] @pid_concilia_cxc  int,
                                       @pcve_com_liq      varchar(1),
                                       @p_cve_r_moneda    varchar(1),
									   @pimp_calculo      numeric(12,2)  OUT,
									   @p_cve_l_moneda    varchar(1) OUT,
									   @p_tipo_cambio     numeric(8,4)
									   
                                          
AS

BEGIN

  DECLARE  @id_mov_bancario     int,
		   @imp_transaccion     numeric(12,2),
		   @imp_cargos          numeric(12,2),
		   @imp_acum_abono      numeric(12,2),
		   @tipo_cambio         numeric(8,4),
           @f_operacion         date,
		   @cve_r_moneda        varchar(1),
		   @cve_cargo_abono     varchar(1)
  
  DECLARE  @k_verdadero         varchar(1),
           @k_falso             varchar(1),
           @k_cargo             varchar(1),
		   @k_abono             varchar(1),
           @k_peso              varchar(1),
           @k_dolares           varchar(1),
           @k_ll_parametro      varchar(4),
		   @k_comisionable      varchar(1),
		   @k_normal            varchar(1),
           @k_combinada         varchar(1)

  DECLARE  @caso                int,
  		   @pje_iva             numeric(8,4),
		   @NunRegistros        int,
           @RowCount            int
		 
  SET @k_verdadero       =  1
  SET @k_falso           =  0
  SET @k_abono           = 'A'
  SET @k_cargo           = 'C'
  SET @k_verdadero       =  0
  SET @k_peso            = 'P'
  SET @k_dolares         = 'D'
  SET @k_comisionable    = 'C'
  SET @k_normal          = 'N'
  SET @k_ll_parametro    = 'IVA'

  SET @imp_transaccion   = 0
  SET @imp_cargos        = 0
  SET @pimp_calculo      = 0


  SELECT @pje_iva = VALOR_NUMERICO FROM CI_PARAMETRO WHERE CVE_PARAMETRO = @k_ll_parametro

  EXEC spDetCasoFacturaCom @pid_concilia_cxc, @caso OUT

  SELECT ' Caso ' + convert(varchar(16), dbo.fnDetCasoFacturaCom(@pid_concilia_cxc))
  IF  @caso  =  0
  BEGIN
    SET  @pimp_calculo      =  0
  END
  ELSE
  BEGIN
    IF  @caso  IN (1,2)
	BEGIN

	  CREATE TABLE #mov_bancario (
              RowID              int IDENTITY(1, 1), 
              ID_MOVTO_BANCARIO  int,
		      IMP_TRANSACCION    numeric(12,2),
              F_OPERACION        date,
			  CVE_R_MONEDA       varchar(1),
			  CVE_CARGO_ABONO    varchar(1))

      INSERT INTO #mov_bancario (ID_MOVTO_BANCARIO, IMP_TRANSACCION, F_OPERACION, CVE_R_MONEDA, CVE_CARGO_ABONO)
	  SELECT m.ID_MOVTO_BANCARIO,
             m.IMP_TRANSACCION,
			 m.F_OPERACION,
			 ch.CVE_MONEDA,
			 m.CVE_CARGO_ABONO
			 FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_CONCILIA_C_X_C cc
			 WHERE
			 cc.ID_CONCILIA_CXC    =   @pid_concilia_cxc    AND
			 cc.ID_MOVTO_BANCARIO  =   m.ID_MOVTO_BANCARIO  AND
			 m.CVE_CHEQUERA        =   ch.CVE_CHEQUERA
      
      SET @NunRegistros = @@ROWCOUNT
      SET @RowCount     = 1

      WHILE @RowCount <= @NunRegistros
      BEGIN
		SELECT ' ** ARRANCO CLCLO **'
		SELECT @id_mov_bancario = ID_MOVTO_BANCARIO, @imp_transaccion = IMP_TRANSACCION, 
		       @f_operacion = F_OPERACION, @cve_r_moneda = CVE_R_MONEDA, @cve_cargo_abono = CVE_CARGO_ABONO
        FROM   #mov_bancario
        WHERE  RowID = @RowCount

		SET @tipo_cambio = ISNULL(dbo.fnObtTipoCamb(@f_operacion),0)

		SET  @p_cve_l_moneda    =  0
		SET  @p_tipo_cambio     =  0

        IF  @cve_cargo_abono  =  @k_abono AND @cve_r_moneda =  @k_dolares
		BEGIN

		  SET  @p_cve_l_moneda    =  @cve_r_moneda
		  SET  @p_tipo_cambio     =  ((@tipo_cambio * @imp_transaccion) * (@p_tipo_cambio * @imp_acum_abono)) /
		                             (@imp_transaccion + @imp_acum_abono)
		  SET  @imp_acum_abono    =  @imp_acum_abono  +  @imp_transaccion
		END 
		
		SELECT  @pcve_com_liq + ' ' + @cve_cargo_abono

        IF 	@pcve_com_liq         =   @k_comisionable      OR
    	   (@pcve_com_liq         =   @k_normal            AND
    		@cve_cargo_abono      <>  @k_cargo)

        BEGIN
		SELECT ' ENTRO A ACUMULAR '
          IF  @pcve_com_liq  =  @k_comisionable  AND  @cve_cargo_abono  <>  @k_cargo 
		  BEGIN
		    SET @imp_transaccion = @imp_transaccion / (1 + (@pje_iva / 100)) 
		  END
	    
		  IF  @cve_r_moneda  =  @k_dolares  AND  @p_cve_r_moneda =  @k_peso
		  BEGIN
		    SET @imp_transaccion = @imp_transaccion *  @tipo_cambio
		  END
		  SELECT @cve_r_moneda + ' ' + @p_cve_r_moneda + ' ' + @cve_cargo_abono
		  IF  @cve_r_moneda  =  @k_peso  AND  @p_cve_r_moneda =  @k_dolares
		  BEGIN
		    SET @imp_transaccion = @imp_transaccion /   @tipo_cambio
		  END

    	  IF  @cve_cargo_abono  =  @k_cargo 
          BEGIN
            SET @pimp_calculo      =  @pimp_calculo  -  @imp_transaccion
          END
          ELSE
          BEGIN
            SET  @pimp_calculo      =  @pimp_calculo  +  @imp_transaccion

          END
        
		SELECT 'IMP ==> ' + CONVERT(VARCHAR(20), @imp_transaccion) + ' ' + CONVERT(VARCHAR(20), @pimp_calculo)

        END

		SET @RowCount = @RowCount + 1 
	  
	  END
    END
    ELSE
	BEGIN
	  IF @caso  IN (3,4) 
	  BEGIN
	    EXEC spCCProrrateaPago   @pid_concilia_cxc

		SET  @p_cve_l_moneda    =  0
		SET  @p_tipo_cambio     =  0

        IF  @cve_r_moneda  =  @k_dolares  AND  @p_cve_r_moneda =  @k_peso
		BEGIN
		  SET @imp_transaccion = @imp_transaccion *  @tipo_cambio
		END
		
		SELECT @cve_r_moneda + ' ' + @p_cve_r_moneda + ' ' + @cve_cargo_abono
		
		IF  @cve_r_moneda  =  @k_peso  AND  @p_cve_r_moneda =  @k_dolares
		BEGIN
		  SET @imp_transaccion = @imp_transaccion /   @tipo_cambio
		END

		SET @imp_cargos  =  0

		IF  @caso  =  4  AND  @pcve_com_liq  =  @k_comisionable
		BEGIN
		  SET @imp_cargos =  (SELECT SUM(m.IMP_TRANSACCION) FROM CI_MOVTO_BANCARIO m, CI_CONCILIA_C_X_C cc
		                      WHERE  cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
							         cc.ID_CONCILIA_CXC    =  @pid_concilia_cxc    AND
									 m.CVE_CARGO_ABONO     =  @k_cargo)
		END
		  
	    SET @id_mov_bancario = (SELECT cc.ID_MOVTO_BANCARIO FROM  CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
		                        WHERE cc.ID_CONCILIA_CXC    =   @pid_concilia_cxc      AND
								      cc.ID_MOVTO_BANCARIO  =   m.ID_MOVTO_BANCARIO    AND
									  m.CVE_CARGO_ABONO     <>  @k_cargo)  	

		SELECT @imp_transaccion = cc.IMP_PAGO_AJUST,  @cve_r_moneda  = ch.CVE_MONEDA,
		       @f_operacion = m.F_OPERACION, @cve_cargo_abono = m.CVE_CARGO_ABONO
    		   FROM  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_CONCILIA_C_X_C cc
	           WHERE m.ID_MOVTO_BANCARIO  =  @id_mov_bancario   AND
			         m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
				     m.ID_MOVTO_BANCARIO  =  cc.ID_MOVTO_BANCARIO AND
				     cc.ID_CONCILIA_CXC   =  @pid_concilia_cxc    AND
                     m.CVE_CARGO_ABONO    <> @k_cargo

		SELECT ' ENTRO A ACUMULAR ' 

	    IF  @pcve_com_liq  =  @k_comisionable  
		BEGIN
		  SET @imp_transaccion = @imp_transaccion / (1 + (@pje_iva / 100)) 
		END
	    
		IF  @cve_r_moneda  =  @k_dolares  AND  @p_cve_r_moneda =  @k_peso
		BEGIN
		  SET @imp_transaccion = @imp_transaccion *  dbo.fnObtTipoCamb(@f_operacion)
		  SET @imp_cargos      = @imp_cargos *  dbo.fnObtTipoCamb(@f_operacion)
		END
		SELECT @cve_r_moneda + ' ' + @p_cve_r_moneda + ' ' + @cve_cargo_abono
		IF  @cve_r_moneda  =  @k_peso  AND  @p_cve_r_moneda =  @k_dolares
		BEGIN
		  SET @imp_cargos = @imp_cargos /  dbo.fnObtTipoCamb(@f_operacion)
		  SET @imp_transaccion = @imp_transaccion /  dbo.fnObtTipoCamb(@f_operacion)
		END

		SET  @pimp_calculo      =  @imp_transaccion - @imp_cargos 

        END
        
		SELECT 'IMP ==> ' + CONVERT(VARCHAR(20), @imp_transaccion) + ' ' + CONVERT(VARCHAR(20), @pimp_calculo) + ' * ' +
		CONVERT(VARCHAR(20), @imp_cargos)
	END
  
  END     
END
