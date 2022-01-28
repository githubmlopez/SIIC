USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
-------------------------------------------------------------------------------------------------
-- Obtiene información tanto de bancos como facturas (CXC) proponiendo conciliación por monto  --
-- Esta consumo es la que se presentará en la pantalla de conciliación bancaria                --                                                                                            --
-------------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtConcP1')
BEGIN
  DROP  PROCEDURE spObtConcP1
END
GO

--EXEC spObtConcP1 1,'CU','MARIO','SIIC','202006',203,1,1,'MDB437',0,' ',' '
CREATE PROCEDURE [dbo].[spObtConcP1]  
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

  SET @pBError    =  NULL
  SET @pError     =  NULL
  SET @pMsgError  =  NULL    

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_verdadero       bit          =  1,
           @k_falso           bit          =  0,
           @k_no_concilia     varchar(2)   =  'NC',
		   @k_activa          varchar(2)   =  'A',
           @k_cancelado       varchar(2)   =  'CA',
		   @k_cxc             varchar(3)   =  'CXC',
		   @k_parcial         varchar(1)   =  'P',
		   @k_anticipo          varchar(2) =  'A'

 DECLARE   @ano_mes             varchar(6),
		   @cve_chequera        varchar(8),
		   @cve_moneda          varchar(1),
		   @id_movto_bancario   int,
		   @f_operacion         date,
		   @imp_transaccion     numeric(12,2),
		   @descripcion         varchar(250),
		   @b_parcial           bit,
		   @referencia          varchar(20),
		   @ref_emp             varchar(50),
		   @id_referencia       varchar(50),
		   @id_concilia_cxc     int,
		   @serie               varchar(6),
		   @id_cxc              int,
		   @f_operacion_f       date,
		   @serie_id            varchar(20),
		   @cve_chequera_f      varchar(6),
		   @nom_cliente         varchar(75),
		   @imp_f_neto          numeric(12,2),
		   @descripcion_f       varchar(120),
		   @b_referencia        bit

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
			   B_REFERENCIA      bit,
			   B_PARCIAL         bit,
			   REFERENCIA        varchar(20),
			   REF_EMP           varchar(50),
			   ID_ANTICIPO       varchar(50),
			   ID_CONCILIA_CXC   int,
			   SERIE             varchar(6),
			   ID_CXC            int,
			   F_OPERACION_F     date,
			   SERIE_ID          varchar(20),
			   CVE_CHEQUERA_F    varchar(8),
			   NOM_CLIENTE       varchar(75),
			   IMP_F_NETO        numeric(12,2),
			   DESCRIPCION_F     varchar(120)
)
	 
  DECLARE  @TAsignados       TABLE
          (RowID             int  identity(1,1),
		   ID_CONCILIA_CXC   int)
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Se obtienen los movimientos bancarios que correspondan a la chequera, no se consideran los
-- movimientos que fueron registrados como anticipados
-----------------------------------------------------------------------------------------------------

  INSERT @TConciliacion  (CVE_EMPRESA, ANO_MES, ID_MOVTO_BANCARIO, F_OPERACION, CVE_CHEQUERA, IMP_TRANSACCION,  
                          DESCRIPCION, B_REFERENCIA, B_PARCIAL, REFERENCIA, REF_EMP, ID_ANTICIPO)
  SELECT @pCveEmpresa, m.ANO_MES, m.ID_MOVTO_BANCARIO,  m.F_OPERACION, m.CVE_CHEQUERA + '-' + ch.CVE_MONEDA, m.IMP_TRANSACCION,
         m.DESCRIPCION, B_REFERENCIA, @k_falso, m.REFERENCIA, m.REF_EMP, 0
  FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
  WHERE   m.CVE_EMPRESA        =  @pCveEmpresa     AND
          m.ANO_MES            =  @pAnoPeriodo     AND
          m.CVE_CHEQUERA       =  @pCveChequera    AND
          m.CVE_TIPO_MOVTO     =  @k_cxc           AND
		  m.SIT_CONCILIA_BANCO =  @k_no_concilia   AND
		  m.SIT_MOVTO         <>  @k_cancelado     AND
		  m.CVE_EMPRESA        =  ch.CVE_EMPRESA   AND
		  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA  AND
