USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spRepIngIdent]    Script Date: 01/10/2016 12:08:04 ******/
--exec spRepIngIdent 2017,05,'AC'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter PROCEDURE [dbo].[spRepIngIdent] @pano int, @pmes int, @pcve_tipo_inf varchar(2)
AS
BEGIN

Declare   @k_dolar       varchar(1),
          @k_peso        varchar(1),
          @k_mes_act     varchar(2),
          @k_mes_ant     varchar(2),	
          @k_cta_com_cte varchar(10),
          @k_cta_con_iva varchar(10),
          @k_cta_iva_tc  varchar(10),
          @k_cta_per_cam varchar(10),  
          @k_cta_gan_cam varchar(10)    

          
Declare   @factor_iva    numeric(4,2),
          @ano_mes       varchar(6)

set       @k_dolar        =  'D'
set       @k_peso         =  'P'
set       @k_mes_act      =  'AC'
set       @k_mes_ant      =  'AN'
set       @factor_iva     =  .16
set       @k_cta_com_cte  =  'CTACTECOMP'
set       @k_cta_con_iva  =  'CTAIVA'
set       @k_cta_iva_tc   =  'CTAIVACOBR'
set       @k_cta_per_cam  =  'CTAPERCAM'  
set       @k_cta_gan_cam   = 'CTAGANCAM'    


SET @ano_mes = convert(varchar(4),@pano) +  replicate ('0',(02 - len(@pmes))) + convert(varchar, @pmes)

select m.ID_MOVTO_BANCARIO,
f.CVE_F_MONEDA  as 'Cve. Mon. Fact', f.CVE_R_MONEDA  as 'Cve. Mon. Liq.', 'FAC' as 'Tipo',
case
  WHEN f.CVE_F_MONEDA = @k_peso 
  THEN c.CTA_CONTABLE 
  ELSE c.CTA_CONT_USD 
  END as 'Cta. Cont. COI',
case
  WHEN  f.CVE_F_MONEDA = @k_dolar 
  THEN  dbo.fnObtParAlfa(@k_cta_com_cte)
  ELSE  ' '
  END as 'Cta. Cont. Comp.',
ch.CTA_CONTABLE as 'Cta. Cont. Ing',
case
  WHEN  f.CVE_R_MONEDA = @k_peso 
  THEN  ' '
  ELSE  ch.CTA_CONT_COMP
  END as 'Cta. Cont. Comp.',
dbo.fnObtParAlfa(@k_cta_con_iva) as 'Cta.Cont. IVA',
dbo.fnObtParAlfa(@k_cta_iva_tc) as 'Cta.C. Tras. IVA',

---------------------------- Cuenta complementaria Perdida -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  ELSE ' '
end  as 'Cta Perdida Camb.',

---------------------------- Cuenta complementaria Ganancia -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
   - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  ELSE ' '
end  as 'Cta Ganancia Camb.',

-----------------------------------------------------------------------------------------

f.F_OPERACION   as 'F. Operacion',	
f.CVE_EMPRESA   as 'Empresa',
f.SERIE         as 'Serie',
f.ID_CXC        as 'Id. CXC',
c.ID_CLIENTE    as 'Id Cliente',
c.NOM_CLIENTE   as 'Nombre Ciente',

---------------------------- Datos de la Factura Dolares Factura -------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO  
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA 
  ELSE 0
end  as  'IVA',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO  
  ELSE 0
end as 'Imp. Neto',

--------------------------  Tipos de Cambio ---------------------------------------------------

f.TIPO_CAMBIO   as 'Tipo Cambio',
dbo.fnObtTipoCamb(f.F_operacion) as 'Tipo Cambio Día',

--dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) - f.IMP_F_NETO as 'Imp. Complemen.',

---------------------------  Datos de la Factura Pesos --------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_BRUTO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
end  as 'Imp. Bruto',
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_IVA 
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_IVA * f.TIPO_CAMBIO,2)
  ELSE 0
