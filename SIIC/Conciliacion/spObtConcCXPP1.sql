USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcCXPP1')
BEGIN
  DROP  PROCEDURE spObtConcCXPP1
END
GO

--EXEC spObtConcCXPP1 'CU','MARIO','201903',135,1,'MDB437',' ',' '
CREATE PROCEDURE [dbo].[spObtConcCXPP1]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCveChequera     varchar(6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_verdadero       bit         =  1,
           @k_falso           bit         =  0,
           @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_cxc             varchar(3)  =  'CXC',
		   @k_normal          varchar(1)  =  'N',
		   @k_pago            varchar(1)  =  'P'

 DECLARE   @ano_mes             varchar(6),
		   @cve_chequera        varchar(8),
		   @cve_moneda          varchar(1),
		   @id_movto_bancario   int,
		   @f_operacion         date,
		   @imp_transaccion     numeric(12,2),
		   @descripcion         varchar(250),
		   @b_referencia        bit,
		   @id_referencia       varchar(50),
		   @id_cxp              int,
		   @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion_c       date,
		   @serie_id            varchar(20),
		   @cve_chequera_c      varchar(6),
		   @nom_proveedor       varchar(75),
		   @imp_f_neto          numeric(12,2),
		   @descripcion_c       varchar(120)

-------------------------------------------------------------------------------
-- Definición de tabla de movimientos conciliados
-------------------------------------------------------------------------------

  DECLARE  @TConciliacion    TABLE
          (RowID             int  identity(1,1),
		   CVE_EMPRESA       varchar(4),
		   ANO_MES           varchar(6),
   		   ID_MOVTO_BANCARIO int,
		   F_OPERACION       date,
		   CVE_CHEQUERA      varchar(8),
		   IMP_TRANSACCION   numeric(12,2),
		   DESCRIPCION       varchar(250),
		   B_PAGO            bit,
		   ID_REFERENCIA     varchar(50),
		   ID_CXP            int,
		   SERIE             varchar(6),
		   ID_CXC            int,
		   F_OPERACION_C     date,
		   SERIE_ID          varchar(20),
		   CVE_CHEQUERA_C    varchar(8),
		   NOM_PROVEEDOR     varchar(75),
		   IMP_F_NETO        numeric(12,2),
		   DESCRIPCION_C     varchar(120)
)
	 
  DECLARE  @TAsignados       TABLE
          (RowID             int  identity(1,1),
		   ID_CXP            int)
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TConciliacion  (CVE_EMPRESA, ANO_MES, ID_MOVTO_BANCARIO, F_OPERACION, CVE_CHEQUERA, IMP_TRANSACCION,  
                          DESCRIPCION, B_PAGO, ID_REFERENCIA)
  SELECT @pCveEmpresa, m.ANO_MES, m.ID_MOVTO_BANCARIO,  m.F_OPERACION, m.CVE_CHEQUERA + '-' + ch.CVE_MONEDA, m.IMP_TRANSACCION, m.DESCRIPCION, @k_falso,
         m.REFERENCIA
  FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE   m.ANO_MES            =  @pAnoPeriodo     AND
          m.CVE_CHEQUERA       =  @pCveChequera    AND
          m.CVE_TIPO_MOVTO     =  @k_cxc           AND
		  m.SIT_CONCILIA_BANCO =  @k_no_concilia   AND
		  m.SIT_MOVTO         <>  @k_cancelado     AND
		  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA  

  SET @NunRegistros = (SELECT COUNT(*) FROM @TConciliacion)
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_MES,
		   @id_movto_bancario  =  ID_MOVTO_BANCARIO,
		   @f_operacion        =  F_OPERACION,
		   @cve_chequera       =  CVE_CHEQUERA,
		   @imp_transaccion    =  IMP_TRANSACCION,
		   @descripcion        =  DESCRIPCION,
		   @b_referencia       =  B_PAGO,
		   @id_referencia      =  ID_REFERENCIA,
           @id_cxp             =  ID_CXP,
		   @serie              =  SERIE,
		   @id_cxc             =  ID_CXC,
		   @f_operacion_c      =  F_OPERACION_C,
           @serie_id           =  SERIE_ID,
		   @cve_chequera_c     =  CVE_CHEQUERA_C,
		   @nom_proveedor      =  NOM_PROVEEDOR,
		   @imp_f_neto         =  IMP_F_NETO,
		   @descripcion_c      =  DESCRIPCION_C  FROM  @TConciliacion
	WHERE  RowID  =  @RowCount

	SELECT TOP(1) 
	@id_cxp  =  p.ID_PAGO, @serie = ' ', @id_cxc = ' ', @f_operacion_c = p.F_CAPTURA,
	@cve_chequera_c = p.CVE_CHEQUERA, @nom_proveedor = p.BENEF_PAGO,
	@imp_f_neto =  p.IMP_NETO, @descripcion_c  = p.TX_NOTA
	FROM CI_PAGO p WHERE
	p.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
	dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo  AND
	p.IMP_NETO  =  
   (SELECT SUM(IMP_NETO) FROM CI_PAGO_CXP pc, CI_CUENTA_X_PAGAR c WHERE
    pc.CVE_EMPRESA = @pCveEmpresa AND pc.ID_PAGO = p.ID_PAGO AND PC.CVE_EMPRESA = C.CVE_EMPRESA AND pc.ID_CXP = c.ID_CXP) AND 
	NOT EXISTS (SELECT 1 FROM @TConciliacion cc WHERE cc.ID_CXP = p.ID_PAGO) AND
	NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE a.ID_CXP = p.ID_PAGO)
	
	UPDATE @TConciliacion SET
	ID_CXP = @id_cxp, SERIE = @serie, ID_CXC = @id_cxc, F_OPERACION_C =  @f_operacion_c,
	SERIE_ID = @serie_id, CVE_CHEQUERA_C = @cve_chequera_c, NOM_PROVEEDOR = @nom_proveedor, IMP_F_NETO = @imp_f_neto,
	DESCRIPCION_C = @descripcion_c, B_PAGO = @k_verdadero
	WHERE RowID  =  @RowCount

	INSERT INTO @TAsignados (ID_CXP) VALUES  (@id_cxp)

	SELECT TOP(1) 
	@id_cxp  =  ID_CXP, @serie = c.SERIE, @id_cxc = c.ID_CXC, @f_operacion_c = c.F_CAPTURA,
	@serie_id = c.SERIE + '-' + CONVERT(VARCHAR(10), LTRIM(c.ID_CXC)), 
	@cve_chequera_c = c.CVE_CHEQUERA, @nom_proveedor = p.NOM_PROVEEDOR,
	@imp_f_neto =  c.IMP_NETO, @descripcion_c  = c.TX_NOTA
	FROM CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p WHERE
	c.ID_PROVEEDOR  =  p.ID_PROVEEDOR  AND c.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
	dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo  AND
	c.IMP_NETO  =  @imp_transaccion  AND  SIT_CONCILIA_CXP  =  @k_no_concilia     AND
	NOT EXISTS (SELECT 1 FROM CI_PAGO_CXP p WHERE p.CVE_EMPRESA = c.CVE_EMPRESA AND p.ID_CXP = c.ID_CXP) AND
	NOT EXISTS (SELECT 1 FROM @TConciliacion cc WHERE cc.ID_CXP = c.ID_CXP) AND
	NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE a.ID_CXP = c.ID_CXP)
	
	UPDATE @TConciliacion SET
	ID_CXP = @id_cxp, SERIE = @serie, ID_CXC = @id_cxc, F_OPERACION_C =  @f_operacion_c,
	SERIE_ID = @serie_id, CVE_CHEQUERA_C = @cve_chequera_c, NOM_PROVEEDOR = @nom_proveedor, IMP_F_NETO = @imp_f_neto,
	DESCRIPCION_C = @descripcion_c, B_PAGO = @k_falso
	WHERE RowID  =  @RowCount

	INSERT INTO @TAsignados (ID_CXP) VALUES  (@id_cxp)

    SET    @RowCount = @RowCount + 1
  END

  select * fROM @TConciliacion

END
