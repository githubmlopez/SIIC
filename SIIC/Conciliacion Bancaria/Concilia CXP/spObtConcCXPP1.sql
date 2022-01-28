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

--EXEC spObtConcCXPP1 1,'CU','MARIO','SIIC','201903',203,1,1,'MPB981',0,' ',' '
CREATE PROCEDURE [dbo].[spObtConcCXPP1]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pCveChequera   varchar(6),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_verdadero       bit         =  1,
           @k_falso           bit         =  0,
           @k_no_concilia     varchar(2)  =  'NC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_cxp             varchar(3)  =  'CXP',
		   @k_pago            varchar(4)  =  'PAGO',
		   @k_anticipo        varchar(1)  =  'A',
		   @k_normal          varchar(1)  =  'N',
		   @k_pago_cxp        varchar(1)  =  'P'

 DECLARE   @ano_mes             varchar(6),
		   @cve_chequera        varchar(8),
		   @cve_moneda          varchar(1),
		   @id_movto_bancario   int,
		   @f_operacion         date,
		   @imp_transaccion     numeric(12,2),
		   @descripcion         varchar(250),
		   @b_parcial           bit,
		   @id_anticipo         varchar(50),
		   @id_cxp              int,
		   @serie_prov          varchar(20),
		   @folio_prov          varchar(40),
		   @f_operacion_c       date,
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
		   CVE_CHEQUERA      varchar(10),
		   IMP_TRANSACCION   numeric(12,2),
		   DESCRIPCION       varchar(250),
		   B_PARCIAL         bit,
		   ID_ANTICIPO       varchar(50),
		   ID_CXP            int,
		   SERIE_PROV        varchar(20),
           FOLIO_PROV        varchar(40),
		   F_OPERACION_C     date,
		   CVE_CHEQUERA_C    varchar(8),
		   NOM_PROVEEDOR     varchar(75),
		   IMP_F_NETO        numeric(12,2),
		   DESCRIPCION_C     varchar(120),
		   B_PAGO            bit
)
	 
  DECLARE  @TAsignados       TABLE
          (RowID             int  identity(1,1),
           CVE_TIPO          VARCHAR(1),
		   ID_CXP            int)
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TConciliacion  (CVE_EMPRESA, ANO_MES, ID_MOVTO_BANCARIO, F_OPERACION, CVE_CHEQUERA, IMP_TRANSACCION,  
                          DESCRIPCION, B_PARCIAL, ID_ANTICIPO)
  SELECT @pCveEmpresa, m.ANO_MES, m.ID_MOVTO_BANCARIO,  m.F_OPERACION, m.CVE_CHEQUERA + '-' + ch.CVE_MONEDA, m.IMP_TRANSACCION,
         m.DESCRIPCION, @k_falso, 0
  FROM   CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE   -- m.ANO_MES            =  @pAnoPeriodo     AND
          m.CVE_CHEQUERA       =  @pCveChequera    AND
          m.CVE_TIPO_MOVTO     =  @k_cxp           AND
		  m.SIT_CONCILIA_BANCO =  @k_no_concilia   AND
		  m.SIT_MOVTO         <>  @k_cancelado     AND
		  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA  AND
		  NOT EXISTS
		 (SELECT 1 FROM CI_ANTICIPO_MOVTO a
          WHERE
		  a.CVE_EMPRESA       =  @pCveEmpresa      AND
		  a.CVE_TIPO_ANT      =  @k_cxp            AND
		  a.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO)

  INSERT @TConciliacion  (CVE_EMPRESA, ANO_MES, ID_MOVTO_BANCARIO, F_OPERACION, CVE_CHEQUERA, IMP_TRANSACCION,  
         DESCRIPCION, B_PARCIAL, ID_ANTICIPO)
  SELECT @pCveEmpresa, m.ANO_MES,  m.ID_MOVTO_BANCARIO, F_OPERACION, m.CVE_CHEQUERA + '-' + ch.CVE_MONEDA + '-' +
         @k_anticipo, a.IMP_ACUM_ANT, m.DESCRIPCION, @k_verdadero,
         a.ID_ANTICIPO
  FROM   CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_ANTICIPO a, CI_ANTICIPO_MOVTO am
  WHERE  a.CVE_TIPO_ANT       =  @k_cxp               AND
		 a.CVE_EMPRESA        =  am.CVE_EMPRESA       AND
		 a.ID_ANTICIPO        =  am.ID_ANTICIPO       AND
		 a.CVE_TIPO_ANT       =  am.CVE_TIPO_ANT      AND
		 am.ANO_MES_APLIC     =  @pAnoPeriodo         AND
		 am.B_ULTIMO          =  @k_verdadero         AND
		 am.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND
		 m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
		 m.SIT_CONCILIA_BANCO =  @k_no_concilia       AND
		 m.SIT_MOVTO         <>  @k_cancelado     

  SET @NunRegistros = (SELECT COUNT(*) FROM @TConciliacion)
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
--  SELECT * FROM @TConciliacion
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_MES,
		   @id_movto_bancario  =  ID_MOVTO_BANCARIO,
		   @f_operacion        =  F_OPERACION,
		   @cve_chequera       =  CVE_CHEQUERA,
		   @imp_transaccion    =  IMP_TRANSACCION,
		   @descripcion        =  DESCRIPCION,
		   @b_parcial          =  B_PARCIAL,
		   @id_anticipo        =  ID_ANTICIPO,
           @id_cxp             =  ID_CXP,
		   @serie_prov         =  SERIE_PROV,
		   @folio_prov         =  FOLIO_PROV,
		   @f_operacion_c      =  F_OPERACION_C,
		   @cve_chequera_c     =  CVE_CHEQUERA_C,
		   @nom_proveedor      =  NOM_PROVEEDOR,
		   @imp_f_neto         =  IMP_F_NETO,
		   @descripcion_c      =  DESCRIPCION_C  FROM  @TConciliacion
	WHERE  RowID  =  @RowCount

	IF EXISTS (SELECT 1
	FROM CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p WHERE
	c.ID_PROVEEDOR  =  p.ID_PROVEEDOR  AND c.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
--	dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo  AND
	c.IMP_NETO  =  @imp_transaccion  AND  SIT_CONCILIA_CXP  =  @k_no_concilia     AND
	NOT EXISTS (SELECT 1 FROM CI_PAGO_CXP p WHERE p.CVE_EMPRESA = c.CVE_EMPRESA AND p.ID_CXP = c.ID_CXP) AND
	NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE a.ID_CXP = c.ID_CXP))
	BEGIN
  	  SELECT TOP(1) 
	  @id_cxp  =  ID_CXP, @folio_prov = c.FOLIO_PROV, @f_operacion_c = c.F_CAPTURA,
	  @serie_prov = SUBSTRING(c.SERIE_PROV + '-' +  FOLIO_PROV,1,20), 
	  @cve_chequera_c = c.CVE_CHEQUERA, @nom_proveedor = p.NOM_PROVEEDOR,
	  @imp_f_neto =  c.IMP_NETO, @descripcion_c  = c.TX_NOTA
	  FROM CI_CUENTA_X_PAGAR c, CI_PROVEEDOR p WHERE
	  c.ID_PROVEEDOR  =  p.ID_PROVEEDOR  AND c.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
