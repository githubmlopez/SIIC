USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCalculaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec spRepSaldosBancarios '201804', 'MPB981', 'II'
ALTER PROCEDURE [dbo].[spRepSaldosBancarios] @pAnoMes varchar(6), @pChequera varchar(6), @pOpcion varchar(2)
AS
BEGIN

DECLARE   @saldo_ini    numeric(12,2),
          @saldo_fin    numeric(12,2)
          
DECLARE   @id_movto_banc  int,
          @f_op_temp      date,
          @desc_temp      VARCHAR(40),
		  @cve_tipo_movto varchar(6),
          @fac_temp       VARCHAR(18),
          @imp_cargo      numeric(12,2),
          @imp_abono      numeric(12,2),
          @imp_saldo      numeric(12,2),
          @imp_saldo_cal  numeric(12,2),
          @id_movto_ant   int

DECLARE   @k_activa       varchar(1)  =  'A',
          @k_cargo        varchar(1)  =  'C',
		  @k_abono        varchar(1)  =  'A',
		  @k_todo         varchar(2)  =  'TO',
		  @k_egresos      varchar(2)  =  'EG',
		  @k_ingresos     varchar(2)  =  'IN',
		  @k_no_concilia  varchar(2)  =  'NC',
		  @k_ing_identif  varchar(2)  =  'II',
		  @k_egr_identif  varchar(2)  =  'EI',
		  @k_cxc          varchar(6)  =  'CXC'

--SET  @pano       = 2016
--SET  @pmes       = 03
--SET  @pChequera  = 'MPB981'



  IF   EXISTS (SELECT 1 FROM CI_CHEQUERA_PERIODO WHERE  ANO_MES  =  @pAnoMes  AND  CVE_CHEQUERA = @pChequera)
  BEGIN
    SELECT @saldo_ini = ch.SDO_INICIO_MES, @saldo_fin = ch.SDO_FIN_MES
    FROM   CI_CHEQUERA_PERIODO ch WHERE
           ANO_MES  =  @pAnoMes  AND
           ch.CVE_CHEQUERA = @pChequera
  END
  ELSE
  BEGIN
    SET @saldo_ini = 0
	SET @saldo_FIN = 0
  END

-- SELECT ' Saldo Ini ==> ' + CONVERT(varchar(18), @saldo_ini)
SET  @imp_saldo = @saldo_ini
-- SELECT ' Imp Saldo ==> ' + CONVERT(varchar(18), @imp_saldo)

IF OBJECT_ID('tempdb..#movbanc') IS NOT NULL DROP TABLE #movbanc
ELSE
  CREATE TABLE #movbanc( 
  CVE_CHEQUERA      varchar(6),
  ID_MOVTO_BANCARIO varchar(10),
  F_OPERACION       varchar(10),
  DESCRIPCION       varchar(40),
  CVE_TIPO_MOVTO    varchar(6),
  IMP_CARGO         numeric(12,2),
  IMP_ABONO         numeric(12,2),     
  SALDO             numeric(12,2),
  PRODUCTO          varchar(50),
  FACTURA           varchar(18),
  CVE_F_MONEDA      varchar(1),
  NOM_CLIENTE       varchar(120),
  IMP_F_BRUTO       numeric(12,2),
  IMP_F_IVA         numeric(12,2),
  IMP_F_NETO        numeric(12,2),
  TX_NOTA           varchar(200))

