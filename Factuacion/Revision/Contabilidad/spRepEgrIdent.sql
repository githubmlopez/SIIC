USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spRepEgrIdent]    Script Date: 01/10/2016 12:08:04 ******/
--exec spRepIngIdent 2017,01,'AN'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spRepEgrIdent] @pano int, @pmes int, @pcve_tipo_inf varchar(2)
AS
BEGIN

Declare   @k_dolar      varchar(1),
          @k_peso       varchar(1),
          @k_mes_act    varchar(2),
          @k_mes_ant    varchar(2),
          @k_activa     varchar(1)
          
Declare   @factor_iva   numeric(3,2),
          @ano_mes      varchar(6)

set       @k_dolar     =  'D'
set       @k_peso      =  'P'	
set       @k_mes_act   =  'AC'
set       @k_mes_ant   =  'AN'
set       @k_activa    =  'A'
set       @factor_iva  =  .16

SET @ano_mes = convert(varchar(4),@pano) +  replicate ('0',(02 - len(@pmes))) + convert(varchar, @pmes)

select 
ch.CVE_CHEQUERA as 'Cuenta Bancaria', m .ID_MOVTO_BANCARIO as 'id. Movto', m.F_OPERACION as 'F. Movto.',
ch.CTA_CONTABLE as 'Cuenta Contable', 
p.ID_PROVEEDOR  as 'Id. Proveedor',
p.NOM_PROVEEDOR as 'Nombre Proveedor',
o.CTA_CONTABLE  as 'Cta. Cont. Gasto',
o.DESC_OPERACION as 'Nombre Gasto',
cxp.F_PAGO       as 'F. Pago',
cxp.TX_NOTA      as 'Comentario',





from CI_CUENTA_X_PAGAR cxp, CI_PROVEEDOR p, CI_OPERACION_CXP o,CI_CONCILIA_C_X_P cp, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
WHERE cxp.ID_CONCILIA_CXP    =  cp.ID_CONCILIA_CXP      AND
      cxp.ID_PROVEEDOR       =  p.ID_PROVEEDOR          AND
      cxp.CVE_OPERACION      =  o.CVE_OPERACION         AND
    ((@pcve_tipo_inf         =  @k_mes_act              AND
      m.ANO_MES              =  @ano_mes)               or
     (@pcve_tipo_inf         =  @k_mes_ant              AND
      m.ANO_MES              <  @ano_mes))              AND
      m.ID_MOVTO_BANCARIO    =  cp.ID_MOVTO_BANCARIO    AND
      m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         AND
      m.SIT_MOVTO            =  @k_activa               AND    
      cxp.SIT_C_X_P          =  @k_activa                     
END





