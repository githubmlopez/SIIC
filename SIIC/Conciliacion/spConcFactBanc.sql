USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spConcFactBanc')
BEGIN
  DROP  PROCEDURE spConcFactBanc
END
GO

--EXEC spConcFactBanc 'CU','MARIO','201903',2965,'MPDB981',' ',' '
CREATE PROCEDURE [dbo].[spConcFactBanc]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdMovtoBancario int,
@pCveChequera     varchar(6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN

  DECLARE  @k_cancelado       varchar(2)  =  'CA'

  SELECT f.F_OPERACION, f.SERIE, f.ID_CXC, f.CVE_CHEQUERA, c.NOM_CLIENTE,F.IMP_F_NETO
  FROM   CI_FACTURA f, CI_VENTA v, CI_CLIENTE c, CI_CONCILIA_C_X_C cc
  WHERE  f.ID_VENTA                     =  v.ID_VENTA        AND
         v.ID_CLIENTE                   =  c.ID_CLIENTE      AND
		cc.ID_MOVTO_BANCARIO            =  @pIdMovtoBancario AND
		cc.ID_CONCILIA_CXC              =  f.ID_CONCILIA_CXC AND
		 f.SIT_TRANSACCION             <>  @k_cancelado     
END