end  as  'IVA',
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_NETO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2)
  ELSE 0
end as 'Imp. Neto',  

case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN 0  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2) - f.IMP_F_NETO
  ELSE 0
end as 'Imp. Complemen.',  

----------------------------- Datos de la liquidación Dolares ----------------------------

case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  ELSE 0
end  as  'IVA',
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN  m.IMP_TRANSACCION  
  ELSE 0
end as 'Imp. Neto',

dbo.fnObtTipoCamb(m.F_OPERACION) as 'Tipo Cambio Liq.',


----------------------------- Datos de la liquidación Pesos ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)    
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) -
       round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2),2)
  ELSE 0
end  as  'IVA',
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN  m.IMP_TRANSACCION  
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)
  ELSE 0
end as 'Imp. Neto',

----------------------------- Cálculo complementaria ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_dolar 
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) - m.IMP_TRANSACCION
  ELSE 0   
end as 'Imp. Comp. Pesos',

----------------------------  Calculo de Pérdida --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) / (1 + @factor_iva),2)
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar)))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN  abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2))  
  ELSE 0
end  as 'Imp. Perdida',

----------------------------  Calculo de utilidad --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2))
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
   round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
  ELSE 0
end  as 'Imp. Utidad',
ch.CVE_CHEQUERA as 'Chequera',
YEAR(m.F_OPERACION) as 'Ano Movto',
MONTH(m.F_OPERACION) as 'Mes Movto',
DAY(m.F_OPERACION)   as 'Dia Movto', 'x'

from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
WHERE f.ID_VENTA             =  v.ID_VENTA              AND
      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
      cc.ANOMES_PROCESO      =  @ano_mes                AND
    --((@pcve_tipo_inf         =  @k_mes_act              AND
    --  m.ANO_MES              =  @ano_mes)               or
    --(@pcve_tipo_inf         =  @k_mes_ant              AND
    -- m.ANO_MES              <  @ano_mes))              AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
      m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         AND
      m.SIT_MOVTO            =  'A'                     AND    
      f.SIT_TRANSACCION      =  'A'                   
-- order by Chequera, m.F_OPERACION                   

UNION

select m.ID_MOVTO_BANCARIO,
' ',
case
  WHEN ch.CVE_MONEDA = @k_peso 
  THEN @k_peso  
  ELSE @k_dolar 
  END as 'Cve. Mon. Liq.',
'PAG' as 'Tipo',
case
  WHEN f.CVE_F_MONEDA = @k_peso 
  THEN c.CTA_CONTABLE 
  ELSE c.CTA_CONT_USD 
  END as 'Cta. Cont. COI',
case
  WHEN  f.CVE_F_MONEDA = @k_dolar 
  THEN  dbo.fnObtParAlfa(@k_cta_com_cte)
  ELSE  ' '
  END as 'Cta. Cont. Comp.',
ch.CTA_CONTABLE as 'Cta. Cont. Ing',
case
  WHEN  f.CVE_R_MONEDA = @k_peso 
  THEN  ' '
  ELSE  ch.CTA_CONT_COMP
  END as 'Cta. Cont. Comp.',
dbo.fnObtParAlfa(@k_cta_con_iva) as 'Cta.Cont. IVA',
dbo.fnObtParAlfa(@k_cta_iva_tc) as 'Cta.C. Tras. IVA',

---------------------------- Cuenta complementaria Perdida -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN dbo.fnObtParAlfa(@k_cta_per_cam)
  ELSE ' '
end  as 'Cta Perdida Camb.',

---------------------------- Cuenta complementaria Ganancia -------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
   - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and	
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam) 
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN dbo.fnObtParAlfa(@k_cta_gan_cam)
  ELSE ' '
end  as 'Cta Ganancia Camb.',

-----------------------------------------------------------------------------------------

