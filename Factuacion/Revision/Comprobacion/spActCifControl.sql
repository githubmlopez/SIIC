USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP PROCEDURE  spActCifControl
ALTER PROCEDURE spActCifControl  
       @pIdProceso          int,
       @pIdTarea            int,
       @pCveOpeCont         varchar(4),
       @pCveEmpresa         varchar(4),
       @pid_transaccion     int,
       @pAnoMes             varchar(6),
	   @pError              varchar(400) OUT,
       @pMsgError           varchar(400) OUT	    

AS
BEGIN
  
  DECLARE  @k_error  varchar(1)

  SET  @k_error =  'E'

  BEGIN TRY
  IF  EXISTS(SELECT 1 FROM FC_CIFRA_CONTROL  WHERE 
                           ANO_MES        =  @pAnoMes        AND        
                           CVE_EMPRESA    =  @pCveEmpresa    AND
                           ID_PROCESO     =  @pIdProceso     AND    
                           CONCEPTO_PROC  =  @pCveOpeCont)
  BEGIN 
 --   SELECT ' ** ACTUALIZA CIFRAS CONTROL ** '
	UPDATE  FC_CIFRA_CONTROL
	SET   TOT_CONCEPTO  =  TOT_CONCEPTO  +  1,
	      IMP_CONCEPTO  =  IMP_CONCEPTO  +  @pid_transaccion
    WHERE 
    ANO_MES        =  @pAnoMes        AND 
	CVE_EMPRESA    =  @pCveEmpresa    AND
    ID_PROCESO     =  @pIdProceso     AND    
    CONCEPTO_PROC  =  @pCveOpeCont
  END 
  ELSE
  BEGIN --   SELECT '*Despliego Informacion'
	--SELECT '*@pCveEmpresa' + ISNULL(@pCveEmpresa, 'NULO')
	--SELECT '*@pAnoMes' + @pAnoMes
	--SELECT '*@pIdProceso' + CONVERT(varchar(10),@pIdProceso)
	--SELECT '*@pid_transaccion' + CONVERT(varchar(10),@pid_transaccion)

    INSERT  INTO FC_CIFRA_CONTROL
           (ANO_MES,
		    CVE_EMPRESA,
            ID_PROCESO,  
            CONCEPTO_PROC,
            TOT_CONCEPTO, 
            IMP_CONCEPTO, 
            TOT_CONC_CAL, 
            IMP_CONC_CAL)   
    VALUES 
	       (@pAnoMes,
		    @pCveEmpresa,
			@pIdProceso,
			@pCveOpeCont,
			1,
			@pid_transaccion,
			0,
			0)
  END
--  select ' *** insert cifras correcto **'
  END TRY
  
  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END
    SET  @pError    =  'Error al insertar Insetar Cifras de Control'
	SET  @pMsgError =  @pError + '==> ' + ERROR_MESSAGE()
	EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH;
  
END
