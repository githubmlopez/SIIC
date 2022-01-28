USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spConcMovBanc')
BEGIN
  DROP  PROCEDURE spConcMovBanc
END
GO
------------------------------------------------------------------------------------------
--  A partir de una chequera y un periodo, muestra las facturas contra las cuales concilio --
------------------------------------------------------------------------------------------

--EXEC spConcMovBanc 'CU','MARIO','201903','MDB437',' ',' '
CREATE PROCEDURE [dbo].[spConcMovBanc]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pCveChequera     varchar(6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN

  DECLARE  @k_cancelado       varchar(2)  =  'CA',
           @k_normal          varchar(1)  =  'N',
		   @k_referencia      varchar(1)  =  'R',
		   @k_cxc             varchar(3)  =  'CXC'

  SELECT m.F_OPERACION, m.CVE_CHEQUERA, m.CVE_TIPO_MOVTO, m.IMP_TRANSACCION, m.DESCRIPCION, m.ID_MOVTO_BANCARIO, @k_normal,
  CASE
  WHEN   EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_C c WHERE  c.ID_MOVTO_BANCARIO = m.ID_MOVTO_BANCARIO)
  THEN   1
  ELSE   0
  END 
  FROM   CI_MOVTO_BANCARIO m
  WHERE  m.ANO_MES  =  @pAnoPeriodo  AND CVE_CHEQUERA =  @pCveChequera  AND
         m.REFERENCIA         NOT IN
  	    (SELECT r.REFERENCIA FROM CI_BMX_ACUM_REF r
		 WHERE
		 r.CVE_EMPRESA   =  @pCveEmpresa         AND
		 ANO_MES         =  @pAnoPeriodo         AND
		 m.CVE_CHEQUERA  =  r.CVE_CHEQUERA       AND
		 m.REFERENCIA    =  r.REFERENCIA         AND
		 m.CVE_CHEQUERA  =  r.CVE_CHEQUERA)      AND
		 CVE_TIPO_MOVTO  =  @k_cxc
  UNION
  SELECT m.F_OPERACION, m.CVE_CHEQUERA, m.CVE_TIPO_MOVTO, m.IMP_TRANSACCION, m.DESCRIPCION, m.ID_MOVTO_BANCARIO, @k_referencia,
  CASE
  WHEN   EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_C c WHERE  c.ID_MOVTO_BANCARIO = m.ID_MOVTO_BANCARIO)
  THEN   1
  ELSE   0
  END 
  FROM CI_MOVTO_BANCARIO m, CI_CHEQUERA ch, CI_BMX_ACUM_REF r
  WHERE   r.ANO_MES            =  @pAnoPeriodo     AND
          r.CVE_CHEQUERA       =  @pCveChequera    AND
		  r.REFERENCIA         =  m.REFERENCIA     AND
		  m.CVE_CHEQUERA       =  ch.CVE_CHEQUERA  AND
          m.CVE_TIPO_MOVTO     =  @k_cxc           AND
		  m.SIT_MOVTO         <>  @k_cancelado     AND
		  CVE_TIPO_MOVTO       =  @k_cxc       

END
