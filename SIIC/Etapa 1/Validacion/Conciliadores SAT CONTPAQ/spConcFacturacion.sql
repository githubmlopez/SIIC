USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
--exec spConcFacturacion 'CU', 'MARIO', '201902', 12, 361, ' ', ' '
ALTER PROCEDURE [dbo].[spConcFacturacion]   @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                            @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								            @pMsgError varchar(400) OUT

AS
BEGIN

  DECLARE @k_error          varchar(1)   = 'E',
          @k_legada         varchar(6)   = 'LEGACY',
		  @k_activa         varchar(1)   = 'A',
		  @k_cancelada      varchar(1)   = 'C',
          @k_falso          bit          = 0,
		  @k_dolar          varchar(1)   = 'D',
		  @k_no_act         numeric(9,0) = 99999

  DECLARE @num_reg_proc     int = 0 

  DECLARE @f_inicio_mes  date,
          @f_fin_mes     date

  BEGIN TRY

  DELETE  FROM  CI_COM_FISC_CONTPAQ  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes  AND
                                            B_CONTPAQ     =  @k_falso    
  
  UPDATE CI_COM_FISC_CONTPAQ  SET  IMP_BRUTO_C     =  0,
                                   IMP_IMPUESTO_C  =  0,
     							   IMP_NETO_C      =  0,
								   TIPO_CAMBIO     =  0
  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND  ANO_MES  =  @pAnoMes
  
  SELECT @f_inicio_mes  =  F_INICIAL,  @f_fin_mes  =  F_FINAL
  FROM CI_PERIODO_CONTA  where ANO_MES  =  @pAnoMes
  
  MERGE CI_COM_FISC_CONTPAQ AS TARGET
       USING (SELECT f.CVE_EMPRESA, f.SERIE, f.ID_CXC, c.ID_CLIENTE, c.NOM_CLIENTE, f.F_OPERACION, 
              f.SIT_TRANSACCION,
	          CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN 
			  f.TIPO_CAMBIO
			  ELSE 0
			  END AS TIPO_CAMBIO,
	          CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_BRUTO *
			  f.TIPO_CAMBIO
			  ELSE f.IMP_F_BRUTO
			  END AS IMP_F_BRUTO,
			  CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_IVA *
			  f.TIPO_CAMBIO
			  ELSE f.IMP_F_IVA
			  END AS IMP_F_IVA,
 			  CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_NETO * 
			  f.TIPO_CAMBIO
			  ELSE f.IMP_F_NETO
			  END AS IMP_F_NETO
	          FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
              WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
              f.ID_VENTA              =  v.ID_VENTA       AND
              v.ID_CLIENTE            =  c.ID_CLIENTE     AND
              f.SERIE                <>  @k_legada        AND                                         
	       (((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND f.SIT_TRANSACCION     = @k_activa) OR
             (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
            ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA) AND
	         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes)))			  
			  UNION 
			  SELECT f.CVE_EMPRESA, f.SERIE, f.ID_CXC, c.ID_CLIENTE, c.NOM_CLIENTE, f.F_OPERACION, @k_activa,
	          CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN 
			  f.TIPO_CAMBIO
			  ELSE 0
			  END AS TIPO_CAMBIO,
	          CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_BRUTO * 
              f.TIPO_CAMBIO
			  ELSE f.IMP_F_BRUTO
			  END AS IMP_F_BRUTO,
			  CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_IVA *
			  f.TIPO_CAMBIO
			  ELSE f.IMP_F_IVA
			  END AS IMP_F_IVA,
 			  CASE
			  WHEN f.CVE_F_MONEDA  =  @k_dolar
			  THEN f.IMP_F_NETO *
              f.TIPO_CAMBIO
			  ELSE f.IMP_F_NETO
			  END AS IMP_F_NETO
	          FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
              WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
              f.ID_VENTA              =  v.ID_VENTA       AND
              v.ID_CLIENTE            =  c.ID_CLIENTE     AND
              f.SERIE                <>  @k_legada        AND
			  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes  AND                                         
			 (f.SIT_TRANSACCION      =  @k_cancelada      AND
		      dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes)       
			 )
			 
			 AS SOURCE 
          ON TARGET.CVE_EMPRESA  = SOURCE.CVE_EMPRESA  AND
             TARGET.ANO_MES      = @pAnoMes            AND
		     TARGET.SERIE        = SOURCE.SERIE        AND
			 TARGET.ID_CXC       = SOURCE.ID_CXC       AND
			 TARGET.ESTADO       = SOURCE.SIT_TRANSACCION

  WHEN MATCHED THEN
       UPDATE 
          SET IMP_BRUTO_C      = SOURCE.IMP_F_BRUTO,
		      IMP_IMPUESTO_C   = SOURCE.IMP_F_IVA,
		      IMP_NETO_C       = SOURCE.IMP_F_NETO,
			  TIPO_CAMBIO      = SOURCE.TIPO_CAMBIO

  WHEN NOT MATCHED  BY TARGET THEN 
       INSERT (CVE_EMPRESA,
               ANO_MES,
		       F_OPERACION,
		       SERIE,
               ID_CXC,
               ID_CLIENTE,
			   RAZON_SOCIAL,
			   RFC,
			   CONCEPTO,
			   APROBACION,
			   ESTADO,
			   F_EXPEDICION,
			   IMP_BRUTO,
			   IMP_DESCUENTO,
			   IMP_IMPUESTO,
			   IMP_NETO,
			   IMP_BRUTO_C,
               IMP_IMPUESTO_C,
			   IMP_NETO_C,
			   B_CONTPAQ,
			   TIPO_CAMBIO)
       VALUES
              (SOURCE.CVE_EMPRESA,
		       @pAnoMes,
               SOURCE.F_OPERACION,
			   SOURCE.SERIE,
			   SOURCE.ID_CXC,
			   SOURCE.ID_CLIENTE,
		       SOURCE.NOM_CLIENTE,
			   ' ',
			   ' ',
			   ' ',
		       SOURCE.SIT_TRANSACCION,
		       NULL,
			   0,
			   0,
			   0,
			   0,
			   SOURCE.IMP_F_BRUTO,
			   SOURCE.IMP_F_IVA,
			   SOURCE.IMP_F_NETO,
			   @k_falso,
			   0);

--  SELECT ' TERMINE MERGE '

  IF  EXISTS(SELECT * FROM  CI_COM_FISC_CONTPAQ c   WHERE
     (c.B_CONTPAQ        =    @k_falso         OR
      c.IMP_BRUTO        <>   c.IMP_BRUTO_C    OR
      c.IMP_IMPUESTO     <>   c.IMP_IMPUESTO_C OR
      c.IMP_NETO         <>   c.IMP_NETO_C)  AND ANO_MES = @pAnoMes)
  BEGIN
    SET  @num_reg_proc = @num_reg_proc + 1 
	SET  @pError    =  'Existen diferencias entre CONTPAQ y  ERP '
 --   SELECT 'E1 ' + @pError
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
    EXEC spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END
   
  END TRY

  BEGIN CATCH
    SET  @pError    =  'Error Act Conciliacion Contpaq'
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--    SELECT 'E2 ' + @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc
END
