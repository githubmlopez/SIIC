USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spCalNegTerceros 2

ALTER PROCEDURE [dbo].[spCalNegTerceros]  @pNegocio int
AS
BEGIN
  DECLARE  @NumRegistros int,
           @RowCount     int

  DECLARE  
           @k_peso       varchar(1),
		   @k_dolar      varchar(1),
		   @k_cta_pagar  varchar(1),
		   @k_factura    varchar(1),
		   @k_comision   varchar(1),
		   @k_gastos     varchar(1),
		   @k_otros_gtos varchar(1),
		   @k_abono      varchar(1)  =  'A',
		   @k_cargo      varchar(1)  =  'C',
		   @k_fact_iva   int         =  1.16
  
  SET  @k_peso       =  'P'
  SET  @k_dolar      =  'D'
  SET  @k_factura    =  'F'
  SET  @k_cta_pagar  =  'P'
  SET  @k_comision   =  'C'
  SET  @k_gastos     =  'O'
  
 
  -- Create a temporary table, note the IDENTITY
  --  column that will be used to loop through
  --  the rows of this table

  SET  @NumRegistros  =  0
  SET  @RowCount      =  0

  CREATE TABLE #PLNEGOCIO (
               RowID            int IDENTITY(1, 1), 
               CLAVE            varchar(2),
			   F_OPERACION      varchar(10),
			   IDENTIFICADOR    varchar(50),
			   CONCEPTO         varchar(100),
			   SIT_CONCILIA     varchar(2),
               CVE_F_MONEDA     varchar(1),
			   IMP_CONCEPTO     numeric(16,2),
			   CVE_R_MONEDA     varchar(1),
			   TIPO_CAMBIO      NUMERIC(8,4),
			   IMP_CONC_PESOS   numeric(16,2)
  )