INSERT INTO #movbanc
SELECT m.CVE_CHEQUERA, LTRIM(CONVERT(VARCHAR(10),m.ID_MOVTO_BANCARIO)), LEFT(CONVERT(VARCHAR, m.F_OPERACION, 120), 10) AS F_OPERACION,
SUBSTRING(m.DESCRIPCION,1,40) AS descripcion , m.CVE_TIPO_MOVTO, 
CASE    
WHEN m.CVE_CARGO_ABONO = @k_cargo THEN m.IMP_TRANSACCION     
ELSE 0
END AS cargo,
CASE    
WHEN m.CVE_CARGO_ABONO = @k_abono THEN m.IMP_TRANSACCION    
ELSE 0
END AS abono,
0 saldo,
SUBSTRING((dbo.fnArmaProducto(f.ID_CONCILIA_CXC)),1,50) AS producto, f.SERIE + convert(varchar,f.ID_CXC) AS identificador,
       f.CVE_F_MONEDA AS moneda, c.NOM_CLIENTE AS clientprov, f.IMP_F_BRUTO AS impbruto, f.IMP_F_IVA AS iva, f.IMP_F_NETO AS impneto, SUBSTRING(f.TX_NOTA,1,200) AS nota
FROM  CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
WHERE f.ID_VENTA             =  v.ID_VENTA              AND
      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
	  dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes AND              
      m.SIT_MOVTO            =  @k_activa               AND    
      f.SIT_TRANSACCION      =  @k_activa               AND
     (@pChequera             =  @k_todo                 OR
	  m.CVE_CHEQUERA         =  @pChequera)             AND
	 (@pOpcion               =  @k_ing_identif          OR
	  @pOpcion               =  @k_todo                 OR
	  @pOpcion               =  @k_ingresos)
UNION
SELECT m.CVE_CHEQUERA, LTRIM(CONVERT(VARCHAR(10),m.ID_MOVTO_BANCARIO)), LEFT(CONVERT(VARCHAR, m.F_OPERACION, 120), 10) AS F_OPERACION,
       SUBSTRING(m.DESCRIPCION,1,40) AS descripcion, m.CVE_TIPO_MOVTO, 
       m.IMP_TRANSACCION AS cargo, 0 AS abono, 0 AS saldo, dbo.fnArmaProductoCP(cp.ID_CXP), convert(varchar,cp.ID_CXP) AS identificador,
       cp.CVE_MONEDA AS moneda, p.NOM_PROVEEDOR AS clientprov, cp.IMP_BRUTO AS impbruto, cp.IMP_IVA AS iva, cp.IMP_NETO AS impneto, SUBSTRING(cp.TX_NOTA,1,200) AS nota
from CI_CUENTA_X_PAGAR cp, CI_PROVEEDOR p, CI_ITEM_C_X_P ip, CI_CONCILIA_C_X_P ccp, CI_MOVTO_BANCARIO m, CI_OPERACION_CXP o
WHERE cp.ID_PROVEEDOR        =  p.ID_PROVEEDOR          AND
      cp.ID_CONCILIA_CXP     =  ccp.ID_CONCILIA_CXP     AND
      cp.CVE_EMPRESA         =  ip.CVE_EMPRESA          AND
	  cp.ID_CXP              =  ip.ID_CXP               AND
      ip.CVE_OPERACION       =  o.CVE_OPERACION         AND
      m.ID_MOVTO_BANCARIO    =  ccp.ID_MOVTO_BANCARIO   AND
	  dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes AND              
      m.SIT_MOVTO            =  @k_activa               AND    
      cp.SIT_C_X_P           =  @k_activa               AND
     (@pChequera             =  @k_todo                 OR
	  m.CVE_CHEQUERA         =  @pChequera)             AND
	 (@pOpcion               =  @k_egr_identif          OR
	  @pOpcion               =  @k_todo                 OR
	  @pOpcion               =  @k_egresos)                 
