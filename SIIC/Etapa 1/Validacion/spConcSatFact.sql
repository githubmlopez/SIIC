USE [ADMON01]
GO
/****** Carga de información del SAT a base ADMON01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spConcSatFact')
BEGIN
  DROP  PROCEDURE spConcSatFact
END
GO
--EXEC spConcSatFact 'CU','MARIO', '201901',1,2,' ',' '
CREATE PROCEDURE [dbo].[spConcSatFact]
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
  
  DECLARE @rfc_cliente     varchar(15),
          @f_operacion     date,
		  @nom_cliente     varchar(100),
		  @id_concilia_cxc int,
		  @imp_f_neto      numeric(16,2),
		  @situacion       varchar(2)

  DECLARE @k_verdadero     bit          = 1,
          @k_falso         bit          = 0,
          @k_legada        varchar(6)   = 'LEGACY',
		  @k_activa        varchar(1)   = 'A',
		  @k_cancelada     varchar(1)   = 'C',
		  @k_error         varchar(1)   = 'E',
		  @k_warning       varchar(1)   = 'W',
		  @k_efcomp_ing    varchar(1)   = 'I',
		  @k_efcomp_rec    varchar(1)   = 'P',
		  @k_no_conc       varchar(2)   = 'NC',
		  @k_conciliado    varchar(2)   = 'CO',
		  @k_c_anterior    varchar(2)   = 'CT'
-------------------------------------------------------------------------------
-- Conciliación de Facturas 
-------------------------------------------------------------------------------
  DECLARE  @TFacturas       TABLE
          (RowID            int  identity(1,1),
           RFC_CLIENTE      varchar(15),
		   NOM_CLIENTE      varchar(100),
		   F_OPERACION      date,
		   ID_CONCILIA_CXC  int,
		   IMP_F_NETO       numeric(16,2),
		   SITUACION        varchar(2))

-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

  DELETE FROM CI_SAT_FACTURA WHERE
  ANO_MES_PROC =  @pAnoPeriodo  AND
  B_AUTOMATICO = 0 
  
  UPDATE CI_SAT_FACTURA SET ID_CONCILIA_CXC = NULL, SIT_CONCILIA = NULL WHERE 
  ANO_MES_PROC = @pAnoPeriodo  AND  B_AUTOMATICO = @k_verdadero

  INSERT  @TFacturas (RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO, SITUACION) 
  SELECT  RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO,
  CASE
  WHEN  ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoPeriodo AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoPeriodo))		  
  THEN  @k_activa
  WHEN  ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoPeriodo AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) < @pAnoPeriodo))		  
  THEN  @k_c_anterior
  ELSE  SIT_TRANSACCION
  END AS SIT_TRANSACCON
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA           =  @pCveEmpresa     AND
          f.ID_VENTA              =  v.ID_VENTA       AND
          v.ID_CLIENTE            =  c.ID_CLIENTE     AND
          f.SERIE                <>  @k_legada        AND                                         
       (((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoPeriodo AND f.SIT_TRANSACCION     = @k_activa) OR
         (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoPeriodo AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
        ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoPeriodo AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoPeriodo)))		  
  --UNION 
  --SELECT  RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO, @k_activa
  --FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  --WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
  --        f.ID_VENTA              =  v.ID_VENTA       AND
  --        v.ID_CLIENTE            =  c.ID_CLIENTE     AND
  --        f.SERIE                <>  @k_legada        AND
  --  	  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoPeriodo  AND                                         
		-- (f.SIT_TRANSACCION      =  @k_cancelada      AND
	 --     dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoPeriodo)       

  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------
--  	SELECT ' num reg ' + CONVERT(varchar(12), @NunRegistros)
--  SELECT * FROM @TFacturas
  SET @RowCount     = 1
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @rfc_cliente = RFC_CLIENTE, @nom_cliente = NOM_CLIENTE,
	       @f_operacion = F_OPERACION, @id_concilia_cxc = ID_CONCILIA_CXC,
		   @imp_f_neto = IMP_F_NETO, @situacion = SITUACION
	FROM   @TFacturas  WHERE  RowID = @RowCount

	SELECT @id_unico = ' '
    SELECT TOP(1) @id_unico = ID_UNICO FROM CI_SAT_FACTURA WHERE
	RFC_RECEPTOR    =  @rfc_cliente  AND
	IMP_FACTURA     =  @imp_f_neto   AND
	ESTATUS         =  @situacion    AND
	ID_CONCILIA_CXC IS NULL          AND
	EFECTO_COMPROB  =  @k_efcomp_ing AND
    dbo.fnArmaAnoMes (YEAR(F_EMISION), MONTH(F_EMISION))  =  @pAnoPeriodo
--	SELECT ' ID UNICO ' + CONVERT(varchar(12), ISNULL(@id_unico,' ') )
	BEGIN TRY

	IF  ISNULL(@id_unico,' ') <> ' '
	BEGIN
      UPDATE CI_SAT_FACTURA SET ID_CONCILIA_CXC = @id_concilia_cxc,
	                            SIT_CONCILIA    = @k_conciliado
	  WHERE ID_UNICO = @id_unico
	END
	ELSE
	BEGIN
	  INSERT  CI_SAT_FACTURA  
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
	  ID_CONCILIA_CXC,
	  ANO_MES_PROC,
	  SIT_CONCILIA,
	  B_AUTOMATICO) VALUES
     (@id_concilia_cxc,
	  @rfc_cliente,
	  @nom_cliente,
	  ' ',
	  ' ',
	  ' ',
	  @f_operacion,
	  @f_operacion,
	  @imp_f_neto,
	  ' ',
	  @situacion,
	  NULL,
	  0,
	  @pAnoPeriodo,
	  @k_no_conc,
	  @k_falso
	 )
    END

	END TRY

    BEGIN CATCH
      SET  @pError    =  'Error Conciliacion SAT vs Facturas'
      SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
--      SELECT @pMsgError
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
    END CATCH

    SET @RowCount     =  @RowCount + 1
    EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @RowCount
 
  END  			

  IF  EXISTS (SELECT * FROM CI_SAT_FACTURA WHERE SIT_CONCILIA = @k_no_conc    AND
              EFECTO_COMPROB <> @k_efcomp_rec AND ANO_MES_PROC = @pAnoPeriodo AND
			  ESTATUS <>  @k_c_anterior)
  BEGIN
	SET  @num_reg_proc = @num_reg_proc + 1 
	SET  @pError    =  'Existen diferencias entre SAT y  FACTURAS '
--    SELECT @pError
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_warning, @pError, @pMsgError
  END

END