-- replicate (' ',(10 - len(i.ID_CXC))) + convert(varchar, i.ID_CXC) 

  IF  (SELECT  COUNT(*)
       FROM CI_NEG_CXC_ITEM n, CI_FACTURA f, CI_ITEM_C_X_C i, CI_CONCILIA_C_X_C cc
       WHERE
	   n.CVE_EMPRESA         =  i.CVE_EMPRESA      AND
	   n.SERIE               =  i.SERIE            AND
	   n.ID_CXC              =  i.ID_CXC           AND
	   n.ID_ITEM             =  i.ID_ITEM          AND
	   i.CVE_EMPRESA         =  f.CVE_EMPRESA      AND
	   i.SERIE               =  f.SERIE            AND
	   i.ID_CXC              =  f.ID_CXC           AND
	   n.ID_NEGOCIO          =  @pNegocio          AND
       f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC) = 0 OR
	   (SELECT COUNT(*) 
	   FROM CI_NEG_CXP_ITEM n, CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P i, CI_CONCILIA_C_X_P cc
	   WHERE
	   n.CVE_EMPRESA         =  i.CVE_EMPRESA       AND
	   n.ID_CXP              =  i.ID_CXP            AND
	   n.ID_CXP_DET          =  i.ID_CXP_DET        AND
	   i.CVE_EMPRESA         =  cp.CVE_EMPRESA      AND
	   i.ID_CXP              =  cp.ID_CXP           AND
	   n.ID_NEGOCIO          =  @pNegocio           AND
       cp.ID_CONCILIA_CXP    =  cc.ID_CONCILIA_CXP)  =  0
  BEGIN
    SELECT ' * Existen CXC o CXP sin Pagos *'
  END


  INSERT INTO #PLNEGOCIO (CLAVE,F_OPERACION,IDENTIFICADOR,CONCEPTO, SIT_CONCILIA, CVE_F_MONEDA,IMP_CONCEPTO,
                          CVE_R_MONEDA, TIPO_CAMBIO, IMP_CONC_PESOS)
  SELECT  @k_factura, convert(varchar(10), f.F_OPERACION, 120) ,
          i.CVE_EMPRESA + '-' +  i.SERIE + '-' + CONVERT(VARCHAR,i.ID_CXC) + '-' +  CONVERT(VARCHAR,i.ID_ITEM),
		  s.DESC_SUBPRODUCTO, f.SIT_CONCILIA_CXC, f.CVE_F_MONEDA,  
          i.IMP_BRUTO_ITEM, ch.CVE_MONEDA,
		  CASE
		  WHEN ch.CVE_MONEDA  =  @k_peso
		  THEN
		  0
		  ELSE
		  dbo.fnObtTipoCamb(m.F_OPERACION)
		  END,
		  CASE
		  WHEN ch.CVE_MONEDA =  @k_peso  AND m.CVE_CARGO_ABONO =  @k_abono
		  THEN 
		 (m.IMP_TRANSACCION / @k_fact_iva) * (i.IMP_BRUTO_ITEM / f.IMP_F_BRUTO)
		  WHEN ch.CVE_MONEDA =  @k_peso  AND m.CVE_CARGO_ABONO =  @k_cargo
		  THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva)  * -1) *  (i.IMP_BRUTO_ITEM / f.IMP_F_BRUTO)
		  WHEN ch.CVE_MONEDA =  @k_dolar  AND m.CVE_CARGO_ABONO =  @k_abono
          THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva) * dbo.fnObtTipoCamb(m.F_OPERACION)) * (i.IMP_BRUTO_ITEM / f.IMP_F_BRUTO)
          WHEN ch.CVE_MONEDA =  @k_dolar  AND m.CVE_CARGO_ABONO =  @k_cargo
		  THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva) * -1) * dbo.fnObtTipoCamb(m.F_OPERACION) * (i.IMP_BRUTO_ITEM / f.IMP_F_BRUTO)
		  ELSE
		  0
		  END
          FROM CI_NEG_CXC_ITEM n, CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_CONCILIA_C_X_C cc, CI_CHEQUERA ch,
		       CI_MOVTO_BANCARIO m
          WHERE
	      n.CVE_EMPRESA         =  i.CVE_EMPRESA      AND
		  n.SERIE               =  i.SERIE            AND
		  n.ID_CXC              =  i.ID_CXC           AND
		  n.ID_ITEM             =  i.ID_ITEM          AND
		  i.CVE_EMPRESA         =  f.CVE_EMPRESA      AND
		  i.SERIE               =  f.SERIE            AND
		  i.ID_CXC              =  f.ID_CXC           AND
		  i.CVE_SUBPRODUCTO     =  s.CVE_SUBPRODUCTO  AND
		  n.ID_NEGOCIO          =  @pNegocio          AND
          f.ID_CONCILIA_CXC     =  cc.ID_CONCILIA_CXC AND
		  cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO  AND
		  m.CVE_CHEQUERA        =  ch.CVE_CHEQUERA

  SET @NumRegistros = @NumRegistros + @@ROWCOUNT
  
  INSERT INTO #PLNEGOCIO (CLAVE,F_OPERACION,IDENTIFICADOR,CONCEPTO, SIT_CONCILIA, CVE_F_MONEDA,IMP_CONCEPTO,
                          CVE_R_MONEDA, TIPO_CAMBIO, IMP_CONC_PESOS)
  SELECT @k_factura + 'T', ' ', ' ', ' ', ' ', ' ', 0, ' ', 0, SUM(IMP_CONC_PESOS)
  FROM  #PLNEGOCIO  WHERE CLAVE = @k_factura

  SET @NumRegistros = @NumRegistros + @@ROWCOUNT

  INSERT INTO #PLNEGOCIO (CLAVE,F_OPERACION,IDENTIFICADOR,CONCEPTO, SIT_CONCILIA, CVE_F_MONEDA,IMP_CONCEPTO,
                          CVE_R_MONEDA, TIPO_CAMBIO, IMP_CONC_PESOS)
  SELECT @k_cta_pagar, convert(varchar(10), cp.F_CAPTURA),
          i.CVE_EMPRESA  + '-' +  CONVERT(VARCHAR,i.ID_CXP) + '-' +  CONVERT(VARCHAR,i.ID_CXP_DET),
		  o.DESC_OPERACION, cp.SIT_CONCILIA_CXP, cp.CVE_MONEDA,  
          i.IMP_BRUTO, ch.CVE_MONEDA,
		  CASE
		  WHEN ch.CVE_MONEDA  =  @k_peso
		  THEN
		  0
		  ELSE
		  dbo.fnObtTipoCamb(m.F_OPERACION)
		  END,
		  CASE
		  WHEN ch.CVE_MONEDA =  @k_peso  AND m.CVE_CARGO_ABONO =  @k_abono
		  THEN 
		  (m.IMP_TRANSACCION / @k_fact_iva) * (i.IMP_BRUTO / cp.IMP_BRUTO)
		  WHEN ch.CVE_MONEDA =  @k_peso  AND m.CVE_CARGO_ABONO =  @k_cargo
		  THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva)  * -1) *  (i.IMP_BRUTO / cp.IMP_BRUTO)
		  WHEN ch.CVE_MONEDA =  @k_dolar  AND m.CVE_CARGO_ABONO =  @k_abono
          THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva) * dbo.fnObtTipoCamb(m.F_OPERACION))* (i.IMP_BRUTO / cp.IMP_BRUTO)
          WHEN ch.CVE_MONEDA =  @k_dolar  AND m.CVE_CARGO_ABONO =  @k_cargo
		  THEN
		  ((m.IMP_TRANSACCION / @k_fact_iva) * -1) * dbo.fnObtTipoCamb(m.F_OPERACION) * (i.IMP_BRUTO / cp.IMP_BRUTO)
		  ELSE
		  0
		  END
          FROM CI_NEG_CXP_ITEM n, CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P i, CI_OPERACION_CXP o, CI_CONCILIA_C_X_P cc, CI_CHEQUERA ch,
		       CI_MOVTO_BANCARIO m
	      WHERE
	      n.CVE_EMPRESA         =  i.CVE_EMPRESA       AND
		  n.ID_CXP              =  i.ID_CXP            AND
		  n.ID_CXP_DET          =  i.ID_CXP_DET        AND
		  i.CVE_EMPRESA         =  cp.CVE_EMPRESA      AND
		  i.ID_CXP              =  cp.ID_CXP           AND
		  i.CVE_OPERACION       =  o.CVE_OPERACION     AND
		  n.ID_NEGOCIO          =  @pNegocio           AND
          cp.ID_CONCILIA_CXP    =  cc.ID_CONCILIA_CXP  AND
		  cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO AND
		  m.CVE_CHEQUERA        =  ch.CVE_CHEQUERA     

  INSERT INTO #PLNEGOCIO (CLAVE,F_OPERACION,IDENTIFICADOR,CONCEPTO, SIT_CONCILIA, CVE_F_MONEDA,IMP_CONCEPTO,
                          CVE_R_MONEDA, TIPO_CAMBIO, IMP_CONC_PESOS)
  SELECT @k_cta_pagar + 'T', ' ', ' ', ' ', ' ', ' ', 0, ' ', 0, SUM(IMP_CONC_PESOS)
  FROM  #PLNEGOCIO  WHERE CLAVE = @k_cta_pagar
  
  SET @NumRegistros = @NumRegistros + @@ROWCOUNT


  -- Insert the resultset we want to loop through
  -- into the temporary table

  
  -- Get the number of records in the temporary table
 
   SET @RowCount     = 1

  -- loop through all records in the temporary table
  -- using the WHILE loop construct
    WHILE @RowCount <= @NumRegistros
    BEGIN
      SET @RowCount = @RowCount + 1
    END                                                                                             
  SELECT * FROM  #PLNEGOCIO                                                                                                  
END