UNION            
SELECT m.CVE_CHEQUERA, LTRIM(CONVERT(VARCHAR(10),m.ID_MOVTO_BANCARIO)), LEFT(CONVERT(VARCHAR, m.F_OPERACION, 120), 10) AS F_OPERACION, 
SUBSTRING(m.DESCRIPCION,1,40) AS descripccion, m.CVE_TIPO_MOVTO, 
CASE    
WHEN m.CVE_CARGO_ABONO = @k_cargo THEN M.IMP_TRANSACCION     
ELSE 0
END AS cargo,
CASE    
WHEN m.CVE_CARGO_ABONO = @k_abono THEN M.IMP_TRANSACCION    
ELSE 0
END AS abono,
0 AS saldo,
SUBSTRING(t.DESCRIPCION,1,40),' ' AS identificador,' ' AS moneda, ' ' AS clientprov, 0 AS impbruto, 0 AS iva, 0 AS impneto, ' ' AS nota
FROM CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t
WHERE m.CVE_TIPO_MOVTO       =  t.CVE_TIPO_MOVTO        AND
	  dbo.fnArmaAnoMes (YEAR(m.F_OPERACION), MONTH(m.F_OPERACION))  = @pAnoMes AND              
      m.SIT_CONCILIA_BANCO   =  @k_no_concilia          AND
     (m.CVE_CHEQUERA         =  @pChequera              OR
	  @pChequera             =  @k_todo)                AND
	 (@pOpcion               =  @k_todo                 OR
	  @pOpcion               =  @k_no_concilia          OR
	 (m.CVE_CARGO_ABONO      =  @k_abono                AND
	  @pOpcion               =  @k_ingresos)            OR
     (m.CVE_CARGO_ABONO      =  @k_cargo                AND
	  @pOpcion               =  @k_egresos))            
     order by CVE_CHEQUERA, F_OPERACION, cargo -- AS oper

DECLARE salbanc cursor for SELECT ID_MOVTO_BANCARIO, F_OPERACION, DESCRIPCION, FACTURA, IMP_CARGO, IMP_ABONO
        FROM #movbanc 

OPEN  salbanc 

FETCH salbanc INTO  @id_movto_banc, @f_op_temp, @desc_temp, @fac_temp, @imp_cargo, @imp_abono  

SET @id_movto_ant =  0

WHILE (@@fetch_status = 0 )
BEGIN 
-- SELECT ' Imp Saldo Entra ==> ' + CONVERT(varchar(18), @imp_saldo)	
-- SELECT ' Imp Saldo Abono ==> ' + CONVERT(varchar(18), @imp_abono)
-- SELECT ' Imp Saldo Cargo ==> ' + CONVERT(varchar(18), @imp_cargo)
   IF  @id_movto_ant  <>  @id_movto_banc
   BEGIN
     IF  @pOpcion  =  @k_todo
     BEGIN
       IF  @imp_abono = 0
       BEGIN
         SET @imp_saldo  =  @imp_saldo - @imp_cargo
       END
       ELSE
       BEGIN
         SET @imp_saldo  =  @imp_saldo + @imp_abono
       END
     END
	 ELSE
	 BEGIN
	   SET @imp_saldo = 0
	 END
   END
   ELSE
   BEGIN
     UPDATE #movbanc SET CVE_CHEQUERA = ' ', ID_MOVTO_BANCARIO = ' ', F_OPERACION = ' ', DESCRIPCION = ' ', CVE_TIPO_MOVTO = ' ',
	                     IMP_CARGO = 0, IMP_ABONO = 0, SALDO = @imp_saldo
     WHERE  F_OPERACION = @f_op_temp and DESCRIPCION = @desc_temp and
            FACTURA     = @fac_temp  and IMP_CARGO   = @imp_cargo and
            IMP_ABONO   = @imp_abono and ID_MOVTO_BANCARIO = @id_movto_banc 
   END   
   SET @id_movto_ant = @id_movto_banc
    
 -- SELECT ' Imp Saldo Sale==> ' + CONVERT(varchar(18), @imp_saldo)
   
   UPDATE #movbanc SET saldo = @imp_saldo  WHERE F_OPERACION = @f_op_temp and DESCRIPCION = @desc_temp and
                                                 FACTURA     = @fac_temp  and IMP_CARGO   = @imp_cargo and
                                                 IMP_ABONO   = @imp_abono and ID_MOVTO_BANCARIO = @id_movto_banc 
  
   FETCH salbanc INTO  @id_movto_banc, @f_op_temp, @desc_temp, @fac_temp, @imp_cargo, @imp_abono  

END

CLOSE salbanc 
DEALLOCATE salbanc 

SELECT * FROM #movbanc

END








