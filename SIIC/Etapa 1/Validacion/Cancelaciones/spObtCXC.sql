USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtCXC')
BEGIN
  DROP  PROCEDURE spObtCXC
END
GO
--EXEC spObtCXC  1,'CU','MARIO','SIIC','202011',200,37,1,0,' ',' '
CREATE PROCEDURE spObtCXC 
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       numeric(9),
@pBError        bit OUT,
@pError         varchar(80) OUT, 
@pMsgError      varchar(400) OUT
AS
BEGIN
  DECLARE  @k_verdadero      varchar(1)   =  1,
           @k_falso          varchar(1)   =  0,
           @k_legada         varchar(6)   =  'LEGACY',
  		   @k_activa         varchar(1)   =  'A',
		   @k_no_concilida   varchar(2)   =  'NC',
		   @k_error          varchar(1)   =  'E',
		   @k_abierto        varchar(1)   =  'A',
		   @k_factura        varchar(4)   =  'FACT'

  DECLARE  @imp_tot_cxc      numeric(16,2),
           @num_reg_proc     int = 0


  IF  (SELECT SIT_PERIODO  FROM CI_PERIODO_CONTA WHERE CVE_EMPRESA = @pCveEmpresa AND ANO_MES = @pAnoPeriodo) = @k_abierto
  BEGIN

   SELECT e.RFC_EMI, r.RFC_REC, c.IMP_TOTAL, c.UUID
   FROM CI_CUENTA_X_COBRAR f, CFDI_COMPROBANTE c, CFDI_RECEPTOR r, CFDI_EMISOR e   
   WHERE f.CVE_EMPRESA         =  @pCveEmpresa        AND
	     f.SIT_CONCILIA_CXC    =  @k_no_concilida     AND
	     f.SERIE_CTE           <> @k_legada           AND   
	     f.SIT_TRANSACCION     =  @k_activa           AND  
		 f.ANO_MES            <=  @pAnoPeriodo        AND
		 f.CVE_EMPRESA         =  c.CVE_EMPRESA       AND
		 f.ANO_MES             =  c.ANO_MES           AND
		 c.CVE_TIPO            =  @k_factura          AND
		 f.UUID                =  c.UUID              AND
		 c.CVE_EMPRESA         =  r.CVE_EMPRESA       AND
		 c.ANO_MES             =  r.ANO_MES           AND
		 c.CVE_TIPO            =  r.CVE_TIPO          AND
		 c.UUID                =  r.UUID              AND
		 c.CVE_EMPRESA         =  e.CVE_EMPRESA       AND
		 c.ANO_MES             =  e.ANO_MES           AND
		 c.CVE_TIPO            =  e.CVE_TIPO          AND
		 c.UUID                =  e.UUID              


  END
  ELSE
  BEGIN
    SET  @pBError    =  @k_verdadero
    SET  @pError    =  '(E) El periodo' + ISNULL(@pAnoPeriodo, 'NULO') +  ' esta cerrado' 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END
END

