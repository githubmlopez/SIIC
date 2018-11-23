Declare   @ano          int,
          @mes          int, 
          @chequera     varchar(6),
          @anomes       varchar(6),
          @saldo_ini    int,
          @saldo_fin    int,
          @f_inicio     date,
          @f_fin        date
          
set  @ano       = 2016
set  @mes       = 09
set  @chequera  = 'MDB437'

select @f_inicio = ch.F_INICIO, @f_fin = ch.F_FIN, @saldo_ini = ch.SDO_INICIO_MES, @saldo_fin = ch.SDO_FIN_MES
from CI_CHEQUERA_PERIODO ch WHERE
ANO_MES = CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes) AND
ch.CVE_CHEQUERA = @chequera

select m.F_OPERACION, substring(m.DESCRIPCION,1,40), 0, m.IMP_TRANSACCION, 0, dbo.fnArmaProducto(f.ID_CONCILIA_CXC), f.SERIE + convert(varchar,f.ID_CXC),
       f.CVE_F_MONEDA, c.NOM_CLIENTE, f.IMP_F_BRUTO, f.IMP_F_IVA, f.IMP_F_NETO, f.TX_NOTA
from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m
WHERE f.ID_VENTA             =  v.ID_VENTA              AND
      v.ID_CLIENTE           =  c.ID_CLIENTE            AND
      f.ID_CONCILIA_CXC      =  cc.ID_CONCILIA_CXC      AND
      m.ID_MOVTO_BANCARIO    =  cc.ID_MOVTO_BANCARIO    AND
      year(m.F_OPERACION)    =  @ano                    AND
      MONTH(m.F_OPERACION)   =  @mes                    AND
      m.F_OPERACION          >= @f_inicio               AND
      m.F_OPERACION          <= @f_fin                  AND
      m.CVE_CHEQUERA         =  @chequera               AND
      m.SIT_MOVTO            =  'A'
union
select m.F_OPERACION, substring(m.DESCRIPCION,1,40), m.IMP_TRANSACCION, 0, 0, O.DESC_OPERACION, convert(varchar,cp.ID_CXP),
       cp.CVE_MONEDA, p.NOM_PROVEEDOR, cp.IMP_BRUTO, cp.IMP_IVA, cp.IMP_NETO, cp.TX_NOTA
from CI_CUENTA_X_PAGAR cp, CI_PROVEEDOR p, CI_CONCILIA_C_X_P ccp, CI_MOVTO_BANCARIO m, CI_OPERACION_CXP o
WHERE cp.ID_PROVEEDOR        =  p.ID_PROVEEDOR          AND
      cp.ID_CONCILIA_CXP     =  ccp.ID_CONCILIA_CXP     AND
      cp.CVE_OPERACION       =  o.CVE_OPERACION         AND
      m.ID_MOVTO_BANCARIO    =  ccp.ID_MOVTO_BANCARIO   AND
      year(m.F_OPERACION)    =  @ano                    AND
      MONTH(m.F_OPERACION)   =  @mes                    AND
      m.F_OPERACION          >= @f_inicio               AND
      m.F_OPERACION          <= @f_fin                  AND

      m.CVE_CHEQUERA         =  @chequera               AND
      m.SIT_MOVTO            =  'A'                     
union            
select m.F_OPERACION, substring(m.DESCRIPCION,1,40),
case    
when m.CVE_CARGO_ABONO = 'C' then M.IMP_TRANSACCION    
else 0
end,
case    
when m.CVE_CARGO_ABONO = 'A' then M.IMP_TRANSACCION    
else 0
end,
0,
case    
when substring(m.CVE_TIPO_MOVTO,1,1) = 'T' then 'Trasp. Bancario'    
when substring(m.CVE_TIPO_MOVTO,1,1) = 'M' then 'Comis. Bancaria'    
else ' '
end,
' ',' ', ' ', 0, 0, 0, ' '
from CI_MOVTO_BANCARIO m
WHERE year(m.F_OPERACION)    =  @ano                    AND
      MONTH(m.F_OPERACION)   =  @mes                    AND
      m.F_OPERACION          >= @f_inicio               AND
      m.F_OPERACION          <= @f_fin                  AND
      m.CVE_CHEQUERA         =  @chequera               AND
      substring(m.CVE_TIPO_MOVTO,1,1) IN ('T','M')      



