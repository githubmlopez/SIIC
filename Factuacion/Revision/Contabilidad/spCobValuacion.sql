USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCobValuacion]    Script Date: 06/03/2017 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec spCobValuacion '201701', 'A' 
ALTER PROCEDURE [dbo].[spCobValuacion] @pano_mes varchar(6), @ptipo_con varchar(1)
AS
BEGIN

declare  @k_dolar       varchar(1),
         @k_peso        varchar(1),
         @k_conciliado  varchar(2),
         @k_conc_error  varchar(2),
         @k_concelada   varchar(1),
         @k_legado      varchar(6),
         @k_ambos       varchar(1);
         
set  @k_dolar        =  'D'
set  @k_peso         =  'P'
set  @k_conciliado   =  'CC'
set  @k_conc_error   =  'CE'
set  @k_concelada    =  'C'
set  @k_ambos        =  'A'
set  @k_legado       =  'LEGACY'

select    
f.F_OPERACION AS 'F. Operacion', 
f.CVE_EMPRESA AS 'Empresa', f.SERIE as 'Sertie', f.ID_CXC as 'Id. CXC',   
c.ID_CLIENTE AS 'Id. Cte.', c.NOM_CLIENTE AS 'Nombre Cliente', f.CVE_F_MONEDA AS 'Cve. Moneda',
f.IMP_F_BRUTO AS 'Imp. Bruto', f.IMP_F_IVA AS 'Imp. IVA', f.IMP_F_NETO AS 'Imp. Neto',
f.TIPO_CAMBIO AS 'Tipo Camb.',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA) 
  ELSE 0
end as 'Imp. Pesos',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar  
  THEN dbo.fnObtTipoCambCierr(@pano_mes) 
  ELSE 0 
end as 'T.C. Cierr',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN round(dbo.fnObtTipoCambCierr(@pano_mes) * f.IMP_F_NETO,2)
  ELSE 0
end as 'Imp.Pesos Cierre',
case
  WHEN f.CVE_F_MONEDA  =  @k_dolar
  THEN   round(((dbo.fnObtTipoCambCierr(@pano_mes) * f.IMP_F_NETO) - 
                dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, f.CVE_F_MONEDA)),2)
  ELSE 0
end as 'Val. Cambiaria'
  
from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c     
where    
f.SIT_CONCILIA_CXC    NOT IN (@k_conciliado,@k_conc_error) and    
f.ID_VENTA            =   v.ID_VENTA           and    
v.ID_CLIENTE          =   c.ID_CLIENTE         and    
f.SIT_TRANSACCION     <>  @k_concelada         and    
f.SERIE               <>  @k_legado            and 
((@ptipo_con          =   @k_dolar             and
 f.CVE_F_MONEDA       =   @k_dolar)            or
(@ptipo_con           =   @k_ambos             and
 f.CVE_F_MONEDA       in  (@k_dolar, @k_peso)))     
END