--	dbo.fnArmaAnoMes (YEAR(c.F_CAPTURA), MONTH(c.F_CAPTURA))  = @pAnoPeriodo  AND
	  c.IMP_NETO  =  @imp_transaccion  AND  SIT_CONCILIA_CXP  =  @k_no_concilia     AND
	  NOT EXISTS (SELECT 1 FROM CI_PAGO_CXP p WHERE p.CVE_EMPRESA = c.CVE_EMPRESA AND p.ID_CXP = c.ID_CXP) AND
	  NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE  a.CVE_TIPO = @k_pago_cxp AND a.ID_CXP = c.ID_CXP)
	
	  UPDATE @TConciliacion SET
	  ID_CXP = @id_cxp, SERIE_PROV = @serie_prov, FOLIO_PROV = @folio_prov, F_OPERACION_C =  @f_operacion_c,
	  CVE_CHEQUERA_C = @cve_chequera_c, NOM_PROVEEDOR = @nom_proveedor, IMP_F_NETO = @imp_f_neto,
	  DESCRIPCION_C = @descripcion_c, B_PAGO = @k_falso
	  WHERE RowID  =  @RowCount

      INSERT INTO @TAsignados (CVE_TIPO, ID_CXP) VALUES  (@k_normal, @id_cxp)

	END

	IF  EXISTS (SELECT 1 
    FROM CI_PAGO p, CI_CHEQUERA ch WHERE
    p.CVE_CHEQUERA = ch.CVE_CHEQUERA AND
	p.CVE_EMPRESA = @pCveEmpresa AND
	p.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
--	dbo.fnArmaAnoMes (YEAR(p.F_PAGO), MONTH(p.F_PAGO))  = @pAnoPeriodo  AND
    p.ANOMES_CONT  = @pAnoPeriodo  AND
	p.IMP_NETO  =  @imp_transaccion AND
	NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE a.ID_CXP = p.ID_PAGO))   AND
    @b_parcial  <>  @k_verdadero
	BEGIN
	  SELECT TOP(1) 
	  @id_cxp  =  p.ID_PAGO, @serie_prov = @k_pago, @folio_prov = ID_PAGO, @f_operacion_c = p.F_PAGO, 
	  @cve_chequera_c = p.CVE_CHEQUERA + '-' + ch.CVE_MONEDA, @nom_proveedor = p.BENEF_PAGO,
	  @imp_f_neto =  p.IMP_NETO, @descripcion_c  = p.TX_NOTA
	  FROM CI_PAGO p, CI_CHEQUERA ch WHERE
	  p.CVE_CHEQUERA = ch.CVE_CHEQUERA AND
	  p.CVE_EMPRESA = @pCveEmpresa AND
	  p.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
      p.ANOMES_CONT  = @pAnoPeriodo  AND
	  p.IMP_NETO  =  @imp_transaccion AND
	  NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE  a.CVE_TIPO = @k_pago_cxp AND a.ID_CXP = p.ID_PAGO)
	
	  UPDATE @TConciliacion SET
	  ID_CXP = @id_cxp, SERIE_PROV = @serie_prov, FOLIO_PROV = @folio_prov, F_OPERACION_C =  @f_operacion_c,
	  CVE_CHEQUERA_C = @cve_chequera_c, NOM_PROVEEDOR = @nom_proveedor, IMP_F_NETO = @imp_f_neto,
	  DESCRIPCION_C = @descripcion_c, B_PAGO = @k_verdadero
	  WHERE RowID  =  @RowCount

      INSERT INTO @TAsignados (CVE_TIPO, ID_CXP) VALUES  (@k_pago_cxp, @id_cxp)
	END
    SET    @RowCount = @RowCount + 1
  END

  select * FROM @TConciliacion

END
