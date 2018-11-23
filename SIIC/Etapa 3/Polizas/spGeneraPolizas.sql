USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--exec spGeneraPolizas 'CU', 'MARIO', '201601', 1, 361, ' ', ' '
 
ALTER PROCEDURE spGeneraPolizas  @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                  @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								  @pMsgError varchar(400) OUT
AS
BEGIN

  DECLARE
  @cve_poliza           varchar(6),
  @desc_poliza          varchar(30),
  @id_transaccion       int,
  @cve_oper_cont        varchar(4),
  @cve_num_cuenta       varchar(30),
  @cve_depto            varchar(30),
  @cve_concepto         varchar(30),
  @cve_tipo_cambio      varchar(30),
  @cve_debe             varchar(30),
  @cve_haber            varchar(30),
  @cve_proyecto         varchar(30)

  DECLARE 
  @cta_contable_p      varchar(30),
  @desc_departamento_p varchar(120),
  @conc_movimiento_p   varchar(400),
  @tipo_cambio_p       numeric(8,4),
  @imp_debe_p          numeric(16,2),
  @imp_haber_p         numeric(16,2),
  @proyecto_p            varchar(50)
  
  DECLARE
  @k_error              varchar(1)  =  'E',
  @k_warning            varchar(1)  =  'W',
  @k_activa             varchar(1)  =  'A',
  @k_verdadero          bit         =   1,
  @k_no_aplica          varchar(2)  =  'NA',
  @k_iva_pesos          varchar(4)  =  'IMIP',
  @k_iva_dolares        varchar(4)  =  'IMID'

  DECLARE
  @Id_enca_poliza_p     int,
  @importe              numeric(14,4),
  @valor                varchar(400),
  @estatus              varchar(1),
  @estatus_enca         varchar(1),
  @cve_oper_cont_d      varchar(4),
  @cve_oper_cont_h      varchar(4)


  SET  @pError           =  ' '
  SET  @pMsgError        =  ' '
 
 
  SELECT @cve_poliza  =  SUBSTRING(PARAMETRO,1,4) FROM FC_GEN_PROCESO  WHERE CVE_EMPRESA  =  @pCveEmpresa  AND
                                                                             ID_PROCESO   =  @pIdProceso


  -- Borra Cifras de Control asociadas
  
  --DELETE FC_CIFRA_CONTROL
  --   WHERE 
	 --CVE_EMPRESA    =  @pCveEmpresa    AND
  --   ANO_MES        =  @pAnoMes        AND        
  --   ID_PROCESO     =  @pIdProceso     AND
	 --CONCEPTO_PROC IN  (@cve_poliza)

--  Borra detalles correspondientes a la clave de poliza

  DELETE  CI_DET_POLIZA WHERE
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ANO_MES      =  @pAnoMes      AND
  CVE_POLIZA   =  @cve_poliza   AND
  (SELECT B_AUTOMATICA FROM CI_ENCA_POLIZA e WHERE  
   e.CVE_EMPRESA    = CI_DET_POLIZA.CVE_EMPRESA    AND
   e.ANO_MES        = CI_DET_POLIZA.ANO_MES        AND
   e.CVE_POLIZA     = CI_DET_POLIZA.CVE_POLIZA     AND
   e.ID_ENCA_POLIZA = CI_DET_POLIZA.ID_ENCA_POLIZA)  = @k_verdadero   

