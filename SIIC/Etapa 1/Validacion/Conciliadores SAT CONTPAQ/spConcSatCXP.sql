USE [ADMON01]
GO
/****** Conciliacion de CXP vs SAT ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spConcSatCXP')
BEGIN
  DROP  PROCEDURE spConcSatCXP
END
GO
--EXEC spConcSatCXP 'CU','MARIO', '201906',1,2,' ',' '
CREATE PROCEDURE [dbo].[spConcSatCXP]
(
--@pIdProceso       numeric(9),
--@pIdTarea         numeric(9),
--@pCodigoUsuario   varchar(20),
--@pIdCliente       int,
--@pCveEmpresa      varchar(4),
--@pCveAplicacion   varchar(10),
--@pAnoPeriodo      varchar(6),

--@pError           varchar(80) OUT,
--@pMsgError        varchar(400) OUT
--)
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE @NunRegistros int, 
          @RowCount     int,
		  @id_unico     varchar(36),
		  @num_reg_proc int
  
  DECLARE @rfc_proveedor   varchar(15),
          @f_operacion     date,
		  @nom_proveedor   varchar(100),
		  @id_cxp          int,
		  @id_cxp_det      int,
		  @imp_f_neto      numeric(16,2),
		  @situacion       varchar(2)

  DECLARE @k_legada        varchar(6)   = 'LEGACY',
		  @k_activa        varchar(1)   = 'A',
		  @k_cancelada     varchar(1)   = 'C',
		  @k_error         varchar(1)   = 'E',
		  @k_warning       varchar(1)   = 'W',
		  @k_efcomp_ing    varchar(1)   = 'I',
		  @k_efcomp_rec    varchar(1)   = 'P',
		  @k_verdadero     varchar(1)   = 1,
		  @k_falso         varchar(1)   = 0,
		  @k_no_conc       varchar(2)   = 'NC',
		  @k_conciliado    varchar(2)   = 'CO',
		  @k_f_inicial     date         = '2018-12-01',
		  @k_cerrado       varchar(1)   = 'C'

  IF  (SELECT SIT_PERIODO FROM CI_PERIODO_CONTA WHERE 
       CVE_EMPRESA = @pCveEmpresa   AND
	   ANO_MES     = @pAnoPeriodo)  <>  @k_cerrado

  BEGIN

-------------------------------------------------------------------------------
-- Conciliación de Cuentas Por Pagar
-------------------------------------------------------------------------------
  DECLARE  @TCXP       TABLE
          (RowID            int  identity(1,1),
           RFC_PROVEEDOR    varchar(15),
		   NOM_PROVEEDOR    varchar(100),
		   F_OPERACION      date,
		   ID_CXP           int,
		   ID_CXP_DET       int,
		   IMP_F_NETO       numeric(16,2),
		   SITUACION        varchar(2))

  DELETE FROM CI_SAT_CXP WHERE
  ANO_MES_PROC =  @pAnoPeriodo  AND
  B_AUTOMATICO =  @k_falso      

  UPDATE CI_SAT_CXP SET ID_CXP = NULL, ID_CXP_DET = NULL, ANO_MES_CONC = NULL
  WHERE 
  ANO_MES_CONC =  @pAnoPeriodo OR
 (ANO_MES_PROC =  @pAnoPeriodo AND
  B_AUTOMATICO =  @k_verdadero)
 
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT -
-----------------------------------------------------------------------------------------------------

  INSERT  @TCXP (RFC_PROVEEDOR, NOM_PROVEEDOR, F_OPERACION, ID_CXP, ID_CXP_DET,
                 IMP_F_NETO, SITUACION) 
  SELECT  p.RFC, p.NOM_PROVEEDOR, c.F_CAPTURA, c.ID_CXP, 0, c.IMP_NETO , c.SIT_C_X_P
  FROM    CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p
-- Selecciona las cuentas por pagar desde el periodo inicial definido, que tengan una factura y que dentro de sus detalles no
-- exista un elemento (item) que indique que tenga factura.
  WHERE   c.CVE_EMPRESA   =  @pCveEmpresa     AND
          c.ID_PROVEEDOR  =  p.ID_PROVEEDOR   AND
          c.F_CAPTURA    >=  @k_f_inicial     AND  
  -- Solo se toman los del mes en curso debido a que los anteriores ya debieron haber sido procesados
  		  dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo AND               
		  c.SIT_C_X_P = @k_activa             AND
		  c.B_FACTURA = @k_verdadero          AND
		  NOT EXISTS 
		  (SELECT 1 FROM CI_ITEM_C_X_P i2 WHERE 
		   c.CVE_EMPRESA = i2.CVE_EMPRESA  AND
		   c.ID_CXP      = i2.ID_CXP       AND
		   i2.B_FACTURA  = @k_verdadero)
  UNION
  SELECT  i.RFC, SUBSTRING(i.TX_NOTA,1,120), c.F_CAPTURA, c.ID_CXP, i.ID_CXP_DET,
  i.IMP_BRUTO + i.IVA, @k_activa
  FROM    CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i
-- Se seleccionan todos los movimientos (items) que indiquen que tienen asociada una factura
  WHERE   c.CVE_EMPRESA  =  @pCveEmpresa  AND
          c.CVE_EMPRESA  =  i.CVE_EMPRESA AND
		  c.ID_CXP       =  i.ID_CXP      AND
          i.B_FACTURA    =  @k_verdadero  AND
          c.F_CAPTURA   >=  @k_f_inicial  AND
 -- Solo se toman los del mes en curso debido a que los anteriores ya debieron haber sido procesados
  		  dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo AND               
		  c.SIT_C_X_P = @k_activa

  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------
  SELECT * FROM @TCXP
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @rfc_proveedor = RFC_PROVEEDOR, @nom_proveedor = NOM_PROVEEDOR,
	       @f_operacion = F_OPERACION, @id_cxp = ID_CXP, @id_cxp_det = ID_CXP_DET,
		   @imp_f_neto = IMP_F_NETO, @situacion = SITUACION
	FROM   @TCXP  WHERE  RowID = @RowCount 

	--SELECT ' RFC ' + @rfc_proveedor
	--SELECT ' IMP ' + CONVERT(VARCHAR(16),@imp_f_neto)
	--SELECT ' SIT ' + @situacion 

	SET @id_unico = ' '

-- Busca en archivo SAT si existe el registro de CXP
    SELECT TOP(1) @id_unico = ID_UNICO FROM CI_SAT_CXP  WHERE
	RFC_EMISOR                =  @rfc_proveedor  AND
	IMP_FACTURA               =  @imp_f_neto     AND
	ESTATUS                   =  @situacion      AND
	ID_CXP              IS NULL                  AND
   	EFECTO_COMPROB            =  @k_efcomp_ing   AND
	CVE_CONC_MAN        IS  NULL  

	--IF @rfc_proveedor = 'DEM8801152E9'
	--BEGIN
 --	  SELECT ' ID ' + @id_unico 
	--  SELECT 'IMPORTE ' + CONVERT(VARCHAR(10), @imp_f_neto)
	--  SELECT 'SIT ' + @situacion
	--  SELECT 'EFECTO  ' + @k_efcomp_ing
 --   END

	BEGIN TRY

	IF  ISNULL(@id_unico,' ') <> ' ' 
	BEGIN
-- Encuentra registro y actuliza registro del SAT con los datos de la CXP
      UPDATE CI_SAT_CXP
	  SET ID_CXP       = @id_cxp,
	      ID_CXP_DET   = @id_cxp_det,
		  SIT_CONCILIA = @k_conciliado,
		  ANO_MES_CONC = @pAnoPeriodo 
	  WHERE ID_UNICO = @id_unico   

	  IF  EXISTS(SELECT 1 FROM CI_SAT_CXP WHERE               
	             ID_UNICO =  (CONVERT(VARCHAR(10),@id_cxp) + '-' + CONVERT(VARCHAR(10),@id_cxp_det)) AND
				 B_AUTOMATICO =  @k_falso)
	  BEGIN
         UPDATE CI_SAT_CXP
         SET SIT_CONCILIA = @k_conciliado,
		     ANO_MES_CONC = @pAnoPeriodo
		 WHERE 
		 ID_UNICO =  (CONVERT(VARCHAR(10),@id_cxp) + '-' + CONVERT(VARCHAR(10),@id_cxp_det)) AND
		 B_AUTOMATICO =  @k_falso
	  END
    
  --    IF  @id_cxp_det = 0 
	 -- BEGIN
	 --   IF  EXISTS (SELECT 1 FROM CI_SAT_CXP WHERE 
		--            ID_CXP       = @id_cxp  AND
		--			ID_CXP_DET   = 0        AND
		--			B_AUTOMATICO = @k_falso)
		--BEGIN
  --        UPDATE CI_SAT_CXP
	 --     SET ID_CXP       = @id_cxp,
	 --         ID_CXP_DET   = 0,
		--      SIT_CONCILIA = @k_conciliado
		--END
	 -- END
	 -- ELSE
	 -- BEGIN
	 -- 	IF  EXISTS (SELECT 1 FROM CI_SAT_CXP WHERE 
		--            ID_CXP     = @id_cxp  AND
		--			ID_CXP_DET = 0         AND
		--			B_AUTOMATICO = @k_falso)
		--BEGIN
  --        UPDATE CI_SAT_CXP
	 --     SET ID_CXP       = @id_cxp,
	 --         ID_CXP_DET   = 0,
		--  SIT_CONCILIA = @k_conciliado
	 --   END
	 -- END
    END 
	ELSE
	BEGIN
--	  SELECT 'INSERTO'
      IF  NOT EXISTS(SELECT 1 FROM CI_SAT_CXP  WHERE ID_UNICO = (CONVERT(VARCHAR(10),@id_cxp) + '-' + CONVERT(VARCHAR(10),@id_cxp_det)))
	  BEGIN
	    INSERT  CI_SAT_CXP  
	   (
	    ID_UNICO,
	    RFC_EMISOR,
	    NOM_EMISOR,
	    RFC_RECEPTOR,
	    NOM_RECEPTOR,
	    RFC_PAC,
	    F_EMISION,
	    F_CERTIFICACION,
	    IMP_FACTURA,
	    EFECTO_COMPROB,
	    ESTATUS,
	    F_CANCELACION,
	    ID_CXP,
	    ID_CXP_DET,
	    SIT_CONCILIA,
	    ANO_MES_PROC,
	    B_AUTOMATICO) VALUES
       (CONVERT(VARCHAR(10),@id_cxp) + '-' + CONVERT(VARCHAR(10),@id_cxp_det),
	    @rfc_proveedor,
	    @nom_proveedor,
	    ' ',
	    ' ',
	    ' ',
	    @f_operacion,
	    @f_operacion,
	    @imp_f_neto,
	    '*',
	    @situacion,
	    NULL,
	    NULL,
	    NULL,
	    @k_no_conc,
	    @pAnoPeriodo,
	    @k_falso
	   )
      END
    END

	END TRY

    BEGIN CATCH
      SET  @pError    =  'Error Conciliacion SAT vs CXP'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      SELECT @pMsgError
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END CATCH

    SET @RowCount     =  @RowCount + 1
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @RowCount
  END  			

  IF  EXISTS (SELECT * FROM CI_SAT_CXP WHERE SIT_CONCILIA = @k_no_conc    AND
              EFECTO_COMPROB <> @k_efcomp_rec AND ANO_MES_PROC = @pAnoPeriodo)
  BEGIN
	SET  @num_reg_proc = @num_reg_proc + 1 
	SET  @pError    =  'Existen diferencias entre SAT y CXP '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

  END
  ELSE
  BEGIN
    SET  @pError    =  'El Periodo esta cerrado '
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    SELECT @pMsgError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

