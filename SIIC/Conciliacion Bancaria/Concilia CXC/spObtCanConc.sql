USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
--------------------------------------------------------------------------------------------------
-- Obtiene información tanto de bancos como facturas (CXC)  que fueron conciliados a fin de dar --
-- la posibilidad de cancelarlos                                                                --                                                                                            --
--------------------------------------------------------------------------------------------------

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtCanConc')
BEGIN
  DROP  PROCEDURE spObtCanConc
END
GO

--EXEC spObtCanConc 1,'CU','MARIO','SIIC','202006',203,1,1,'MPB981',0,' ',' '
CREATE PROCEDURE [dbo].[spObtCanConc]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pCveChequera   varchar(6),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

DECLARE  @k_CXC  varchar(3) = 'CXC'

SELECT  m.ID_MOVTO_BANCARIO, m.B_REFERENCIA, REFERENCIA, m.F_OPERACION, m.CVE_CHEQUERA, ch.CVE_MONEDA, m.IMP_TRANSACCION, m.DESCRIPCION,
        c.ID_CONCILIA_CXC, c.F_OPERACION AS F_OPERACION_F, c.CVE_CHEQUERA AS CVE_CHEQUERA_F, c.IMP_F_NETO, ct.NOM_CLIENTE
FROM CI_CONCILIA_C_X_C cc, CI_MOVTO_BANCARIO m, CI_CUENTA_X_COBRAR c, CI_CHEQUERA ch,CI_CLIENTE ct
WHERE m.CVE_EMPRESA         =  @pCveEmpresa          AND
      m.ANO_MES             =  @pAnoPeriodo          AND
	  m.CVE_CHEQUERA        =  @pCveChequera         AND
	  m.CVE_TIPO_MOVTO      =  @k_CXC			     AND
      cc.CVE_EMPRESA        =  m.CVE_EMPRESA         AND
      cc.ID_MOVTO_BANCARIO  =  m.ID_MOVTO_BANCARIO   AND
	  cc.ID_CONCILIA_CXC    =  c.ID_CONCILIA_CXC     AND
	  m.CVE_EMPRESA	        =  ch.CVE_EMPRESA        AND
	  m.CVE_CHEQUERA        =  ch.CVE_CHEQUERA       AND
	  c.CVE_EMPRESA		    =  ct.CVE_EMPRESA        AND
	  c.ID_CLIENTE          =  ct.ID_CLIENTE         ORDER BY M.ID_MOVTO_BANCARIO

END
