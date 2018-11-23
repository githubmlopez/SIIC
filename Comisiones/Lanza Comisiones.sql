declare @f_real_pago date,
        @ano  int,
        @mes_inicio_cxc int,
        @mes varchar(2)

set @f_real_pago = '2016-12-11'   

set @ano  = YEAR(@f_real_pago);

set @mes_inicio_cxc  = MONTH(@f_real_pago)

--if @mes_inicio_cxc < 10
--begin
--  set @mes_inicio_cxc = '0' + @mes_inicio_cxc
--end
SELECT * FROM CI_VENTA
SELECT * FROM CI_VENTA_FACTURA
SELECT * FROM CI_FACTURA
SELECT * FROM CI_ITEM_C_X_C
SELECT * FROM CI_CUPON_COMISION
DELETE FROM CI_CUPON_COMISION

SELECT * FROM CI_PROD_PROCESO WHERE CVE_VENDEDOR = 'PIRA' AND CVE_PRODUCTO = 'ET'

   set @mes = replicate ('0',(02 - len(@mes_inicio_cxc))) + convert(varchar, @mes_inicio_cxc)

select @ano
select @mes_inicio_cxc  
select @mes

SELECT * FROM CI_SUBPRODUCTO  P11010
SELECT * FROM CI_VENDEDOR DAFU
CVE_PROCESO TODO

update CI_FACTURA  set B_FACTURA_PAGADA = 1 where ID_CONCILIA_CXC = 62
EXEC spCalculaComision 34



delete FROM CI_CUPON_COMISION WHERE SERIE <> 'LEGACY' AND ID_CXC = 494


SELECT * FROM CI_CUPON_COMISION WHERE SERIE <> 'LEGACY' AND ID_CXC = 494


SELECT * FROM CI_PROD_PROCESO WHERE CVE_VENDEDOR = 'SOPO' AND CVE_PRODUCTO = 'SE'
UPDATE CI_PROD_PROCESO SET pje_comision = 0 WHERE CVE_VENDEDOR = 'SOPO' AND CVE_PRODUCTO = 'SE'


SELECT * FROM CI_PROD_PROCESO WHERE CVE_VENDEDOR = 'DAFU' AND CVE_PRODUCTO = 'SE'

SELECT * FROM CI_AUDIT_ERROR  
SELECT * FROM CI_CUPON_COMISION where ID_CXC = 610

update CI_CUPON_COMISION set IMP_CUPON = 744, TX_NOTA = 'Se ajusto manual, viaticos en factura' where ID_CXC = 610

DELETE FROM CI_CUPON_COMISION
SELECT * FROM CI_AUDIT_ERROR
select * from CI_FACTURA

select * from CI_TIPO_CAMBIO

select * from CI_VENTA_FACTURA

SELECT * FROM  CI_PROD_PROCESO


SELECT * FROM CI_PRODUCTO where CVE_PRODUCTO = 'SE'

SELECT * FROM CI_SUBPRODUCTO WHERE CVE_SUBPRODUCTO = 'S90010'

SELECT * FROM CI_ITEM_C_X_C  WHERE ID_CXC = 562

SELECT * FROM CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m WHERE c.ID_CONCILIA_CXC = 43 AND
                                                             c.ID_MOVTO_BANCARIO = m.ID_MOVTO_BANCARIO
SELECT * FROM CI_FACTURA f, CI_ITEM_C_X_C i  WHERE ID_CONCILIA_CXC = 5  and
                                                   f.CVE_EMPRESA = i.CVE_EMPRESA and
                                                   f.SERIE = i.SERIE and
                                                   f.ID_CXC = i.ID_CXC
                                                   
UPDATE CI_ITEM_C_X_C SET CVE_VENDEDOR2 = NULL WHERE CVE_VENDEDOR2 = 'SVEN' 

                                                   
                                                  
select c.NOM_CLIENTE, f.IMP_F_NETO from CI_FACTURA f, CI_VENTA v, CI_CLIENTE c where f.ID_CONCILIA_CXC = 43 and
                                                           f.ID_VENTA = v.ID_VENTA and
                                                           v.ID_CLIENTE = c.ID_CLIENTE

SELECT * FROM CI_VENDEDOR where CVE_VENDEDOR = 'SOPO'

