--EXECUTE spCCIngIdentif 2017,07
ALTER PROCEDURE [dbo].[spCCIngIdentif]   @pAno int,
                                         @pMes int

AS
BEGIN

--CREATE TYPE CCINGIDENTIF AS TABLE
--(CVE_MONEDA_FACT   VARCHAR(1),
-- CVE_MONEDA_LIQ    VARCHAR(1),
-- CVE_REG           VARCHAR(2),
-- CTA_CONT_ING      VARCHAR(30),
-- CTA_CONT_COMP_B   VARCHAR(30),
-- CTA_CONT_CTE      VARCHAR(30),
-- CTA_CONT_COMP_C   VARCHAR(30),
-- CTA_CONT_IVA_NC   VARCHAR(30),
-- CTA_CONT_IVA_CO   VARCHAR(30),
-- CTA_CONT_PERD_C   VARCHAR(30),
-- CTA_CONT_GAN_C    VARCHAR(30),
-- F_OPERACION       DATE,
-- CVE_EMPRESA       VARCHAR(4),
-- SERIE             VARCHAR(4),
-- ID_CXC            INT,
-- ID_CLIENTE        NUMERIC(10),
-- NOM_CLIENTE       VARCHAR(120),
-- IMP_BRUTO_FACT    NUMERIC(12,2),
-- IMP_IVA_FACT      NUMERIC(12,2),
-- IMP_NETO_FACT     NUMERIC(12,2),
-- TIPO_CAMBIO_FACT  NUMERIC(8,4),
-- IMP_BRUTO_F_MN    NUMERIC(12,2),
-- IMP_IVA_F_MN      NUMERIC(12,2),
-- IMP_NETO_F_MN     NUMERIC(12,2),
-- IMP_COMP_FACT_MN  NUMERIC(12,2),
-- IMP_BRUTO_BAN     NUMERIC(12,2),
-- IMP_IVA_BAN       NUMERIC(12,2),
-- IMP_NETO_BAN      NUMERIC(12,2),
-- TIPO_CAMBIO_BAN   NUMERIC(8,4),
-- IMP_BRUTO_B_MN    NUMERIC(12,2),
-- IMP_IVA_B_MN      NUMERIC(12,2),
-- IMP_NETO_B_MN     NUMERIC(12,2),
-- IMP_COMP_B_MN     NUMERIC(12,2),
-- IMP_PERDIDA       NUMERIC(12,2),
-- IMP_GANANCIA      NUMERIC(12,2),
-- IMP_DIF_P_F       NUMERIC(12,2),
-- CVE_SORT          VARCHAR(10),
-- CVE_CHEQUERA      VARCHAR(6),
-- ANO               VARCHAR(4),
-- MES               VARCHAR(2),
-- DIA               VARCHAR(2),
-- FOLIOS            VARCHAR(45),
-- ID_MOVTO_BANCARIO INT)

declare @ccingidentif as CCINGIDENTIF

