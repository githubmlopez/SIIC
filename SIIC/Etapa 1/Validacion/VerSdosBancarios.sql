USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
-- exec spVerSdosBancarios  'CU', 'MLOPEZ', '201906', 12,371, ' ', ' '
ALTER PROCEDURE [dbo].[spVerSdosBancarios] @pCveEmpresa varchar(4), @pCveUsuario varchar(8), @pAnoMes  varchar(6), 
                                           @pIdProceso numeric(9), @pIdTarea numeric(9), @pError varchar(80) OUT,
								           @pMsgError varchar(400) OUT
AS
BEGIN

  DECLARE   @ano           int,
            @mes           int, 
            @chequera      varchar(6),
            @ano_mes       varchar(6),
            @saldo_ini     numeric(12,2),
            @saldo_fin     numeric(12,2),
            @f_inicio      date,
            @f_fin         date,
            @cargos        numeric(12,2),
            @abonos        numeric(12,2),
            @diferencia    numeric(12,2),
	        @tipo_chequera varchar(2),
			@num_reg_proc  int = 0

  DECLARE   @k_activa      varchar(1)   =  'A',
            @k_falso       bit          =  0,
	  	    @k_verdadero   bit          =  1,
		    @k_no_concilia varchar(2)   =  'NC',
            @k_cargo       varchar(1)   =  'C',
		    @k_abono       varchar(1)   =  'A',
   		    @k_activo      varchar(1)   =  'A',
			@k_error       varchar(1)   =  'E',
			@k_no_act      numeric(9,0) = 99999,
			@k_no_aplica   varchar(2)   = 'NA',
			@k_chequera    varchar(2)   = 'CH'

  DECLARE   @NunRegistros  int, 
            @RowCount      int,
            @cve_chequera  varchar(6),
		    @cve_ind_cargo varchar(10),
			@cve_ind_abono varchar(10)
          
  DECLARE SALBANC CURSOR FOR SELECT  cp.ANO_MES, cp.CVE_CHEQUERA, cp.F_INICIO, cp.F_FIN, cp.SDO_INICIO_MES, cp.SDO_FIN_MES, ch.CVE_TIPO_CHEQ
  FROM  CI_CHEQUERA_PERIODO cp, CI_CHEQUERA ch
  WHERE
  cp.ANO_MES      =  @pAnoMes       AND
  cp.CVE_CHEQUERA = ch.CVE_CHEQUERA
  
  OPEN  SALBANC 
  FETCH SALBANC INTO  @ano_mes, @chequera, @f_inicio, @f_fin, @saldo_ini, @saldo_fin, @tipo_chequera  
	                                      
  WHILE (@@fetch_status = 0 )
  BEGIN 

  SET @ano  = CONVERT(int,SUBSTRING(@ano_mes,1,4))
  SET @mes  = CONVERT(int,SUBSTRING(@ano_mes,5,2))

  SELECT @cargos = ISNULL(SUM(oper.cargo),0), @abonos = ISNULL(SUM(oper.abono),0),
  @diferencia = ISNULL((SUM(oper.abono) - SUM(oper.cargo) + @saldo_ini - @saldo_fin),0)
  FROM 
 (SELECT DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, SUBSTRING(m.DESCRIPCION,1,40) as descripcion,
  CASE    
  WHEN m.CVE_CARGO_ABONO = @k_cargo then M.IMP_TRANSACCION     
  ELSE 0
  END as cargo,
  CASE    
  WHEN m.CVE_CARGO_ABONO = @k_abono then M.IMP_TRANSACCION    
  ELSE 0
  END as abono,
  0 as saldo
  FROM CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
  WHERE f.ID_VENTA             =  v.ID_VENTA              AND
        v.ID_CLIENTE           =  c.ID_CLIENTE            AND
        f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
        m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
        year(m.F_OPERACION)    =  @ano                    AND
        MONTH(m.F_OPERACION)   =  @mes                    AND
        m.F_OPERACION          >= @f_inicio               AND
        m.F_OPERACION          <= @f_fin                  AND
        m.CVE_CHEQUERA         =  @chequera               AND
        m.SIT_MOVTO            =  @k_activo               AND    
        f.SIT_TRANSACCION      =  @k_activo                     
  UNION
  SELECT DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, SUBSTRING(m.DESCRIPCION,1,40) as descripcion, m.IMP_TRANSACCION as cargo, 0 as abono, 0 as saldo
  FROM CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P ip, CI_PROVEEDOR p, CI_CONCILIA_C_X_P ccp, CI_MOVTO_BANCARIO m, CI_OPERACION_CXP o
  WHERE cp.ID_PROVEEDOR        =  p.ID_PROVEEDOR          AND
        cp.ID_CONCILIA_CXP     =  ccp.ID_CONCILIA_CXP     AND
        cp.CVE_EMPRESA         =  ip.CVE_EMPRESA          AND
	    cp.ID_CXP              =  ip.ID_CXP               AND
        ip.CVE_OPERACION       =  o.CVE_OPERACION         AND
        m.ID_MOVTO_BANCARIO    =  ccp.ID_MOVTO_BANCARIO   AND
        year(m.F_OPERACION)    =  @ano                    AND
        MONTH(m.F_OPERACION)   =  @mes                    AND
        m.F_OPERACION          >= @f_inicio               AND
        m.F_OPERACION          <= @f_fin                  AND
        m.CVE_CHEQUERA         =  @chequera               AND
        m.SIT_MOVTO            =  @k_activo                   
  UNION            
  SELECT  DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, SUBSTRING(m.DESCRIPCION,1,40) as descripccion,
  CASE    
  WHEN m.CVE_CARGO_ABONO = @k_cargo then M.IMP_TRANSACCION     
  ELSE 0
  END as cargo,
  CASE    
  WHEN m.CVE_CARGO_ABONO = @k_abono then M.IMP_TRANSACCION    
  ELSE 0
  END as abono,
  0 as saldo
  FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t
  WHERE m.CVE_TIPO_MOVTO       =  t.CVE_TIPO_MOVTO        AND
        year(m.F_OPERACION)    =  @ano                    AND
        MONTH(m.F_OPERACION)   =  @mes                    AND
        m.F_OPERACION          >= @f_inicio               AND
        m.F_OPERACION          <= @f_fin                  AND
        m.CVE_CHEQUERA         =  @chequera               AND
		m.SIT_MOVTO            =  @k_activo               AND
       (t.B_CONCILIA           =  @k_falso                OR
        M.SIT_CONCILIA_BANCO   =  @k_no_concilia)) AS oper


  IF  @tipo_chequera = @k_chequera 
  BEGIN
    UPDATE CI_CHEQUERA_PERIODO SET SDO_FIN_MES_CALC = @saldo_ini + @abonos - @cargos WHERE ANO_MES = @ano_mes AND CVE_CHEQUERA = @chequera
  END
  ELSE
  BEGIN
