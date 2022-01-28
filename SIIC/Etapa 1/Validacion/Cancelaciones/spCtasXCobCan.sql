USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCtasXCobCan')
BEGIN
  DROP  PROCEDURE spCtasXCobCan
END
GO
--EXEC spCtasXCobCan 1,'CU','MARIO','SIIC','201906',200,37,1,0,' ',' '
CREATE PROCEDURE spCtasXCobCan  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pTCancelaCfdi  TCANCELACFDI READONLY,
@pBError        bit OUT,
@pError         varchar(80) OUT, 
@pMsgError      varchar(400) OUT
AS
BEGIN
  
  DECLARE  @TCxcCan   TABLE
          (RowID      int  identity(1,1),
		   UUID       varchar(36))

  DECLARE  @serie         varchar(6),
           @id_cxc        int,
           @uuid          varchar(36),
		   @NumRegistros  int,
		   @RowCount      int,
		   @error         varchar(80)

  DECLARE  @k_verdadero   bit  =  1,
           @k_falso       bit  =  0,
           @k_cancelada      varchar(1)  =  'C',
		   @k_legada         varchar(6)  =  'LEGACY',
		   @k_no_concilia    varchar(2)  =  'NC',
		   @k_activa         varchar(1)  =  'A',
		   @k_factura        varchar(4)  =  'FACT',
		   @k_error          varchar(1)  =  'E'

  INSERT   @TCxcCan (UUID) 
  SELECT   
  s.ID_UNICO
  FROM CFDI_META_CXC s     
  WHERE -- s.CVE_EMPRESA   = @pCveEmpresa   AND         
        s.SIT_CONCILIA     = @k_cancelada        

  INSERT   @TCxcCan (UUID) 
  SELECT   
  c.UUID
  FROM @pTCancelaCfdi c     

END