SELECT * FROM CI_AUDIT_ERROR

select * from CI_SUBPRODUCTO WHERE cve_subproducto = 'D92080'
select * FROM CI_PRODUCTO WHERE cve_producto = 'ET'

  SELECT  F_OPERACION, F_REAL_PAGO, IMP_R_NETO_COM, TIPO_CAMBIO_LIQ,
          @cve_r_moneda = CVE_R_MONEDA, @id_venta = ID_VENTA, ID_FACT_PARCIAL,
          @b_fact_pagada = B_FACTURA_PAGADA, @sit_transaccion =  SIT_TRANSACCION, IMP_F_BRUTO, CVE_F_MONEDA,
          @cve_empresa = CVE_EMPRESA, @serie = SERIE, @id_cxc = @ID_CXC FROM CI_FACTURA WHERE ID_CONCILIA_CXC = 62
          
 SELECT B_PAGA_COMISION FROM CI_VENDEDOR WHERE CVE_VENDEDOR = 'PIRA'
 
 select * from CI_PRODUCTO

SELECT * FROM CI_CLIENTE

SELECT  'update CI_FACTURA  set B_FACTURA_PAGADA = 1 where ID_CONCILIA_CXC = ', ID_CONCILIA_CXC AS AC1, 
'EXEC spCalculaComision', ID_CONCILIA_CXC AS AC2
 FROM CI_FACTURA WHERE B_FACTURA_PAGADA = 0
128 127 80 125 126 67 103 119 4 130 132 105 94 129 149 141 146 19 131 140 136

Comisiones 060716

--------------------------
 
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '22072016'  where ID_CONCILIA_CXC = 	166	EXEC spCalculaComision	166




update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	127	EXEC spCalculaComision	127
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	80	EXEC spCalculaComision	80
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	125	EXEC spCalculaComision	125
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    126	EXEC spCalculaComision	126
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    67	EXEC spCalculaComision	67
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    103	EXEC spCalculaComision	103
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    119	EXEC spCalculaComision	119
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    4	EXEC spCalculaComision	4
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    130	EXEC spCalculaComision	130
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	132	EXEC spCalculaComision	132
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	105	EXEC spCalculaComision	105
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	94	EXEC spCalculaComision	94
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    129	EXEC spCalculaComision	129
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    149	EXEC spCalculaComision	149
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    141	EXEC spCalculaComision	141
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =    146	EXEC spCalculaComision	146
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC =  19	EXEC spCalculaComision	19
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	131	EXEC spCalculaComision	131
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	140	EXEC spCalculaComision	140
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	136	EXEC spCalculaComision	136

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '06072016'  where ID_CONCILIA_CXC = 	129	EXEC spCalculaComision	129

------------------    Calculo JuLio 2016 ----------------

169
108
137
139
143
143
143
143
144
150
150
160
163
167

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC = 	169	EXEC spCalculaComision	169
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC = 	108	EXEC spCalculaComision	108
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC = 	137	EXEC spCalculaComision	137
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    139	EXEC spCalculaComision	139
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    143	EXEC spCalculaComision	143
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    144	EXEC spCalculaComision	144
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    150	EXEC spCalculaComision	150
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    160	EXEC spCalculaComision	160
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC =    163	EXEC spCalculaComision	163	
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03082016'  where ID_CONCILIA_CXC = 	167	EXEC spCalculaComision	167


-- Calculo Agosto 2016

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	138	EXEC spCalculaComision	138
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	148	EXEC spCalculaComision	148
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	159	EXEC spCalculaComision	159
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	162	EXEC spCalculaComision	162
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	171	EXEC spCalculaComision	171
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	173	EXEC spCalculaComision	173
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	178	EXEC spCalculaComision	178
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	181	EXEC spCalculaComision	181
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	182	EXEC spCalculaComision	182
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	184	EXEC spCalculaComision	184
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	187	EXEC spCalculaComision	187
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	188	EXEC spCalculaComision	188
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '02092016'  where ID_CONCILIA_CXC = 	189	EXEC spCalculaComision	189


-------------------------