--    SELECT @tipo_chequera, ' ' + CONVERT(varchar(18),@saldo_ini)  + ' ' + CONVERT(varchar(18),@cargos) + ' ' + CONVERT(varchar(18),@abonos) 
    UPDATE CI_CHEQUERA_PERIODO SET SDO_FIN_MES_CALC = (@saldo_ini) - @abonos + @cargos WHERE ANO_MES = @ano_mes AND CVE_CHEQUERA = @chequera
--    SELECT CONVERT(varchar(18),(@saldo_ini) - @abonos + @cargos)
  END
  FETCH SALBANC INTO  @ano_mes, @chequera, @f_inicio, @f_fin, @saldo_ini, @saldo_fin, @tipo_chequera 

  END


  IF  EXISTS (SELECT 1
              FROM   CI_CHEQUERA_PERIODO cp
              WHERE  ANO_MES  =  @pAnoMes  AND
                     cp.SDO_FIN_MES <> cp.SDO_FIN_MES_CALC)
  BEGIN
    SET  @num_reg_proc = @num_reg_proc + 1
	SET  @pError    =  'Error en Saldos Bancarios ' +  ' ' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(),' '))
    SELECT @pMsgError
--    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError  
  END

  CLOSE SALBANC 
  DEALLOCATE SALBANC
  EXEC spActRegGral  @pCveEmpresa, @pIdProceso, @pIdTarea, @num_reg_proc

-------------------------------------------------------------------------------
-- Actualizaci�n de Indicadores para movimientos Bancarios
-------------------------------------------------------------------------------

  DECLARE  @TChequera       TABLE
          (RowID            int  identity(1,1),
		   CVE_CHEQUERA     varchar(6),
		   CVE_IND_CARGO    varchar(10),
		   CVE_IND_ABONO    varchar(10))
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TChequera  (CVE_CHEQUERA, CVE_IND_CARGO, CVE_IND_ABONO)  
  SELECT CVE_CHEQUERA, CVE_IND_CARGO, CVE_IND_ABONO  FROM CI_CHEQUERA WHERE
  ISNULL(CVE_IND_CARGO,@k_no_aplica) <> @k_no_aplica AND ISNULL(CVE_IND_ABONO,@k_no_aplica) <> @k_no_aplica

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_chequera  = CVE_CHEQUERA, @cve_ind_cargo = CVE_IND_CARGO,
	       @cve_ind_abono = CVE_IND_ABONO FROM @TChequera
	WHERE  RowID  =  @RowCount

    SET @cargos  =  0
	SET @abonos  =  0

	SELECT @cargos  =  isnull(SUM(IMP_TRANSACCION),0)  FROM CI_MOVTO_BANCARIO WHERE 
	CVE_CHEQUERA    =  @cve_chequera  AND
	CVE_CARGO_ABONO =  @k_cargo       AND
	ANO_MES         =  @pAnoMes       AND
	SIT_MOVTO       =  @k_activo
	EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @cve_ind_cargo,  @cargos, @k_no_act

    SELECT @abonos  =  isnull(SUM(IMP_TRANSACCION),0)  FROM CI_MOVTO_BANCARIO WHERE 
	CVE_CHEQUERA    =  @cve_chequera  AND
	CVE_CARGO_ABONO =  @k_abono       AND
	ANO_MES         =  @pAnoMes       AND
	SIT_MOVTO       =  @k_activo
	EXEC spInsIndicador @pCveEmpresa, @pAnoMes, @cve_ind_abono,  @abonos, @k_no_act

	SET @RowCount   = @RowCount + 1
  END

END 