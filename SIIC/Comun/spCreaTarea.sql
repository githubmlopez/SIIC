USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCreaTarea')
BEGIN
  DROP  PROCEDURE spCreaTarea
END
GO
--EXEC spCreaTarea 1,'CU','MARIO',0, ' ',' '
CREATE PROCEDURE [dbo].[spCreaTarea]
(
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(6),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pBPrimTarea    bit,
@pStoreProc     varchar(50),
@pIdTarea       int OUT,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT 							 
) 
AS
BEGIN
  DECLARE
  @k_verdadero         bit         =  1,
  @k_falso             bit         =  0,
  @k_iniciando         varchar(1)  =  'I',
  @k_error             varchar(80) =  'E',
  @k_prim_tarea        int         =  1

  DECLARE
  @fol_tarea           int

  SET  @pError      =  ' '
  SET  @pMsgError   =  ' '
      
  IF  @pBPrimTarea  =  @k_verdadero
  BEGIN
    SET  @fol_tarea =  @k_prim_tarea
    SET  @pIdTarea  = @fol_tarea
  END
  ELSE
  BEGIN
    SET  @fol_tarea =
	(SELECT isnull(MAX(ID_TAREA),0) + 1 FROM FC_TAREA t WHERE t.CVE_EMPRESA = @pCveEmpresa AND 
	                                                t.ID_PROCESO = @pIdProceso AND t.FOLIO_EXEC = @pFolioExe)
    SET  @pIdTarea = @fol_tarea
  END
  
  BEGIN TRY 

    IF EXISTS (SELECT 1 FROM FC_PROC_EXEC WHERE CVE_EMPRESA = @pCveEmpresa AND ID_PROCESO = @pIdProceso AND
	                                            FOLIO_EXEC  = @pFolioExe)
    BEGIN
      INSERT  INTO FC_TAREA  
     (CVE_EMPRESA,
      ID_PROCESO,
      FOLIO_EXEC,
      ID_TAREA,
	  STORE_PROCEDURE,
      PCT_AVANCE,
	  NUM_REGISTROS) VALUES
     (@pCveEmpresa,
      @pIdProceso,
      @pFolioExe,
      @fol_tarea,
      @pStoreProc,
	  0,
	  0)
   END
   ELSE
   BEGIN
     RAISERROR ('(E) No existe Proc Exec',16,1)  
   END
 --   select ' Salgo de Insertar '
  END TRY

  BEGIN CATCH
    SET  @pBError   =  @k_verdadero
    SET  @pError    =  '(E) insertar Tarea;'
	SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    SELECT @pMsgError
--	EXECUTE spCreaTareaEvento @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
END