DECLARE
 @CVE_MONEDA_FACT   VARCHAR(1),
 @CVE_MONEDA_LIQ    VARCHAR(1),
 @CVE_REG           VARCHAR(2),
 @CTA_CONT_ING      VARCHAR(30),
 @CTA_CONT_COMP_B   VARCHAR(30),
 @CTA_CONT_CTE      VARCHAR(30),
 @CTA_CONT_COMP_C   VARCHAR(30),
 @CTA_CONT_IVA_NC   VARCHAR(30),
 @CTA_CONT_IVA_CO   VARCHAR(30),
 @CTA_CONT_PERD_C   VARCHAR(30),
 @CTA_CONT_GAN_C    VARCHAR(30),
 @F_OPERACION       DATE,
 @CVE_EMPRESA       VARCHAR(4),
 @SERIE             VARCHAR(4),
 @ID_CXC            INT,
 @ID_CLIENTE        NUMERIC(10),
 @NOM_CLIENTE       VARCHAR(120),
 @IMP_BRUTO_FACT    NUMERIC(12,2),
 @IMP_IVA_FACT      NUMERIC(12,2),
 @IMP_NETO_FACT     NUMERIC(12,2),
 @TIPO_CAMBIO_FACT  NUMERIC(8,4),
 @IMP_BRUTO_F_MN    NUMERIC(12,2),
 @IMP_IVA_F_MN      NUMERIC(12,2),
 @IMP_NETO_F_MN     NUMERIC(12,2),
 @IMP_COMP_FACT_MN  NUMERIC(12,2),
 @IMP_BRUTO_BAN     NUMERIC(12,2),
 @IMP_IVA_BAN       NUMERIC(12,2),
 @IMP_NETO_BAN      NUMERIC(12,2),
 @TIPO_CAMBIO_BAN   NUMERIC(8,4),
 @IMP_BRUTO_B_MN    NUMERIC(12,2),
 @IMP_IVA_B_MN      NUMERIC(12,2),
 @IMP_NETO_B_MN     NUMERIC(12,2),
 @IMP_COMP_B_MN     NUMERIC(12,2),
 @IMP_PERDIDA       NUMERIC(12,2),
 @IMP_GANANCIA      NUMERIC(12,2),
 @IMP_DIF_P_F       NUMERIC(12,2),
 @CVE_SORT          VARCHAR(10),
 @CVE_CHEQUERA      VARCHAR(6),
 @ANO               VARCHAR(4),
 @MES               VARCHAR(2),
 @DIA               VARCHAR(2),
 @FOLIOS            VARCHAR(45),
 @ID_MOVTO_BANCARIO INT
 
DECLARE
 @k_dolar          varchar(1),
 @k_peso           varchar(1),
 @k_cta_x_cobrar   varchar(3),
 @k_activo         varchar(1),
 @k_factura        varchar(3),
 @k_pago           varchar(3),
 @k_cta_com_cte    varchar(10),
 @k_cta_con_iva    varchar(10),
 @k_cta_iva_tc     varchar(10),
 @k_cta_per_cam    varchar(10),  
 @k_cta_gan_cam    varchar(10)    

          
DECLARE   
 @factor_iva       numeric(4,2),
 @ano_mes          varchar(6)

EXECUTE spCCProrrateaPago  @pAno,@pMes

set       @k_dolar        =  'D'
set       @k_peso         =  'P'
set       @factor_iva     =  .16
set       @k_cta_x_cobrar =  'CXC'
set       @k_activo       =  'A'
set       @k_factura      =  'FAC'
set       @k_pago         =  'PA'
set       @k_cta_com_cte  =  'CTACTECOMP'
set       @k_cta_con_iva  =  'CTAIVA'
set       @k_cta_iva_tc   =  'CTAIVACOBR'
set       @k_cta_per_cam  =  'CTAPERCAM'  
set       @k_cta_gan_cam   = 'CTAGANCAM'    

SET @ano_mes = convert(varchar(4),@pano) +  replicate ('0',(02 - len(@pmes))) + convert(varchar, @pmes)

declare pagos_banco cursor for 

select DISTINCT(m.ID_MOVTO_BANCARIO),
' ', -- 1
case -- 2
  WHEN ch.CVE_MONEDA = @k_peso 
  THEN @k_peso  
  ELSE @k_dolar 
  END, 
@k_pago,  -- 3
ch.CTA_CONTABLE,  -- 4
ch.CTA_CONT_COMP, -- 5
' ', -- 6
' ', -- 7
' ', -- 8
dbo.fnObtParAlfa(@k_cta_iva_tc),  -- 9
' ', -- 10 
' ', -- 11
m.F_OPERACION, -- 12
' ', -- 13
' ', -- 14
0,   -- 15
0,   -- 16 Cliente
' ', -- 17 Nombre Cliente
0,  -- 18
0,  -- 19
0,  -- 20
0,  -- 21
0,  -- 22
0,  -- 23
0,  -- 24
0,  -- 25
----------------------------- Datos de la liquidación Dolares ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  ELSE 0
end, -- 26
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  ELSE 0
end,  -- 27
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN  m.IMP_TRANSACCION  
  ELSE 0
end, -- 28
dbo.fnObtTipoCamb(m.F_operacion), -- 29
----------------------------- Datos de la liquidación Pesos ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)    
  ELSE 0
end,  -- 30
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) -
       round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2),2)
  ELSE 0
end,  -- 31
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN  m.IMP_TRANSACCION  
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)
  ELSE 0