-- Excluye los movimientos que están registrados como Anticipos
		  NOT EXISTS
		 (SELECT 1 FROM CI_ANTICIPO_MOVTO a
          WHERE
		  a.CVE_EMPRESA       =  @pCveEmpresa      AND
		  a.CVE_TIPO_ANT      =  @k_cxc            AND
		  a.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO)

  ----------------------------------------------------------------------------------------------
  -- Se incluyen los anticipos que indiquen que es el ultimo anticipo y que se podrá conciliar
  -- este anticipo y los anteriores con una factura
  ----------------------------------------------------------------------------------------------
  INSERT @TConciliacion  (CVE_EMPRESA, ANO_MES, ID_MOVTO_BANCARIO, F_OPERACION, CVE_CHEQUERA, IMP_TRANSACCION,  
                          DESCRIPCION, B_REFERENCIA, B_PARCIAL, REFERENCIA, REF_EMP, ID_ANTICIPO)
  SELECT @pCveEmpresa, m.ANO_MES,  a.ID_ANTICIPO, F_OPERACION, m.CVE_CHEQUERA + '-' + ch.CVE_MONEDA + '-' +
         @k_anticipo, a.IMP_ACUM_ANT, a.TX_NOTA, B_REFERENCIA, m.REFERENCIA, m.REF_EMP, @k_verdadero,
         a.ID_ANTICIPO
  FROM   CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_ANTICIPO a, CI_ANTICIPO_MOVTO am
  WHERE  a.CVE_TIPO_ANT       =  @k_cxc               AND
		 a.CVE_EMPRESA        =  am.CVE_EMPRESA       AND
		 a.ID_ANTICIPO        =  am.ID_ANTICIPO       AND
		 a.CVE_TIPO_ANT       =  am.CVE_TIPO_ANT      AND
		 am.ANO_MES_APLIC     =  @pAnoPeriodo         AND
		 am.B_ULTIMO          =  @k_verdadero         AND
		 am.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND
         m.CVE_EMPRESA        =  ch.CVE_EMPRESA       AND
		 m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
		 m.SIT_CONCILIA_BANCO =  @k_no_concilia       AND
		 m.SIT_MOVTO         <>  @k_cancelado     

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
		   @b_referencia       =  B_REFERENCIA,
		   @b_parcial          =  B_PARCIAL,
		   @referencia         =  REFERENCIA,
		   @ref_emp            =  REF_EMP,
		   @id_referencia      =  ID_ANTICIPO,
           @id_concilia_cxc    =  ID_CONCILIA_CXC,
		   @serie              =  SERIE,
		   @id_cxc             =  ID_CXC,
		   @f_operacion_f      =  F_OPERACION_F,
           @serie_id           =  SERIE_ID,
		   @cve_chequera_f     =  CVE_CHEQUERA_F,
		   @nom_cliente        =  NOM_CLIENTE,
		   @imp_f_neto         =  IMP_F_NETO,
		   @descripcion_f      =  DESCRIPCION_F  FROM  @TConciliacion
	WHERE  RowID  =  @RowCount

	SELECT TOP(1) 
	@id_concilia_cxc  =  ID_CONCILIA_CXC, @serie = f.SERIE_CTE, @id_cxc = f.FOLIO_CTE, @f_operacion_f = f.F_OPERACION,
	@serie_id = f.SERIE_CTE + '-' + CONVERT(VARCHAR(10), LTRIM(f.FOLIO_CTE)), 
	@cve_chequera_f = f.CVE_CHEQUERA, @nom_cliente = c.NOM_CLIENTE,
	@imp_f_neto =  f.IMP_F_NETO, @descripcion_f  = f.TX_NOTA
	FROM  CI_CUENTA_X_COBRAR f, CI_CLIENTE c WHERE
	f.CVE_EMPRESA = @pCveEmpresa AND
	f.ID_CLIENTE  =  c.ID_CLIENTE  AND f.CVE_CHEQUERA = SUBSTRING(@cve_chequera,1,6) AND
--	dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoPeriodo  AND
	IMP_F_NETO  =  @imp_transaccion  AND  f.SIT_CONCILIA_CXC  =  @k_no_concilia   AND
	f.SIT_TRANSACCION = @k_activa AND
	NOT EXISTS (SELECT 1 FROM @TAsignados a WHERE a.ID_CONCILIA_CXC = f.ID_CONCILIA_CXC)
	
	UPDATE @TConciliacion SET
	ID_CONCILIA_CXC = @id_concilia_cxc, SERIE = @serie, ID_CXC = @id_cxc, F_OPERACION_F =  @f_operacion_f,
	SERIE_ID = @serie_id, CVE_CHEQUERA_F = @cve_chequera_f, NOM_CLIENTE = @nom_cliente, IMP_F_NETO = @imp_f_neto,
	DESCRIPCION_F = @descripcion_f
	WHERE RowID  =  @RowCount

	INSERT INTO @TAsignados (ID_CONCILIA_CXC) VALUES  (@id_concilia_cxc)

    SET    @RowCount = @RowCount + 1
  END

  SELECT * FROM @TConciliacion

END