--  Borra encabezados correspondientes a la clave de poliza

  DELETE  CI_ENCA_POLIZA  WHERE
  CVE_EMPRESA    =  @pCveEmpresa  AND
  ANO_MES        =  @pAnoMes      AND
  CVE_POLIZA     =  @cve_poliza   AND
  ID_ENCA_POLIZA =  @k_verdadero
   
 -- SELECT 'CLAVE POLIZA ' + '*' + @pCveEmpresa + '*' + @cve_poliza + '*'  + @pAnoMes + '*' + @k_activa 
  DECLARE cur_poliza CURSOR FOR SELECT
  c.CVE_POLIZA,
  c.DESC_POLIZA,
  t.ID_TRANSACCION,
  t.CVE_OPER_CONT,
  g.CVE_NUM_CUENTA,
  g.CVE_DEPTO,
  g.CVE_CONCEPTO,
  g.CVE_TIPO_CAMBIO,
  g.CVE_DEBE,
  g.CVE_HABER,
  g.CVE_PROYECTO
  FROM   CI_CAT_POLIZA c, CI_POLIZA_TRANSAC p, CI_GUIA_CONTABLE g, CI_TRANSACCION_CONT t
  WHERE  c.CVE_EMPRESA     =  @pCveEmpresa      AND
         c.CVE_POLIZA      =  @cve_poliza       AND
         c.CVE_EMPRESA     =  p.CVE_EMPRESA     AND
		 c.CVE_POLIZA      =  p.CVE_POLIZA      AND
		 p.CVE_EMPRESA     =  t.CVE_EMPRESA     AND
		 p.CVE_OPER_CONT   =  t.CVE_OPER_CONT   AND
         p.CVE_EMPRESA     =  g.CVE_EMPRESA     AND
         t.ANO_MES         =  @pAnoMes          AND
		 t.CVE_EMPRESA     =  @pCveEmpresa      AND
		 t.CVE_OPER_CONT   =  g.CVE_OPER_CONT   AND
		 t.SIT_TRANSACCION =  @k_activa       
				   
  open  cur_poliza
  
  FETCH cur_poliza INTO
  @cve_poliza,
  @desc_poliza,
  @id_transaccion,
  @cve_oper_cont,
  @cve_num_cuenta,
  @cve_depto,
  @cve_concepto,
  @cve_tipo_cambio,
  @cve_debe,
  @cve_haber,
  @cve_proyecto
 -- SELECT ' CREO ENCABEZADO'
  EXEC  spCreaEncaPoliza @pIdTarea, @pIdProceso, @pCveEmpresa, @pAnoMes, @cve_poliza, @desc_poliza, @Id_enca_poliza_p OUT, 
                         @pError OUT, @pMsgError OUT
  -- SELECT ' SALI CREAR ENCABEZADO'
  BEGIN TRY

  IF  @pError  =  ' '
  BEGIN
  
--  select ' Entro a Cursor '
  
    WHILE (@@fetch_status = 0 )
    BEGIN 
 
-- Cuenta Contable
      SET @estatus  =  ' '
--	  SELECT ' CUENTA CONTABLE '
	  
	  EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_num_cuenta,
	                        @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
      IF  @estatus  IN  (@k_error, @k_warning) 
	  BEGIN
	    SET @estatus_enca  =  @estatus
	  END
	  ELSE
	  BEGIN
	    SET @cta_contable_p  =  @valor
	  END

-- Descripcion Departamento	  @desc_departamento_p
  --    SELECT ' DEPARTAMENTO '
	  EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_depto,
	                        @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
      IF  @estatus  IN  (@k_error, @k_warning) 
	  BEGIN
	    SET @estatus_enca  =  @estatus
	  END
	  ELSE
	  BEGIN
	    SET @desc_departamento_p  =  @valor
	  END

-- Concepto del movimiento 	  @conc_movimiento_p
   --   SELECT ' CONCEPTO '
	  EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_concepto,
	                        @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
      IF  @estatus  IN  (@k_error, @k_warning) 
	  BEGIN
	    SET @estatus_enca  =  @estatus
	  END
	  ELSE
	  BEGIN
	    SET @conc_movimiento_p  =  @valor
	  END

-- Tipo de Cambio
-- SELECT ' TIPO DE CAMBIO '

      IF  @cve_tipo_cambio  <> @k_no_aplica
	  BEGIN
	    EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_tipo_cambio,
	                          @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
-- SELECT ' IMPORTE ' + CONVERT(VARCHAR(26),@importe) 	                        
        IF  @estatus  IN  (@k_error, @k_warning) 
	    BEGIN
	      SET @estatus_enca  =  @estatus
	    END
	    ELSE
	    BEGIN
	      SET @tipo_cambio_p  =  @importe
	    END
	  END
      ELSE
	  BEGIN
	    SET @tipo_cambio_p  =  1
	  END

-- Debe
 -- SELECT ' DEBE '
 
      IF  @cve_debe  <> @k_no_aplica
	  BEGIN
	    SET   @cve_oper_cont_d  =  @cve_oper_cont
		EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_debe,
	                          @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
        IF  @estatus  IN  (@k_error, @k_warning) 
	    BEGIN
	      SET @estatus_enca  =  @estatus
	    END
	    ELSE
	    BEGIN
	      SET @imp_debe_p  =  @importe
    	END
      END
	  ELSE
	  BEGIN
	    SET @imp_debe_p  =  0
	  END
-- Haber
-- SELECT ' HABER '
      IF  @cve_haber  <> @k_no_aplica 
      BEGIN
   	    SET   @cve_oper_cont_h  =  @cve_oper_cont

		EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_haber,
	                          @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
        IF  @estatus  IN  (@k_error, @k_warning) 
	    BEGIN
	      SET @estatus_enca  =  @estatus
	    END
	    ELSE
	    BEGIN
	      SET @imp_haber_p  =  @importe
	    END
	  END
	  ELSE
	  BEGIN
	    SET @imp_haber_p  =  0
	  END