end,  -- 32
----------------------------- Cálculo complementaria ----------------------------
case 
  WHEN ch.CVE_MONEDA  =  @k_dolar 
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) - m.IMP_TRANSACCION
  ELSE 0   
end,  -- 33
0, -- 34
0, -- 35
0, -- 36
' ', -- 37
ch.CVE_CHEQUERA, -- 38
YEAR(m.F_OPERACION), --39
MONTH(m.F_OPERACION), -- 40
DAY(m.F_OPERACION), -- 41
dbo.fnArmaFolPoliza(m.ID_MOVTO_BANCARIO) -- 42
from  CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_CONCILIA_C_X_C cc
WHERE cc.ANOMES_PROCESO      =  @ano_mes                AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
      m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         AND
      m.CVE_TIPO_MOVTO       =  @k_cta_x_cobrar           AND    
      m.SIT_MOVTO            =  @k_activo                        
--
 
open  pagos_banco

FETCH pagos_banco INTO 
 @ID_MOVTO_BANCARIO, 
 @CVE_MONEDA_FACT, -- 1
 @CVE_MONEDA_LIQ,  -- 2
 @CVE_REG,         -- 3
 @CTA_CONT_ING,    -- 4
 @CTA_CONT_COMP_B, -- 5
 @CTA_CONT_CTE,    -- 6 
 @CTA_CONT_COMP_C, -- 7
 @CTA_CONT_IVA_NC, -- 8
 @CTA_CONT_IVA_CO, -- 9
 @CTA_CONT_PERD_C, -- 10
 @CTA_CONT_GAN_C,  -- 11
 @F_OPERACION,     -- 12
 @CVE_EMPRESA,     -- 13
 @SERIE,           -- 14
 @ID_CXC,          -- 15
 @ID_CLIENTE,      -- 16
 @NOM_CLIENTE,     -- 17
 @IMP_BRUTO_FACT,  -- 18
 @IMP_IVA_FACT,    -- 19
 @IMP_NETO_FACT,   -- 20
 @TIPO_CAMBIO_FACT,-- 21
 @IMP_BRUTO_F_MN,  -- 22
 @IMP_IVA_F_MN,    -- 23 
 @IMP_NETO_F_MN,   -- 24
 @IMP_COMP_FACT_MN, -- 25
 @IMP_BRUTO_BAN,   -- 26
 @IMP_IVA_BAN,  -- 27
 @IMP_NETO_BAN,  -- 28
 @TIPO_CAMBIO_BAN, -- 29
 @IMP_BRUTO_B_MN,  -- 30
 @IMP_IVA_B_MN,    -- 31
 @IMP_NETO_B_MN,   -- 32
 @IMP_COMP_B_MN,   -- 33
 @IMP_PERDIDA,     -- 34
 @IMP_GANANCIA,    -- 35
 @IMP_DIF_P_F,     -- 36
 @CVE_SORT,        -- 37          
 @CVE_CHEQUERA,    -- 38
 @ANO,             -- 39
 @MES,             -- 40
 @DIA,             -- 41
 @FOLIOS           -- 42
     
WHILE (@@fetch_status = 0 )
BEGIN

select  @ID_CLIENTE = c.ID_CLIENTE, @NOM_CLIENTE = c.NOM_CLIENTE   
from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
WHERE cc.ID_MOVTO_BANCARIO   =  @ID_MOVTO_BANCARIO      AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
      f.ID_VENTA             =  v.ID_VENTA              AND
      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
      f.SIT_TRANSACCION      =  @k_activo     

 INSERT INTO @ccingidentif 