-- Calculo Septiembre 2016

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	153	EXEC spCalculaComision	153
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	154	EXEC spCalculaComision	154
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	177	EXEC spCalculaComision	177
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	197	EXEC spCalculaComision	197
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	206	EXEC spCalculaComision	206
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	213	EXEC spCalculaComision	213
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	214	EXEC spCalculaComision	214

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	185	EXEC spCalculaComision	185
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	195	EXEC spCalculaComision	195
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '03102016'  where ID_CONCILIA_CXC = 	215	EXEC spCalculaComision	215


-- Calculo Octubre 2016

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	151	EXEC spCalculaComision	151
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	152	EXEC spCalculaComision	152
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	155	EXEC spCalculaComision	155
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	157	EXEC spCalculaComision	157
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	175	EXEC spCalculaComision	175
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	179	EXEC spCalculaComision	179
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	186	EXEC spCalculaComision	186
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	192	EXEC spCalculaComision	192
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	196	EXEC spCalculaComision	196
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	199	EXEC spCalculaComision	199
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	205	EXEC spCalculaComision	205
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	207	EXEC spCalculaComision	207
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	211	EXEC spCalculaComision	211
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	212	EXEC spCalculaComision  212
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	219	EXEC spCalculaComision	219
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	220	EXEC spCalculaComision	220
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	224	EXEC spCalculaComision	224
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	225	EXEC spCalculaComision	225
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	226	EXEC spCalculaComision	226
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	228	EXEC spCalculaComision	228
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	230	EXEC spCalculaComision	230
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	231	EXEC spCalculaComision	231
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	232	EXEC spCalculaComision	232
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	233	EXEC spCalculaComision	233
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '07112016'  where ID_CONCILIA_CXC = 	235	EXEC spCalculaComision	235


-- Calculo Noviembre 2016

update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	190	EXEC spCalculaComision	190
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	208	EXEC spCalculaComision	208
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	217	EXEC spCalculaComision	217
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	222	EXEC spCalculaComision	222
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	227	EXEC spCalculaComision	227
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	240	EXEC spCalculaComision	240
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	241	EXEC spCalculaComision	241
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	245	EXEC spCalculaComision	245
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	248	EXEC spCalculaComision	248
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	249	EXEC spCalculaComision	249
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	251	EXEC spCalculaComision	251
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	252	EXEC spCalculaComision	252
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	256	EXEC spCalculaComision	256
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	257	EXEC spCalculaComision  257
update CI_FACTURA  set B_FACTURA_PAGADA = 1, FIRMA = '05112016'  where ID_CONCILIA_CXC = 	261	EXEC spCalculaComision	261

190
208
217
222
227
240
241
245
248
249
251
252
256
257
261




select * from CI_CUPON_COMISION WHERE ID_CXC = 16 and ANO_MES > '201606'

DELETE from CI_CUPON_COMISION WHERE ID_CXC = 16 and ANO_MES = '201606' 

update CI_CUPON_COMISION set imp_cupon = 453.72 WHERE ID_CXC = 500 and ANO_MES = '201606' 

INSERT INTO CI_CUPON_COMISION 
      (ANO_MES
      ,CVE_EMPRESA
      ,SERIE
      ,ID_CXC
      ,ID_ITEM
      ,NUM_PAGO
      ,CVE_VENDEDOR
      ,CVE_PROCESO
      ,PJE_COMISION
      ,IMP_CUPON
      ,TX_NOTA)
SELECT '201606'
      ,CVE_EMPRESA
      ,SERIE
      ,ID_CXC
      ,ID_ITEM
      ,NUM_PAGO
      ,CVE_VENDEDOR
      ,CVE_PROCESO
      ,PJE_COMISION
      ,106.25
      ,'Pago cupon 1  ;  5 periodos**'
  FROM CI_CUPON_COMISION   
  WHERE ID_CXC = 605 AND ANO_MES IN ('201605') 
GO

SELECT * FROM CI_FACTURA WHERE ID_CXC = 607

update CI_ITEM_C_X_C set IMP_COM_DIR1 = 4662.50 WHERE ID_CXC = 607 AND ID_ITEM =163

SELECT   * FROM CI_CUPON_COMISION  WHERE ID_CXC = 599 
DELETE   FROM CI_CUPON_COMISION  WHERE ID_CXC = 599 
 
  FROM CI_CUPON_COMISION   
 WHERE ID_CXC = 527 AND ANO_MES IN ('201602','201603') --('201602','201603','201604') 