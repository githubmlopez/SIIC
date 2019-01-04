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
--EXEC spConcSatFact 1,1,'MARIO',1,'CU','FCTURACION','201901',' ',' '
CREATE PROCEDURE [dbo].[spConcSatFact]
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pAnoMes          varchar(6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE @NunRegistros int, 
          @RowCount     int,
		  @id_unico     varchar(36)
  
  DECLARE @rfc_cliente     varchar(15),
          @f_operacion     date,
		  @nom_cliente     varchar(100),
		  @id_concilia_cxc int,
		  @imp_f_neto      numeric(16,2),
		  @situacion       varchar(2)

  DECLARE @k_legada        varchar(6)   = 'LEGACY',
		  @k_activa        varchar(1)   = 'A',
		  @k_cancelada     varchar(1)   = 'C'
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
  INSERT  @TFacturas (RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO, SITUACION) 
  SELECT  RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO, SIT_TRANSACCION
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
          f.ID_VENTA              =  v.ID_VENTA       AND
          v.ID_CLIENTE            =  c.ID_CLIENTE     AND
          f.SERIE                <>  @k_legada        AND                                         
        ((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND f.SIT_TRANSACCION     = @k_activa) OR
         (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
        ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes))			  
  UNION 
  SELECT  RFC_CLIENTE, NOM_CLIENTE, F_OPERACION, ID_CONCILIA_CXC, IMP_F_NETO, @k_activa
  FROM    CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  WHERE   f.CVE_EMPRESA   =  @pCveEmpresa     AND
          f.ID_VENTA              =  v.ID_VENTA       AND
          v.ID_CLIENTE            =  c.ID_CLIENTE     AND
          f.SERIE                <>  @k_legada        AND
    	  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes  AND                                         
		 (f.SIT_TRANSACCION      =  @k_cancelada      AND
	      dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION))  = @pAnoMes)       

  SET @NunRegistros = @@ROWCOUNT
-------------------------------------------------------------------------------------

  SET @RowCount     = 1
				  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @rfc_cliente = RFC_CLIENTE, @nom_cliente = NOM_CLIENTE,
	       @f_operacion = F_OPERACION, @id_concilia_cxc = ID_CONCILIA_CXC,
		   @imp_f_neto = IMP_F_NETO, @situacion = SITUACION
	FROM   @TFacturas  WHERE  RowID = @RowCount

    SELECT TOP(1) @id_unico = ID_UNICO FROM CI_SAT_FACTURA WHERE
	RFC_RECEPTOR    =  @rfc_cliente  AND
	IMP_FACTURA     =  @imp_f_neto   AND
	ESTATUS         =  @situacion    AND
	ID_CONCILIA_CXC =  0             AND
    dbo.fnArmaAnoMes (YEAR(F_EMISION), MONTH(F_EMISION))  =  @pAnoMes

	IF  ISNULL(@id_unico,' ') <> ' '
	BEGIN
      UPDATE CI_SAT_FACTURA SET ID_CONCILIA_CXC = @id_concilia_cxc WHERE ID_UNICO = @id_unico
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
	  ID_CONCILIA_CXC) VALUES
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
	  ' ',
	  NULL,
	  0
	 )
    SET @RowCount     =   @RowCount + 1
    END
  END  			
END

