USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spVerificaSaldosBancarios]    ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec spVerificaSaldosBancarios
alter PROCEDURE [dbo].[spVerificaSaldosBancarios] 
AS
BEGIN

Declare   @ano          int,
          @mes          int, 
          @chequera     varchar(6),
          @ano_mes      varchar(6),
          @saldo_ini    numeric(12,2),
          @saldo_fin    numeric(12,2),
          @f_inicio     date,
          @f_fin        date,
          @cargos       numeric(12,2),
          @abonos       numeric(12,2),
          @diferencia   numeric(12,2)


          
declare salbanc cursor for SELECT  cp.ANO_MES, cp.CVE_CHEQUERA, cp.F_INICIO, cp.F_FIN, cp.SDO_INICIO_MES, cp.SDO_FIN_MES
FROM  CI_CHEQUERA_PERIODO cp 

open  salbanc 
FETCH salbanc INTO  @ano_mes, @chequera, @f_inicio, @f_fin, @saldo_ini, @saldo_fin  
	                                      
WHILE (@@fetch_status = 0 )
BEGIN 

--select 'Seleccion ==> ' + @ano_mes + ' ' + @chequera

set @ano  = CONVERT(int,substring(@ano_mes,1,4))
set @mes  = CONVERT(int,substring(@ano_mes,5,2))

--select ' Año Mes ==> ', CONVERT(varchar(4),@ano) + ' ' + CONVERT(varchar(2),@mes)

SELECT @cargos = isnull(SUM(oper.cargo),0), @abonos = isnull(SUM(oper.abono),0),
@diferencia = isnull((SUM(oper.abono) - SUM(oper.cargo) + @saldo_ini - @saldo_fin),0)
FROM 
(select DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripcion,
case    
when m.CVE_CARGO_ABONO = 'C' then M.IMP_TRANSACCION     
else 0
end as cargo,
case    
when m.CVE_CARGO_ABONO = 'A' then M.IMP_TRANSACCION    
else 0
end as abono,
0 as saldo
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
select DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripcion, m.IMP_TRANSACCION as cargo, 0 as abono, 0 as saldo
from CI_CUENTA_X_PAGAR cp, CI_ITEM_C_X_P ip, CI_PROVEEDOR p, CI_CONCILIA_C_X_P ccp, CI_MOVTO_BANCARIO m, CI_OPERACION_CXP o
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
      m.SIT_MOVTO            =  'A'                    
union            
select  DISTINCT(m.ID_MOVTO_BANCARIO), m.F_OPERACION, substring(m.DESCRIPCION,1,40) as descripccion,
case    
when m.CVE_CARGO_ABONO = 'C' then M.IMP_TRANSACCION     
else 0
end as cargo,
case    
when m.CVE_CARGO_ABONO = 'A' then M.IMP_TRANSACCION    
else 0
end as abono,
0 as saldo
from CI_MOVTO_BANCARIO m, CI_TIPO_MOVIMIENTO t
WHERE m.CVE_TIPO_MOVTO       =  t.CVE_TIPO_MOVTO        AND
      year(m.F_OPERACION)    =  @ano                    AND
      MONTH(m.F_OPERACION)   =  @mes                    AND
      m.F_OPERACION          >= @f_inicio               AND
      m.F_OPERACION          <= @f_fin                  AND
      m.CVE_CHEQUERA         =  @chequera               AND
     (t.B_CONCILIA           =  0                       OR
      M.SIT_CONCILIA_BANCO   =  'NC')) AS oper



-- SELECT @ano_mes, @chequera, @f_inicio, @f_fin, @saldo_ini, @saldo_fin, @cargos, @abonos,@diferencia

UPDATE CI_CHEQUERA_PERIODO SET SDO_FIN_MES_CALC = @saldo_ini + @abonos - @cargos where ANO_MES = @ano_mes AND CVE_CHEQUERA = @chequera

FETCH salbanc INTO  @ano_mes, @chequera, @f_inicio, @f_fin, @saldo_ini, @saldo_fin 

END

select cp.ANO_MES, cp.CVE_CHEQUERA, cp.F_INICIO, cp.F_INICIO, cp.SDO_INICIO_MES, cp.SDO_FIN_MES, cp.SDO_FIN_MES_CALC, cp.SDO_FIN_MES - cp.SDO_FIN_MES_CALC from CI_CHEQUERA_PERIODO cp

close salbanc 
deallocate salbanc

END 