(CVE_MONEDA_FACT,
 CVE_MONEDA_LIQ,
 CVE_REG,
 CTA_CONT_ING,
 CTA_CONT_COMP_B,
 CTA_CONT_CTE,
 CTA_CONT_COMP_C,
 CTA_CONT_IVA_NC,
 CTA_CONT_IVA_CO,
 CTA_CONT_PERD_C,
 CTA_CONT_GAN_C,
 F_OPERACION,
 CVE_EMPRESA,
 SERIE,
 ID_CXC,
 ID_CLIENTE,
 NOM_CLIENTE,
 IMP_BRUTO_FACT,
 IMP_IVA_FACT,
 IMP_NETO_FACT,
 TIPO_CAMBIO_FACT,
 IMP_BRUTO_F_MN,
 IMP_IVA_F_MN,
 IMP_NETO_F_MN,
 IMP_COMP_FACT_MN,
 IMP_BRUTO_BAN,
 IMP_IVA_BAN,
 IMP_NETO_BAN,
 TIPO_CAMBIO_BAN,
 IMP_BRUTO_B_MN,
 IMP_IVA_B_MN,
 IMP_NETO_B_MN,
 IMP_COMP_B_MN,
 IMP_PERDIDA,
 IMP_GANANCIA,
 IMP_DIF_P_F,
 CVE_SORT,
 CVE_CHEQUERA,
 ANO,
 MES,
 DIA,
 FOLIOS,
 ID_MOVTO_BANCARIO) VALUES
(@CVE_MONEDA_FACT,
 @CVE_MONEDA_LIQ,
 @CVE_REG,
 @CTA_CONT_ING,
 @CTA_CONT_COMP_B,
 @CTA_CONT_CTE,
 @CTA_CONT_COMP_C,
 @CTA_CONT_IVA_NC,
 @CTA_CONT_IVA_CO,
 @CTA_CONT_PERD_C,
 @CTA_CONT_GAN_C,
 @F_OPERACION,
 @CVE_EMPRESA,
 @SERIE,
 @ID_CXC,
 @ID_CLIENTE,
 @NOM_CLIENTE,
 @IMP_BRUTO_FACT,
 @IMP_IVA_FACT,
 @IMP_NETO_FACT,
 @TIPO_CAMBIO_FACT,
 @IMP_BRUTO_F_MN,
 @IMP_IVA_F_MN,
 @IMP_NETO_F_MN,
 @IMP_COMP_FACT_MN,
 @IMP_BRUTO_BAN,
 @IMP_IVA_BAN,
 @IMP_NETO_BAN,
 @TIPO_CAMBIO_BAN,
 @IMP_BRUTO_B_MN,
 @IMP_IVA_B_MN,
 @IMP_NETO_B_MN,
 @IMP_COMP_B_MN,
 @IMP_PERDIDA,
 @IMP_GANANCIA,
 @IMP_DIF_P_F,
 @CVE_SORT,
 @CVE_CHEQUERA,
 @ANO,
 @MES,
 @DIA,
 @FOLIOS,
 @ID_MOVTO_BANCARIO)

FETCH pagos_banco INTO 
 @ID_MOVTO_BANCARIO,
 @CVE_MONEDA_FACT, -- 1
 @CVE_MONEDA_LIQ,  -- 2
 @CVE_REG,         -- 3
 @CTA_CONT_ING,    -- 4
 @CTA_CONT_COMP_B, -- 5
 @CTA_CONT_CTE,    -- 6 
 @CTA_CONT_COMP_C, -- 7
 @CTA_CONT_IVA_NC, -- 8
 @CTA_CONT_IVA_CO, -- 9
 @CTA_CONT_PERD_C, -- 10
 @CTA_CONT_GAN_C,  -- 11
 @F_OPERACION,     -- 12
 @CVE_EMPRESA,     -- 13
 @SERIE,           -- 14
 @ID_CXC,          -- 15
 @ID_CLIENTE,      -- 16
 @NOM_CLIENTE,     -- 17
 @IMP_BRUTO_FACT,  -- 18
 @IMP_IVA_FACT,    -- 19
 @IMP_NETO_FACT,   -- 20
 @TIPO_CAMBIO_FACT,-- 21
 @IMP_BRUTO_F_MN,  -- 22
 @IMP_IVA_F_MN,    -- 23 
 @IMP_NETO_F_MN,   -- 24
 @IMP_COMP_FACT_MN, -- 25
 @IMP_BRUTO_BAN,   -- 26
 @IMP_IVA_BAN,  -- 27
 @IMP_NETO_BAN,  -- 28
 @TIPO_CAMBIO_BAN, -- 29
 @IMP_BRUTO_B_MN,  -- 30
 @IMP_IVA_B_MN,    -- 31
 @IMP_NETO_B_MN,   -- 32
 @IMP_COMP_B_MN,   -- 33
 @IMP_PERDIDA,     -- 34
 @IMP_GANANCIA,    -- 35
 @IMP_DIF_P_F,     -- 36
 @CVE_SORT,        -- 37
 @CVE_CHEQUERA,    -- 38
 @ANO,             -- 39
 @MES,             -- 40
 @DIA,              -- 41
 @FOLIOS           -- 42
  