--select ch.CVE_CHEQUERA as 'Cuenta Bancaria', m .ID_MOVTO_BANCARIO as 'id. Movto', m.F_OPERACION as 'F. Movto.',
-- ch.CTA_CONTABLE as 'Cuenta Contable', 
--case
--  WHEN f.CVE_R_MONEDA  =  @k_dolar
--  THEN ch.CTA_CONT_COMP
--  ELSE ' '
--  END as 'Cta. Comp. Bco', 
--case
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN c.CTA_CONT_COMP
--  ELSE ' '
--  END as 'Cta. Comp. Cte.',
--f.F_OPERACION   as 'F. Operacion',	
--f.CVE_EMPRESA   as 'Empresa',
--f.SERIE         as 'Serie',
--f.ID_CXC        as 'Id. CXC',
--c.ID_CLIENTE    as 'Id Cliente',
--c.NOM_CLIENTE   as 'Nombre Ciente',
--f.CVE_F_MONEDA  as 'Cve. Moneda',
--f.TIPO_CAMBIO   as 'Tipo Cambio',
------------------------------ Datos de la Factura Dolares -------------------------------
--case
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN f.IMP_F_BRUTO  
--  ELSE 0
--end  as 'Imp. Bruto',
--case
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN f.IMP_F_IVA 
--  ELSE 0
--end  as  'IVA',
--case
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN f.IMP_F_NETO  
--  ELSE 0
--end as 'Imp. Neto',
-----------------------------  Datos de la Factura Pesos  --------------------------------
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso
--  THEN f.IMP_F_BRUTO  
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, f.CVE_F_MONEDA) 
--end  as 'Imp. Bruto',
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso
--  THEN f.IMP_F_IVA 
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_IVA, f.CVE_F_MONEDA) 
--  ELSE 0
--end  as  'IVA',
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso
--  THEN f.IMP_F_NETO  
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  THEN dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) 
--  ELSE 0
--end as 'Imp. Neto',
------------------------------- Datos de la liquidación Dolares ----------------------------
--f.TIPO_CAMBIO_LIQ as 'T.C. Liq',
--f.CVE_R_MONEDA as 'Mon. Liq.',
--case
--  WHEN f.CVE_R_MONEDA  =  @k_dolar
----  THEN f.IMP_R_NETO / (1 + @factor_iva)   
--  THEN f.IMP_R_NETO    
--  ELSE 0
--end  as 'Imp. Bruto',
--case
--  WHEN f.CVE_R_MONEDA  =  @k_dolar
----  THEN (f.IMP_R_NETO / (1 + @factor_iva)) * @factor_iva 
--  THEN round(f.IMP_R_NETO * @factor_iva,2) 
--  ELSE 0
--end  as  'IVA',
--case
--  WHEN f.CVE_R_MONEDA  =  @k_dolar
----  THEN f.IMP_R_NETO  
--  THEN round((f.IMP_R_NETO * (1 + @factor_iva)),2) 
--  ELSE 0
--end as 'Imp. Neto',
------------------------------- Datos de la liquidación Pesos --------------------------
--case
--  WHEN f.CVE_R_MONEDA  =  @k_peso
----  THEN f.IMP_R_NETO / (1 + @factor_iva)  
--  THEN f.IMP_R_NETO   
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
----  THEN (dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) / (1 + @factor_iva))
--  THEN dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA)
--end  as 'Imp. Bruto',
--case
--  WHEN f.CVE_R_MONEDA  =  @k_peso
----  THEN (f.IMP_R_NETO / (1 + @factor_iva)) * @factor_iva 
--  THEN round((f.IMP_R_NETO * @factor_iva),2) 
--  WHEN f.CVE_F_MONEDA  =  @k_dolar
--  --THEN dbo.fnCalculaPesos(f.F_OPERACION,  
--  --    (dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) / (1 + @factor_iva) * @factor_iva),
--  --     f.CVE_R_MONEDA)  
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) * @factor_iva),2)
--  ELSE 0
--end  as  'IVA',
--case
--  WHEN f.CVE_R_MONEDA  =  @k_peso
----  THEN f.IMP_R_NETO  
--  THEN round((f.IMP_R_NETO  * (1 + @factor_iva)),2)
--  WHEN f.CVE_R_MONEDA  =  @k_dolar
----  THEN dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) 
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) * (1 + @factor_iva)),2)
--  ELSE 0
--end as 'Imp. Neto',
-------------------------------  Calculo Complementaria  ---------------------------------
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA) -
--       f.IMP_R_NETO),2) 
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_peso
--  THEN round(((f.IMP_R_NETO * (1 + @factor_iva)) - f.IMP_F_NETO),2)
--  ELSE 0
--end as 'Imp.Comp. (P)',
------------------------------- Diferencial Cambiario ------------------------------------
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round(((dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_R_NETO, f.CVE_R_MONEDA)) -
--        f.IMP_F_BRUTO),2)
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_peso
--  THEN round((f.IMP_R_NETO) - 
--       (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, f.CVE_F_MONEDA)),2) 
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, f.IMP_F_BRUTO, f.CVE_F_MONEDA)) - 
--       (dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_R_NETO, f.CVE_F_MONEDA)),2) 
--  ELSE 0
--end as 'Bruto',
--case
--  WHEN f.CVE_F_MONEDA  =  @k_peso  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round ((dbo.fnCalculaPesos(m.F_OPERACION, (f.IMP_R_NETO * @factor_iva), f.CVE_R_MONEDA) -
--       f.IMP_F_NETO),2)
--  WHEN  f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_peso
--  THEN round(((f.IMP_R_NETO * @factor_iva) - 
--        dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_IVA, f.CVE_F_MONEDA)),2)
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, (f.IMP_F_BRUTO * @factor_iva), f.CVE_F_MONEDA)) - 
--       (dbo.fnCalculaPesos(f.F_OPERACION, (f.IMP_R_NETO * @factor_iva), f.CVE_F_MONEDA)),2) 
--  ELSE 0
--end as 'IVA',
--  case
--  WHEN f.CVE_F_MONEDA  =  @k_peso  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round ((dbo.fnCalculaPesos(m.F_OPERACION, (f.IMP_R_NETO * (1 + @factor_iva)), f.CVE_R_MONEDA) -   
--       f.IMP_F_NETO),2) 
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_peso
--  THEN round(((f.IMP_R_NETO * (1 + @factor_iva)) -
--       dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA)),2)     
--  WHEN f.CVE_F_MONEDA  =  @k_dolar  and  f.CVE_R_MONEDA  =  @k_dolar
--  THEN round((dbo.fnCalculaPesos(m.F_OPERACION, (f.IMP_F_BRUTO * (1 + @factor_iva)), f.CVE_F_MONEDA)) - 
--       (dbo.fnCalculaPesos(f.F_OPERACION, (f.IMP_R_NETO * (1 + @factor_iva)), f.CVE_F_MONEDA)),2) 
--  ELSE 0
--end as ' Neto '
--from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CHEQUERA ch
--WHERE f.ID_VENTA             =  v.ID_VENTA              AND
--      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
--      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
----      m.ANO_MES              =  @ano_mes                AND
--    ((@pcve_tipo_inf         =  @k_mes_act              AND
--      m.ANO_MES              =  @ano_mes)               or
--     (@pcve_tipo_inf         =  @k_mes_ant              AND
--      m.ANO_MES              <  @ano_mes))              AND
--      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
--      m.CVE_CHEQUERA         =  ch.CVE_CHEQUERA         AND
--      m.SIT_MOVTO            =  'A'                     AND    
--      f.SIT_TRANSACCION      =  'A'                     
--END








