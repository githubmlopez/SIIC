Declare   @ano          int,
          @mes          int, 
          @chequera     varchar(6),
          @anomes       varchar(6),
          @saldo_ini    numeric(12,2),
          @saldo_fin    numeric(12,2),
          @f_inicio     date,
          @f_fin        date
          
set  @ano       = 2016
set  @mes       = 06
set  @chequera  = 'MPB981'

select @f_inicio = ch.F_INICIO, @f_fin = ch.F_FIN, @saldo_ini = ch.SDO_INICIO_MES, @saldo_fin = ch.SDO_FIN_MES
from CI_CHEQUERA_PERIODO ch WHERE
ANO_MES = CONVERT(varchar(4),@ano) +  replicate ('0',(02 - len(@mes))) + convert(varchar, @mes) AND
ch.CVE_CHEQUERA = @chequera

--SELECT SUM(oper.cargo) AS totcargo, SUM(oper.abono) as totaabono,
--SUM(oper.abono) - SUM(oper.cargo) + @saldo_ini - @saldo_fin as diferencia
--FROM 
(select m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripcion,
case    
when m.CVE_CARGO_ABONO = 'C' then M.IMP_TRANSACCION     
else 0
end as cargo,
case    
when m.CVE_CARGO_ABONO = 'A' then M.IMP_TRANSACCION    
else 0
end as abono,
0 as saldo, dbo.fnArmaProducto(f.ID_CONCILIA_CXC) as producto, f.SERIE + convert(varchar,f.ID_CXC) as identificador,
       f.CVE_F_MONEDA as moneda, c.NOM_CLIENTE as clientprov, f.IMP_F_BRUTO as impbruto, f.IMP_F_IVA as iva, f.IMP_F_NETO as impneto, f.TX_NOTA as nota
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
      m.SIT_MOVTO            =  'A'                     AND    
      f.SIT_TRANSACCION      =  'A'                     
union
select m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripcion, m.IMP_TRANSACCION as cargo, 0 as abono, 0 as saldo, O.DESC_OPERACION, convert(varchar,cp.ID_CXP) as identificador,
       cp.CVE_MONEDA as moneda, p.NOM_PROVEEDOR as clientprov, cp.IMP_BRUTO as impbruto, cp.IMP_IVA as iva, cp.IMP_NETO as impneto, cp.TX_NOTA as nota
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
select m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripccion,
case    
when m.CVE_CARGO_ABONO = 'C' then M.IMP_TRANSACCION     
else 0
end as cargo,
case    
when m.CVE_CARGO_ABONO = 'A' then M.IMP_TRANSACCION    
else 0
end as abono,
0 as saldo,
t.DESCRIPCION,' ' as identificador,' ' as moneda, ' ' as clientprov, 0 as impbruto, 0 as iva, 0 as impneto, ' ' as nota
from CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t
WHERE m.CVE_TIPO_MOVTO       =  t.CVE_TIPO_MOVTO        AND
      year(m.F_OPERACION)    =  @ano                    AND
      MONTH(m.F_OPERACION)   =  @mes                    AND
      m.F_OPERACION          >= @f_inicio               AND
      m.F_OPERACION          <= @f_fin                  AND
      m.CVE_CHEQUERA         =  @chequera               AND
     (t.B_CONCILIA           =  0                       OR
      M.SIT_CONCILIA_BANCO   =  'NC')) order by F_OPERACION, identificador, cargo -- AS oper