END

close pagos_banco 
deallocate pagos_banco

-- select * from  @ccingidentif    
     
-- ******************************************************************************************

declare pagos_banco cursor for 
select m.ID_MOVTO_BANCARIO,
f.CVE_F_MONEDA,  -- 1
f.CVE_R_MONEDA,  -- 2
@k_factura, -- 3
' ', -- 4,
' ', -- 5
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN c.CTA_CONT_USD  
  ELSE c.CTA_CONTABLE
end as 'Cta. Cont. Ing',  -- 18

dbo.fnObtParAlfa(@k_cta_com_cte) as 'Cta.Cont. Comp.', -- 7 
dbo.fnObtParAlfa(@k_cta_con_iva) as 'Cta.Cont. IVA',  -- 8
dbo.fnObtParAlfa(@k_cta_iva_tc) as 'Cta.C. Tras. IVA', -- 9

---------------------------- Cuenta complementaria Perdida -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  ELSE ' '
end,  -- 10

---------------------------- Cuenta complementaria Ganancia -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2)
   - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  ELSE ' '
end,  -- 11

-----------------------------------------------------------------------------------------

f.F_OPERACION,  -- 12	
f.CVE_EMPRESA,  -- 13
f.SERIE,        -- 14
f.ID_CXC,       -- 15
c.ID_CLIENTE,   -- 16
c.NOM_CLIENTE,  -- 17

---------------------------- Datos de la Factura Dolares Factura -------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO  
  ELSE 0
end,  -- 18
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA 
  ELSE 0
end,  -- 19
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO  
  ELSE 0
end,  -- 20

--------------------------  Tipos de Cambio ---------------------------------------------------

f.TIPO_CAMBIO,  -- 21
-- dbo.fnObtTipoCamb(f.F_operacion),  -- 22

---------------------------  Datos de la Factura Pesos --------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_BRUTO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
end,  -- 22
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_IVA 
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_IVA * f.TIPO_CAMBIO,2)
  ELSE 0
end,  -- 23
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_NETO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2)
  ELSE 0
end,  -- 24  

case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN 0  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2) - f.IMP_F_NETO
  ELSE 0
end,  -- 25  

----------------------------- Datos de la liquidación Dolares ----------------------------

case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)    
  ELSE 0
end,  -- 26
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(cc.IMP_PAGO_AJUST - (cc.IMP_PAGO_AJUST / (1 + @factor_iva)),2)
  ELSE 0
end,  -- 27
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN  cc.IMP_PAGO_AJUST  
  ELSE 0
end,  -- 28

dbo.fnObtTipoCamb(m.F_OPERACION),  -- 29

----------------------------- Datos de la liquidación Pesos ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)    
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2)    
  ELSE 0
end,  -- 30
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(cc.IMP_PAGO_AJUST - (cc.IMP_PAGO_AJUST / (1 + @factor_iva)),2)
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar) -
       round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2),2)
  ELSE 0
end,  -- 31
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN  cc.IMP_PAGO_AJUST  
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)
  ELSE 0
end,  -- 32

----------------------------- Cálculo complementaria ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_dolar 
  THEN dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar) - cc.IMP_PAGO_AJUST
  ELSE 0   
end,  -- 33

----------------------------  Calculo de Pérdida --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar) / (1 + @factor_iva),2)
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar)))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN abs(round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN  abs(round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2))  
  ELSE 0
end,  -- 34