f.F_OPERACION   as 'F. Operacion',	
f.CVE_EMPRESA   as 'Empresa',
f.SERIE         as 'Serie',
f.ID_CXC        as 'Id. CXC',
c.ID_CLIENTE    as 'Id Cliente',
c.NOM_CLIENTE   as 'Nombre Ciente',

---------------------------- Datos de la Factura Dolares Factura -------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO  
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA 
  ELSE 0
end  as  'IVA',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO  
  ELSE 0
end as 'Imp. Neto',

--------------------------  Tipos de Cambio ---------------------------------------------------

f.TIPO_CAMBIO   as 'Tipo Cambio',
dbo.fnObtTipoCamb(f.F_operacion) as 'Tipo Cambio Día',

--dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) - f.IMP_F_NETO as 'Imp. Complemen.',

---------------------------  Datos de la Factura Pesos --------------------------------
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_BRUTO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
end  as 'Imp. Bruto',
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_IVA 
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_IVA * f.TIPO_CAMBIO,2)
  ELSE 0
end  as  'IVA',
case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_NETO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2)
  ELSE 0
end as 'Imp. Neto',  

case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN 0  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(f.IMP_F_NETO * f.TIPO_CAMBIO,2) - f.IMP_F_NETO
  ELSE 0
end as 'Imp. Complemen.',  

----------------------------- Datos de la liquidación Dolares ----------------------------

case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  ELSE 0
end  as  'IVA',
case
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN  m.IMP_TRANSACCION  
  ELSE 0
end as 'Imp. Neto',

dbo.fnObtTipoCamb(m.F_OPERACION) as 'Tipo Cambio Liq.',


----------------------------- Datos de la liquidación Pesos ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION / (1 + @factor_iva),2)    
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)    
  ELSE 0
end  as 'Imp. Bruto',
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN round(m.IMP_TRANSACCION - (m.IMP_TRANSACCION / (1 + @factor_iva)),2)
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) -
       round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2),2)
  ELSE 0
end  as  'IVA',
case
  WHEN ch.CVE_MONEDA  =  @k_peso
  THEN  m.IMP_TRANSACCION  
  WHEN ch.CVE_MONEDA  =  @k_dolar
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)
  ELSE 0
end as 'Imp. Neto',

----------------------------- Cálculo complementaria ----------------------------
case
  WHEN ch.CVE_MONEDA  =  @k_dolar 
  THEN dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) - m.IMP_TRANSACCION
  ELSE 0   
end as 'Imp. Comp. Pesos',

----------------------------  Calculo de Pérdida --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar) / (1 + @factor_iva),2)
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar)))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO < 0
  THEN abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) < 0
  THEN  abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2))  
  ELSE 0
end  as 'Imp. Perdida',

----------------------------  Calculo de utilidad --------------------------------
case
  WHEN (ch.CVE_MONEDA  =  @k_dolar and f.CVE_F_MONEDA = @k_dolar) and
  round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN abs(round(dbo.fnCalculaPesos(m.F_OPERACION, m.IMP_TRANSACCION, @k_dolar)/ (1 + @factor_iva),2))
  - (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, @k_dolar))    
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_peso) and
  round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO > 0
  THEN abs(round(m.IMP_TRANSACCION / (1 + @factor_iva),2) -  f.IMP_F_BRUTO)   
  WHEN (ch.CVE_MONEDA  =  @k_peso and f.CVE_F_MONEDA = @k_dolar) and
   round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) > 0
  THEN  round(m.IMP_TRANSACCION / (1 + @factor_iva),2)
  - round(f.IMP_F_BRUTO * f.TIPO_CAMBIO,2) 
  ELSE 0
end  as 'Imp. Utidad',
ch.CVE_CHEQUERA as 'Chequera',
YEAR(m.F_OPERACION) as 'Ano Movto',
MONTH(m.F_OPERACION) as 'Mes Movto',
DAY(m.F_OPERACION)   as 'Dia Movto', 'y'

from CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
WHERE m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         
 --order by Chequera, m.F_OPERACION

END

