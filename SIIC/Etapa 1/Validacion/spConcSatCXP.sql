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
--EXEC spConcSatCXP 'CU','MARIO', '201811',1,1,' ',' '
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
		  @id_concilia_cxp int,
		  @id_cxp_det      int,
		  @imp_f_neto      numeric(16,2),
		  @situacion       varchar(2)

  DECLARE @k_legada        varchar(6)   = 'LEGACY',
		  @k_activa        varchar(1)   = 'A',
		  @k_cancelada     varchar(1)   = 'C',
		  @k_error         varchar(1)   = 'E',
		  @k_efcomp_ing    varchar(1)   = 'I',
		  @k_efcomp_rec    varchar(1)   = 'P',
		  @k_verdadero     varchar(1)   = 1
-------------------------------------------------------------------------------
-- Conciliación de Facturas 
-------------------------------------------------------------------------------
  DECLARE  @TCXP       TABLE
          (RowID            int  identity(1,1),
           RFC_PROVEEDOR    varchar(15),
		   NOM_PROVEEDOR    varchar(100),
		   F_OPERACION      date,
		   ID_CONCILIA_CXP  int,
		   ID_CXP_DET       int,
		   IMP_F_NETO       numeric(16,2),
		   SITUACION        varchar(2))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

  DELETE FROM CI_SAT_CXP WHERE ID_CONCILIA_CXP = 0
  UPDATE CI_SAT_CXP SET ID_CONCILIA_CXP = NULL WHERE 
  ID_CONCILIA_CXP IS NOT NULL

  INSERT  @TCXP (RFC_PROVEEDOR, NOM_PROVEEDOR, F_OPERACION, ID_CONCILIA_CXP, ID_CXP_DET,
                 IMP_F_NETO, SITUACION) 
  SELECT  p.RFC, p.NOM_PROVEEDOR, c.F_CAPTURA, c.ID_CONCILIA_CXP, i.ID_CXP_DET, c.IMP_NETO , c.SIT_C_X_P
  FROM    CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p, CI_ITEM_C_X_P i
  WHERE   c.CVE_EMPRESA           =  @pCveEmpresa     AND
          c.CVE_EMPRESA           =  i.CVE_EMPRESA    AND
		  c.ID_CXP                =  i.ID_CXP         AND
          c.ID_PROVEEDOR          =  p.ID_PROVEEDOR   AND
         (dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo AND c.SIT_C_X_P = @k_activa) AND
		  NOT EXISTS 
		  (SELECT 1 FROM CI_ITEM_C_X_P i2 WHERE 
		   i.CVE_EMPRESA = i2.CVE_EMPRESA  AND
		   i.ID_CXP      = i2.ID_CXP       AND
		   i2.B_FACTURA  = @k_verdadero)
  UNION
  SELECT  i.RFC, SUBSTRING(i.TX_NOTA,1,120), c.F_CAPTURA, c.ID_CONCILIA_CXP, i.ID_CXP_DET,
  i.IMP_BRUTO + i.IVA, @k_activa
  FROM    CI_CUENTA_X_PAGAR c, CI_ITEM_C_X_P i
  WHERE   c.CVE_EMPRESA  =  @pCveEmpresa  AND
          c.CVE_EMPRESA           =  i.CVE_EMPRESA    AND
		  c.ID_CXP                =  i.ID_CXP         AND
          i.B_FACTURA    =  @k_verdadero  AND
         (dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo AND c.SIT_C_X_P = @k_activa) 

  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------
--  SELECT * FROM @TCXP
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @rfc_proveedor = RFC_PROVEEDOR, @nom_proveedor = NOM_PROVEEDOR,
	       @f_operacion = F_OPERACION, @id_concilia_cxp = ID_CONCILIA_CXP, @id_cxp_det = ID_CXP_DET,
		   @imp_f_neto = IMP_F_NETO, @situacion = SITUACION
	FROM   @TCXP  WHERE  RowID = @RowCount

	SELECT ' RFC ' + @rfc_proveedor
	SELECT ' IMP ' + CONVERT(VARCHAR(16),@imp_f_neto)
	SELECT ' SIT ' + @situacion 

    SELECT TOP(1) @id_unico = ID_UNICO FROM CI_SAT_CXP  WHERE
	RFC_EMISOR      =  @rfc_proveedor  AND
	IMP_FACTURA     =  @imp_f_neto    AND
	ESTATUS         =  @situacion     AND
	ID_CONCILIA_CXP IS NULL           AND
   	EFECTO_COMPROB  =  @k_efcomp_ing    AND
     dbo.fnArmaAnoMes (YEAR(F_EMISION), MONTH(F_EMISION))  =  @pAnoPeriodo

	SELECT ' ID ' + @id_unico 

	BEGIN TRY

	IF  ISNULL(@id_unico,' ') <> ' '
	BEGIN
      UPDATE CI_SAT_CXP SET ID_CONCILIA_CXP = @id_concilia_cxp WHERE ID_UNICO = @id_unico
	END
	ELSE
	BEGIN
	  SELECT 'INSERTO'
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
	  ID_CONCILIA_CXP) VALUES
     (CONVERT(VARCHAR(10),@id_concilia_cxp) + '-' + CONVERT(VARCHAR(10),@id_cxp_det),
	  @rfc_proveedor,
	  @nom_proveedor,
	  ' ',
	  ' ',
	  ' ',
	  @f_operacion,
	  @f_operacion,
	  @imp_f_neto,
	  ' ',
	  @situacion,
	  NULL,
	  0
	 )
    END

	END TRY

    BEGIN CATCH
      SET  @pError    =  'Error Conciliacion SAT vs CXP'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
      SELECT @pMsgError
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END CATCH

    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc
    SET @RowCount     =  @RowCount + 1

  END  			

  IF  EXISTS (SELECT 1 FROM CI_SAT_CXP WHERE ID_CONCILIA_CXP = 0 OR
              ID_CONCILIA_CXP IS NULL)
  BEGIN
	SET  @num_reg_proc = @num_reg_proc + 1 
	SET  @pError    =  'Existen diferencias entre SAT y CXP '
    SELECT @pError
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ERROR_MESSAGE())
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END

END

