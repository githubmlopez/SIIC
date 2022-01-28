USE [ADMON01]
GO
/****** Carga de información Tarjetas Corporativas ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCFDICalImptoI')
BEGIN
  DROP  PROCEDURE spCFDICalImptoI
END
GO
--EXEC spCFDICalImptoI 'CU','MARIO','201906',104,1, 'FACT', 
--'isJhlk/EsLUWIpI2x7g2r033pX1VnWK58Ce+n4/HTHAbUyEXF22QRcsDGBSQWNM9lwDMOM9qNpjP7Qv+wuMxXUtt33NbvQfSdLzaZHKpZzg3ZYveG2bY7KHtCpmWtnEHpxHTcTLFgVFSM9qJKk3mwGJ4h4LhEotTBsqkDZBGKwDqUmSa7cn7ar03Z3eI60b1rj52RlVa/by+JxQxmkCWrONMUFHnoRypn06QbIXCQMGKStPNMfJvL/rmwwvaK3+2J22Plr+T2zFkBlj7ugt0VFsQQ23jTMDP40NnlRUVX1V0by5mgPoZDSwNfy/b6KMmWStyHF7JglUvB3/RUo9Hdg==',
--0,0,0,' ',' '
CREATE PROCEDURE [dbo].[spCFDICalImptoI]
(

@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pCveTipo         varchar(4),
@pUuid            varchar(36),
@pIdNodo          int,
@PimpDescuento    numeric(16,2) OUT,
@pError           varchar(80)   OUT,
@pMsgError        varchar(400)  OUT
)
AS
BEGIN
  SET  @pImpDescuento = 0

  IF EXISTS  (SELECT 1 FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES = @pAnoPeriodo AND 
                                                 CVE_TIPO    = @pCveTipo     AND UUID = @pUuid  AND ID_NODO  =  @pIdNodo)
  BEGIN
    SET @pImpDescuento =  
	(SELECT IMP_DESCUENTO FROM CFDI_PROD_SERV WHERE CVE_EMPRESA = @pCveEmpresa  AND ANO_MES  = @pAnoPeriodo AND 
                                        CVE_TIPO    = @pCveTipo     AND UUID = @pUuid  AND ID_NODO  =  @pIdNodo)
  END

END