-- Proyecto

	  EXEC  spObtValorCpto  @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @id_transaccion, @cve_oper_cont, @cve_proyecto,
	                        @importe OUT, @valor OUT, @estatus OUT, @pError,  @pMsgError
	                        
      IF  @estatus  IN  (@k_error, @k_warning) 
	  BEGIN
	    SET @estatus_enca  =  @estatus
	  END
	  ELSE
	  BEGIN
	    SET @proyecto_p  =  @valor
	  END

	  IF  @estatus_enca  IN (@k_error, @k_warning)  
	  BEGIN
--	    SELECT ' ERROR VOY A ACTUALIZAR ESTATUS'
		UPDATE  CI_ENCA_POLIZA  SET SIT_POLIZA = @estatus_enca  where CVE_EMPRESA    =  @pCveEmpresa  AND
		                                                         ANO_MES        =  @pAnoMes      AND
																 CVE_POLIZA     =  @cve_poliza   AND
																 ID_ENCA_POLIZA =  @Id_enca_poliza_p
	  END

 	  IF   (@imp_debe_p <> 0  OR  @imp_haber_p <> 0)  AND  ISNULL(@cta_contable_p,' ')  <> ' '
	  BEGIN
--	    SELECT ' ENVIO CREA POLIZA '

    	EXEC  spCreaPoliza @pIdTarea, @pIdProceso, @pCveEmpresa, @pAnoMes, @cve_poliza,  @Id_enca_poliza_p, @id_transaccion,
	                       @cta_contable_p, @desc_departamento_p, @conc_movimiento_p, @tipo_cambio_p, @imp_debe_p,
		           		   @imp_haber_p ,@proyecto_p,  @pError OUT, @pMsgError OUT  
      END 
	  ELSE
	  BEGIN
        IF  (@cve_debe NOT IN (@k_iva_pesos, @k_iva_dolares) AND @cve_haber NOT IN (@k_iva_pesos, @k_iva_dolares))  AND
		    (@imp_debe_p = 0 AND @imp_haber_p = 0) 
        BEGIN
	      SET @pError    =  'DEBE-HABER en ceros ' + 
		  ISNULL(@pCveEmpresa,'**') + ISNULL(@pAnoMes,'**') + ISNULL(convert(varchar(20),@id_transaccion),'**') +
		  ISNULL(@cve_debe,'**') + ISNULL(@cve_haber,'**')
          SET @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
        END
        ELSE
		BEGIN
		  IF  ISNULL(@cta_contable_p,' ') = ' '
		  BEGIN
            SET @pError    =  'Cta Contable erronea ' + 
		    ISNULL(@pCveEmpresa,'**') + ISNULL(@pAnoMes,'**') + ISNULL(convert(varchar(20),@id_transaccion),'**') 
            SET @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
            EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
		  END
		END

	  END
	    
      FETCH cur_poliza INTO
      @cve_poliza,
      @desc_poliza,
	  @id_transaccion,
      @cve_oper_cont,
      @cve_num_cuenta,
      @cve_DEPTO,
      @cve_concepto,
      @cve_tipo_cambio,
      @cve_debe,
      @cve_haber,
      @cve_proyecto
  END

  END
--  select ' Salgo Cursor'
  CLOSE cur_poliza
  DEALLOCATE cur_poliza

  EXEC spCuadraPoliza @pIdProceso, @pIdTarea, @pCveEmpresa, @pAnoMes, @cve_poliza, @Id_enca_poliza_p,
                      @pError OUT, @pMsgError  OUT

  EXEC spActRegProcPol @pCveEmpresa, @pIdProceso, @pIdTarea, @pAnoMes, @cve_poliza 

  IF (SELECT  NUM_REGISTROS FROM FC_GEN_TAREA WHERE CVE_EMPRESA = @pCveEmpresa  AND
                                 ID_PROCESO = @pIdProceso   AND
								 ID_TAREA    = @pIdTarea)  = 0
  BEGIN
    DELETE  CI_ENCA_POLIZA  WHERE CVE_EMPRESA =  @pCveEmpresa  AND  ANO_MES = @pAnoMes  AND CVE_POLIZA = @cve_poliza AND
	                              ID_ENCA_POLIZA = @Id_enca_poliza_p
  END									      

  EXEC spActPctTarea @pIdTarea, 90

  END TRY

  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_poliza'))  =  1 
	BEGIN
	  CLOSE cur_poliza
      DEALLOCATE cur_poliza
    END
  SET  @pError    =  'Error proceso Generacion Polizas'
  SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
  EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH

END