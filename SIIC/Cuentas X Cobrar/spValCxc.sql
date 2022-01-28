USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spValCxc')
BEGIN
  DROP  PROCEDURE spValCxc
END
GO
-- Proceso 28
-- EXEC  spValCxc 1, 'EGG', 'F48F409E-ADD8-4A47-9C82-7D8CA92250B2', 'INFRA', 'F48F409E-ADD8-4A47-9C82-7D8CA92250B4', 'P', 0, 'MPB001', 10, 2, 14, ' ', 28, 0, 0, 0, ' ', ' '
CREATE PROCEDURE [dbo].[spValCxc]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(100),
@pCveAplicacion varchar(10),
@pUiid          varchar(36),
@pCveMoneda     varchar(1),
@pTipoCambio    numeric(8,4),
@pCveChequera   varchar(6),
@pImoBruto      numeric(16,2),
@pImpIva        numeric(16,2),
@pImpNeto       numeric(16,2),
@pAnoPeriodo    varchar(6),
@pIdProceso     numeric(9),
@pFolioExe      int          OUT,
@pIdTarea       numeric(9)   OUT,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT

AS
BEGIN

  DECLARE  @hora_inicio        varchar(10) = ' ',
		   @hora_fin           varchar(10) = ' '

  DECLARE  @k_verdadero        bit  =  1,
           @k_falso            bit  =  0,
		   @k_error            varchar(1)  =  'E',
		   @k_peso             varchar(1)  =  'P'

  EXEC spCreaInstancia
  @pIdCliente,
  @pCveEmpresa,
  @pCodigoUsuario,
  @pCveAplicacion,
  @pAnoPeriodo,
  @pIdProceso,
  @pIdTarea      OUT,
  @pFolioExe     OUT,
  @k_falso,      -- Asignara un nuevo folio
  @hora_inicio   OUT,
  @hora_fin      OUT,
  @pBError       OUT,
  @pError        OUT,
  @pMsgError     OUT	

  IF   EXISTS (SELECT * FROM CI_CUENTA_X_COBRAR  WHERE  CVE_EMPRESA  =  @pCveEmpresa AND
                                                        UUID         =  @pUiid)
  BEGIN
    SET  @pBError  =  @k_verdadero
    SET  @pError =  'La Cuenta X Cobrar ya existe ' 
    SET  @pMsgError = @pError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END                                          

  IF  @pCveMoneda  <>  @k_peso  AND  ISNULL(@pTipoCambio,0) = 0
  BEGIN
    SET  @pBError  =  @k_verdadero
    SET  @pError =  'En moneda extranjera se requiere T. Cambio ' 
    SET  @pMsgError = @pError
	EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END                         

  IF  @pCveMoneda  <>
     (SELECT CVE_MONEDA  FROM  CI_CHEQUERA  WHERE CVE_EMPRESA = @pCveEmpresa  AND  CVE_CHEQUERA = @pCveChequera)
  BEGIN
    SET  @pBError  =  @k_verdadero
    SET  @pError =  'La moneda no corresp a chequera ' 
    SET  @pMsgError = @pError
	EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END 

  IF  (@pImoBruto + @pImpIva)  <>  @pImpNeto  
  BEGIN
    SET  @pBError  =  @k_verdadero
    SET  @pError =  'Imp Neto <> a Imp. Bruto + IVA- ' 
    SET  @pMsgError = @pError
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END
END