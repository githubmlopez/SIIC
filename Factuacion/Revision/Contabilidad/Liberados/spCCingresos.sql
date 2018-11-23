USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spFacturacion]    Script Date: 07/03/2017 12:08:04 ******/
--exec spCCingresos '201806'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spCCingresos] @pano_mes varchar(6)
AS
BEGIN

declare  @f_inicio_mes      date,
         @f_fin_mes         date,
         @tipo_cam_f_mes    numeric(8,4)

declare  @k_activa          varchar(2),
         @k_cancelada       varchar(2),
         @k_legada          varchar(6),
         @k_peso            varchar(1),
         @k_dolar           varchar(1),
         @k_falso           bit,
         @k_verdadero       bit

set      @k_activa         =  'A'
set      @k_cancelada      =  'C'
set      @k_dolar          =  'AB'
set      @k_legada         =  'LEGACY'
set      @k_dolar          =  'D'
set      @k_peso           =  'P'
set      @k_falso          =  0
set      @k_verdadero      =  1

  select @f_inicio_mes  =  F_INICIAL, @f_fin_mes  =  F_FINAL, @tipo_cam_f_mes =  TIPO_CAM_F_MES
  from CI_PERIODO_CONTA  where ANO_MES  =  @pano_mes
  
  select 
  f.CVE_F_MONEDA as 'Moneda',
  '' as 'Moneda Liq.',
  CASE
  WHEN
  (f.F_CANCELACION is null or f.F_CANCELACION > @f_fin_mes)               and
          f.F_OPERACION     >= @f_inicio_mes and  f.F_OPERACION    <= @f_fin_mes 
  THEN  'ACTIVA'
  WHEN
  (f.F_CANCELACION   >= @f_inicio_mes and  f.F_CANCELACION  <= @f_fin_mes  and
          CONVERT(varchar(4), YEAR(f.F_CANCELACION)) + replicate ('0',(02 - len(MONTH(f.F_CANCELACION)))) + 
          convert(varchar, MONTH(f.F_CANCELACION)) >    
          CONVERT(varchar(4), YEAR(f.F_OPERACION)) + replicate ('0',(02 - len(MONTH(f.F_OPERACION)))) + 
          convert(varchar, MONTH(f.F_OPERACION))) 
  THEN  'CANTE'
  WHEN
  (f.F_CANCELACION   >= @f_inicio_mes and  f.F_CANCELACION  <= @f_fin_mes  and
          CONVERT(varchar(4), YEAR(f.F_CANCELACION)) + replicate ('0',(02 - len(MONTH(f.F_CANCELACION)))) + 
          convert(varchar, MONTH(f.F_CANCELACION)) =    
          CONVERT(varchar(4), YEAR(f.F_OPERACION)) + replicate ('0',(02 - len(MONTH(f.F_OPERACION)))) + 
          convert(varchar, MONTH(f.F_OPERACION))) 
  THEN  'CMES'
  END  AS SIT_FACTURA,
  case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN ISNULL((SELECT CTA_CONTABLE FROM CI_CTA_CONT_CTE WHERE CVE_EMPRESA = 'CU' AND ID_CLIENTE = c.ID_CLIENTE AND CVE_TIPO_CTA = 'D'), '*')
  ELSE ISNULL((SELECT CTA_CONTABLE FROM CI_CTA_CONT_CTE WHERE CVE_EMPRESA = 'CU' AND ID_CLIENTE = c.ID_CLIENTE AND CVE_TIPO_CTA = 'P'), '*')
  END as 'Cta. Contab. Cte',
  case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN dbo.fnObtParAlfa('CTACTECOMP')
  ELSE ' '
  END as 'Cta. Complem. Cte', 
  dbo.fnObtParAlfa('CTAINGRESO') as 'Cuenta Ingreso',
  dbo.fnObtParAlfa('CTAIVA') 'Cuenta IVA',
  f.F_OPERACION as 'F. Operacion',
  CVE_EMPRESA as 'Empresa',
  SERIE as 'Serie',
  ID_CXC as 'Id. CXC',
  c.ID_CLIENTE as 'Id. Cliente',
  c.NOM_CLIENTE as 'Nombre Cliente',
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
  case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.TIPO_CAMBIO  
  ELSE 0
  end  as 'Tipo Cambio',
  case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_BRUTO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_BRUTO * f.TIPO_CAMBIO -- dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_BRUTO, f.CVE_F_MONEDA) 
  end  as 'Imp. Bruto',
  case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_IVA 
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_IVA * f.TIPO_CAMBIO -- dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_IVA, f.CVE_F_MONEDA) 
  ELSE 0
  end  as  'IVA',
  case
  WHEN f.CVE_F_MONEDA  =  @k_peso
  THEN f.IMP_F_NETO  
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN f.IMP_F_NETO * f.TIPO_CAMBIO -- dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) 
  ELSE 0
  end as 'Imp. Neto',

  case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  -- THEN dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) - f.IMP_F_NETO  
  THEN (f.IMP_F_NETO * f.TIPO_CAMBIO) - f.IMP_F_NETO  
  ELSE 0
  end as 'Imp. Complementario (Pesos)',
  f.F_CANCELACION,
  f.TX_NOTA

  FROM CI_FACTURA f, CI_VENTA v , CI_CLIENTE c
  where (( (f.F_CANCELACION is null or f.F_CANCELACION > @f_fin_mes)               and
          f.F_OPERACION     >= @f_inicio_mes and  f.F_OPERACION    <= @f_fin_mes)  or
          
         (f.F_CANCELACION   >= @f_inicio_mes and  f.F_CANCELACION  <= @f_fin_mes  and
          CONVERT(varchar(4), YEAR(f.F_CANCELACION)) + replicate ('0',(02 - len(MONTH(f.F_CANCELACION)))) + 
          convert(varchar, MONTH(f.F_CANCELACION)) >    
          CONVERT(varchar(4), YEAR(f.F_OPERACION)) + replicate ('0',(02 - len(MONTH(f.F_OPERACION)))) + 
          convert(varchar, MONTH(f.F_OPERACION)) or  

         (f.F_CANCELACION   >= @f_inicio_mes and  f.F_CANCELACION  <= @f_fin_mes  and
          CONVERT(varchar(4), YEAR(f.F_CANCELACION)) + replicate ('0',(02 - len(MONTH(f.F_CANCELACION)))) + 
          convert(varchar, MONTH(f.F_CANCELACION)) =    
          CONVERT(varchar(4), YEAR(f.F_OPERACION)) + replicate ('0',(02 - len(MONTH(f.F_OPERACION)))) + 
          convert(varchar, MONTH(f.F_OPERACION))) and
          f.SERIE <> @k_legada))       and
          v.ID_VENTA    = f.ID_VENTA   and 
          v.ID_CLIENTE  = c.ID_CLIENTE 
          order by SIT_FACTURA
END   