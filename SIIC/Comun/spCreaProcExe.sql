USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCreaProcExe')
BEGIN
  DROP  PROCEDURE spCreaProcExe
END
GO

-----------------------------------------------------------
/* Inserta registro de instancia de ejecución de proceso  */
-----------------------------------------------------------

--EXEC spCreaProcExe 1,'CU','MARIO','SIIC',202001, 1,0,' ',' '
CREATE PROCEDURE [dbo].[spCreaProcExe]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(6),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT 							 
) 
AS
BEGIN
  
  DECLARE
  @k_verdadero         bit         =  1,
  @k_falso             bit         =  0

  SET  @pError      =  ' '
  SET  @pMsgError   =  ' '
      
  BEGIN TRY 

    INSERT  INTO FC_PROC_EXEC  
   (CVE_EMPRESA,
    ID_PROCESO,
    FOLIO_EXEC,
    F_EJECUCION,
	H_INICIO,
    H_FIN,
    ANO_MES_PROC,
	CODIGO_USUARIO) VALUES
   (@pCveEmpresa,
    @pIdProceso,
    @pFolioExe,
    GETDATE(),
    CONVERT(varchar(10), GETDATE(), 108),
	' ',
	@pAnoPeriodo,
	@pCodigoUsuario)

  END TRY

  BEGIN CATCH
    SET  @pError    =  '(E) insertar Instancia '
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SELECT  @pMsgError 
  END CATCH
END