----------------------------  Calculo de utilidad --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, cc.IMP_PAGO_AJUST, @k_dolar)/ (1 + @factor_iva),2))
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN abs(round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
   round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN  round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
  ELSE 0
end,  -- 35
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(cc.IMP_PAGO_AJUST / (1 + @factor_iva),2) - f.IMP_F_BRUTO    
  ELSE 0
end,  -- 36
' ', -- 37
ch.CVE_CHEQUERA, -- 38
YEAR(m.F_OPERACION), -- 39
MONTH(m.F_OPERACION), -- 40
DAY(m.F_OPERACION), -- 41
' ' -- 42
from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
WHERE f.ID_VENTA             =  v.ID_VENTA              AND
      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
      cc.ANOMES_PROCESO      =  @ano_mes                AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
      m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         AND
      m.SIT_MOVTO            =  'A'                     AND
      m.CVE_TIPO_MOVTO       =  'CXC'                   AND    
      f.SIT_TRANSACCION      =  'A'                     
--
 
open  pagos_banco

FETCH pagos_banco INTO 
 @ID_MOVTO_BANCARIO, 
 @CVE_MONEDA_FACT, -- 1
 @CVE_MONEDA_LIQ,  -- 2
 @CVE_REG,         -- 3
 @CTA_CONT_ING,    -- 4
 @CTA_CONT_COMP_B, -- 5
 @CTA_CONT_CTE,    -- 6 
 @CTA_CONT_COMP_C, -- 7
 @CTA_CONT_IVA_NC, -- 8
 @CTA_CONT_IVA_CO, -- 9
 @CTA_CONT_PERD_C, -- 10
 @CTA_CONT_GAN_C,  -- 11
 @F_OPERACION,     -- 12
 @CVE_EMPRESA,     -- 13
 @SERIE,           -- 14
 @ID_CXC,          -- 15
 @ID_CLIENTE,      -- 16
 @NOM_CLIENTE,     -- 17
 @IMP_BRUTO_FACT,  -- 18
 @IMP_IVA_FACT,    -- 19
 @IMP_NETO_FACT,   -- 20
 @TIPO_CAMBIO_FACT,-- 21
 @IMP_BRUTO_F_MN,  -- 22
 @IMP_IVA_F_MN,    -- 23 
 @IMP_NETO_F_MN,   -- 24
 @IMP_COMP_FACT_MN, -- 25
 @IMP_BRUTO_BAN,   -- 26
 @IMP_IVA_BAN,  -- 27
 @IMP_NETO_BAN,  -- 28
 @TIPO_CAMBIO_BAN, -- 29
 @IMP_BRUTO_B_MN,  -- 30
 @IMP_IVA_B_MN,    -- 31
 @IMP_NETO_B_MN,   -- 32
 @IMP_COMP_B_MN,   -- 33
 @IMP_PERDIDA,     -- 34
 @IMP_GANANCIA,    -- 35
 @IMP_DIF_P_F,     -- 36
 @CVE_SORT,         -- 37
 @CVE_CHEQUERA,     -- 38
 @ANO,              -- 39
 @MES,              -- 40
 @DIA,              -- 41
 @FOLIOS            -- 42
  
WHILE (@@fetch_status = 0 )
BEGIN

 INSERT INTO @ccingidentif 
(CVE_MONEDA_FACT,
 CVE_MONEDA_LIQ,
 CVE_REG,
 CTA_CONT_ING,
 CTA_CONT_COMP_B,
 CTA_CONT_CTE,
 CTA_CONT_COMP_C,
 CTA_CONT_IVA_NC,
 CTA_CONT_IVA_CO,
 CTA_CONT_PERD_C,
 CTA_CONT_GAN_C,
 F_OPERACION,
 CVE_EMPRESA,
 SERIE,
 ID_CXC,
 ID_CLIENTE,
 NOM_CLIENTE,
 IMP_BRUTO_FACT,
 IMP_IVA_FACT,
 IMP_NETO_FACT,
 TIPO_CAMBIO_FACT,
 IMP_BRUTO_F_MN,
 IMP_IVA_F_MN,
 IMP_NETO_F_MN,
 IMP_COMP_FACT_MN,
 IMP_BRUTO_BAN,
 IMP_IVA_BAN,
 IMP_NETO_BAN,
 TIPO_CAMBIO_BAN,
 IMP_BRUTO_B_MN,
 IMP_IVA_B_MN,
 IMP_NETO_B_MN,
 IMP_COMP_B_MN,
 IMP_PERDIDA,
 IMP_GANANCIA,
 IMP_DIF_P_F,
 CVE_SORT,
 CVE_CHEQUERA,
 ANO,
 MES,
 DIA,
 FOLIOS,
 ID_MOVTO_BANCARIO) VALUES
(@CVE_MONEDA_FACT,
 @CVE_MONEDA_LIQ,
 @CVE_REG,
 @CTA_CONT_ING,
 @CTA_CONT_COMP_B,
 @CTA_CONT_CTE,
 @CTA_CONT_COMP_C,
 @CTA_CONT_IVA_NC,
 @CTA_CONT_IVA_CO,
 @CTA_CONT_PERD_C,
 @CTA_CONT_GAN_C,
 @F_OPERACION,
 @CVE_EMPRESA,
 @SERIE,
 @ID_CXC,
 @ID_CLIENTE,
 @NOM_CLIENTE,
 @IMP_BRUTO_FACT,
 @IMP_IVA_FACT,
 @IMP_NETO_FACT,
 @TIPO_CAMBIO_FACT,
 @IMP_BRUTO_F_MN,
 @IMP_IVA_F_MN,
 @IMP_NETO_F_MN,
 @IMP_COMP_FACT_MN,
 @IMP_BRUTO_BAN,
 @IMP_IVA_BAN,
 @IMP_NETO_BAN,
 @TIPO_CAMBIO_BAN,
 @IMP_BRUTO_B_MN,
 @IMP_IVA_B_MN,
 @IMP_NETO_B_MN,
 @IMP_COMP_B_MN,
 @IMP_PERDIDA,
 @IMP_GANANCIA,
 @IMP_DIF_P_F,
 @CVE_SORT,
 @CVE_CHEQUERA,
 @ANO,
 @MES,
 @DIA,
 @FOLIOS,
 @ID_MOVTO_BANCARIO)

FETCH pagos_banco INTO 
 @ID_MOVTO_BANCARIO,
 @CVE_MONEDA_FACT, -- 1
 @CVE_MONEDA_LIQ,  -- 2
 @CVE_REG,         -- 3
 @CTA_CONT_ING,    -- 4
 @CTA_CONT_COMP_B, -- 5
 @CTA_CONT_CTE,    -- 6 
 @CTA_CONT_COMP_C, -- 7
 @CTA_CONT_IVA_NC, -- 8
 @CTA_CONT_IVA_CO, -- 9
 @CTA_CONT_PERD_C, -- 10
 @CTA_CONT_GAN_C,  -- 11
 @F_OPERACION,     -- 12
 @CVE_EMPRESA,     -- 13
 @SERIE,           -- 14
 @ID_CXC,          -- 15
 @ID_CLIENTE,      -- 16
 @NOM_CLIENTE,     -- 17
 @IMP_BRUTO_FACT,  -- 18
 @IMP_IVA_FACT,    -- 19
 @IMP_NETO_FACT,   -- 20
 @TIPO_CAMBIO_FACT,-- 21
 @IMP_BRUTO_F_MN,  -- 22
 @IMP_IVA_F_MN,    -- 23 
 @IMP_NETO_F_MN,   -- 24
 @IMP_COMP_FACT_MN, -- 25
 @IMP_BRUTO_BAN,   -- 26
 @IMP_IVA_BAN,  -- 27
 @IMP_NETO_BAN,  -- 28
 @TIPO_CAMBIO_BAN, -- 29
 @IMP_BRUTO_B_MN,  -- 30
 @IMP_IVA_B_MN,    -- 31
 @IMP_NETO_B_MN,   -- 32
 @IMP_COMP_B_MN,   -- 33
 @IMP_PERDIDA,     -- 34
 @IMP_GANANCIA,    -- 35
 @IMP_DIF_P_F,     -- 36
 @CVE_SORT,         -- 37
 @CVE_CHEQUERA,    -- 38
 @ANO,             -- 39   
 @MES,             -- 40
 @DIA,             -- 41
 @FOLIOS           -- 42


END

close pagos_banco 
deallocate pagos_banco

--select ID_MOVTO_BANCARIO from  @ccingidentif  WHERE CVE_REG = @k_factura 
--GROUP BY ID_MOVTO_BANCARIO 
--HAVING COUNT(*) > 1

select * from  @ccingidentif ORDER BY ID_MOVTO_BANCARIO, CVE_REG DESC

END