  USE ADMON01
  go 
  DECLARE  @TMovBancFact TMOVBANFACT

  INSERT INTO @TMovBancFact (
  CVE_EMPRESA,
  ANO_PERIODO,
  ID_MOVTO_BANCARIO,
  B_REFERENCIA,
  REFERENCIA,
  B_PARCIAL,
  ID_ANTICIPO,
  CVE_CHEQUERA,
  SERIE,
  ID_CXC)
  VALUES (
  'CU',
  '201903',
  0,
  0,
  ' ',
  1,
  1,
  'MDB437',
  'CUM',
  1293)

--2947
--2948
--2949

--  INSERT INTO @TMovBancFact (
--  CVE_EMPRESA,
--  ANO_PERIODO,
--  ID_MOVTO_BANCARIO,
--  CVE_TIPO,
--  REFERENCIA,
--  CVE_CHEQUERA,
--  SERIE,
--  ID_CXC)
--  VALUES (
--  'CU',
--  '201903',
--  2964,
--  'N',
--  '0',
-- 'MPB981',
-- 'CUM',
-- 1288)

--  INSERT INTO @TMovBancFact (
--  CVE_EMPRESA,
--  ANO_PERIODO,
--  ID_MOVTO_BANCARIO,
--  CVE_TIPO,
--  REFERENCIA,
--  CVE_CHEQUERA,
--  SERIE,
--  ID_CXC)
--  VALUES (
--  'CU',
--  '201903',
--  2965,
--  'N',
--  '0',
-- 'MPB981',
-- 'CUM',
-- 1289
--)

--  INSERT INTO @TMovBancFact (
--  CVE_EMPRESA,
--  ANO_PERIODO,
--  ID_MOVTO_BANCARIO,
--  CVE_TIPO,
--  REFERENCIA,
--  CVE_CHEQUERA,
--  SERIE,
--  ID_CXC)
--  VALUES (
--  'CU',
--  '201903',
--  2971,
--  'N',
--  '0',
-- 'MPB981',
-- 'CUM',
-- 1290
--)

--@pIdCliente     int,
--@pCveEmpresa    varchar(4),
--@pCodigoUsuario varchar(20),
--@pCveAplicacion varchar(10),
--@pAnoPeriodo    varchar(8),
--@pIdProceso     numeric(9),
--@pFolioExe      int,
--@pIdTarea       numeric(9),
--@TMovBancFact TMOVBANFACT READONLY,
--@pBError        bit,
--@pError         varchar(80) OUT,
--@pMsgError      varchar(400) OUT
 
EXEC spActConcilia 1,'CU','MARIO','SIIC','201903',200,69,1,@TMovBancFact,0,' ',' '

  SELECT * FROM CI_FACTURA WHERE ID_CXC IN (1293)
  SELECT * FROM CI_MOVTO_BANCARIO WHERE ID_MOVTO_BANCARIO IN (2919, 2947,2957)
  SELECT * FROM CI_MOVTO_BANCARIO WHERE ANO_MES = '201903' AND CVE_CHEQUERA = 'MPB981'

  EXEC spCancMovConc 'CU','MARIO','201903',2947,' ',' '


  SELECT * FROM CI_CONCILIA_C_X_C

   DELETE FROM CI_CONCILIA_C_X_P

SELECT * FROM CI_FACTURA WHERE CVE_CHEQUERA = 'MDB437' AND F_OPERACION BETWEEN '2019-03-01' AND '2019-03-30'
--1293

UPDATE  CI_FACTURA SET IMP_F_NETO = 2627.25, SIT_CONCILIA_CXC = 'NC' WHERE ID_CXC = 1293

--PAGO RECIBIDO DE    14970107493 TRANSF.  Referencia Númerica: DEPOS D049073114 Autorización: 00021582

SELECT * FROM CI_MOVTO_BANCARIO WHERE DESCRIPCION LIKE '%00021582%'

  go 
  DECLARE  @TMovBancCxp TMOVBANCXP

  INSERT INTO @TMovBancCxp (
  CVE_EMPRESA,
  ANO_PERIODO,
  ID_MOVTO_BANCARIO,
  B_PAGO,
  ID_PAGO,
  CVE_CHEQUERA,
  ID_CXP)
  VALUES (
  'CU',
  '201905',
  3091,
  1,
  1,
  'MPB981',
  0)

EXEC spActConcilCxP 1,'CU','MARIO','SIIC','201905',200,69,1,@TMovBancCxp,0,' ',' '  


