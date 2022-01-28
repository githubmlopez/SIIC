USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spLanzaProcCont')
BEGIN
  DROP  PROCEDURE spLanzaProcCont
END
GO

-- EXEC spLanzaProcCont 2,'EGG','MARIO','SIIC','202109',1001,0,0,0,' ', ' ', 0,' ',' '  
CREATE OR ALTER PROCEDURE [dbo].[spLanzaProcCont]
  (
  @pIdCliente       int,
  @pCveEmpresa      varchar(4),
  @pCodigoUsuario   varchar(20),
  @pCveAplicacion   varchar(10),
  @pAnoPeriodo      varchar(6),
  @pIdProceso       numeric(9),
  @pValPeriodo      bit,
  @pFolioExe        int          OUT,
  @pBFolioExe       bit,
  @pHoraInicio      varchar(10)  OUT,
  @pHoraFin         varchar(10)  OUT,
  @pBError          bit          OUT,
  @pError           varchar(80)  OUT,
  @pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE @k_verdadero  bit        = 1,
          @k_falso      bit        = 0,
          @k_error      varchar(1) = 'E'

  DECLARE @msg_error    varchar(400),
          @id_tarea     numeric(9),
          @sql          nvarchar(max),
          @parametros   nvarchar(max),
          @sit_periodo  varchar(1),
          @b_correcto   bit,
          @base_datos   varchar(20),
          @owner        varchar(20),
          @store_proc   varchar(50),
		  @b_error_int  varchar(1)

  SET @msg_error   =  ' '
  SET @id_tarea    =  0
  SET @b_error_int = @k_falso

  BEGIN TRY
-------------------------------------------------------------------------
/*  Ejecución de creación de instancia para el proceso que se ejecuta  */
------------------------------------------------------------------------- 
--EXEC spCreaInstancia 2,'EGG','MARIO','SIIC','201812',1,0,0,0,' ', ' ', 0,' ',' '  

   EXEC  spCreaInstancia  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @id_tarea OUT, 
                          @pFolioExe OUT, @pBFolioExe, @pHoraInicio OUT, @pHoraFin OUT, @b_error_int OUT, @pError OUT,
	                      @pMsgError OUT

   IF  @b_error_int  =  @k_verdadero
   BEGIN
	 SET  @pBError  =  @k_verdadero
     IF EXISTS (SELECT 1
                FROM  FC_TAREA
                WHERE CVE_EMPRESA = @pCveEmpresa
                AND   ID_PROCESO    = @pIdProceso
                AND   FOLIO_EXEC    = @pFolioExe
		        AND   ID_TAREA      = @id_tarea)
     BEGIN
       SET  @b_error_int  =  @k_falso
       EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @id_tarea, @k_error, @pError, @pMsgError
       RETURN
     END
   END
   ELSE
   BEGIN
     IF  @pValPeriodo  =  @k_verdadero
     BEGIN
	   SET  @b_error_int  =  @k_falso
-------------------------------------------------------------------------
/*  Valida información relacionado con el periodo                      */
------------------------------------------------------------------------- 
	   EXEC  spValidaPeriodo  @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @id_tarea,
                              @pFolioExe, @b_error_int OUT, @pError OUT, @pMsgError OUT
     END
     IF  @b_error_int  =  @k_verdadero
     BEGIN
       SET  @pBError  =  @k_verdadero
       RETURN
     END
   END

-------------------------------------------------------------------------
/*  Ejecución de proceso  requerido en los parámetros                  */
------------------------------------------------------------------------- 
    SELECT @store_proc = STORE_PROCEDURE,
	       @base_datos = BASE_DATOS,
		   @owner      = OWNER
    FROM  FC_PROCESO
    WHERE CVE_EMPRESA  = @pCveEmpresa
    AND   ID_PROCESO   = @pIdProceso

   SET @sql = N'EXEC ' + LTRIM(@base_datos + @owner + @store_proc) +  
   N' @pIdCliente_p,@pCveEmpresa_p,@pCodigoUsuario_p,@pCveAplicacion_p,@pAnoPeriodo_p,@pIdProceso_p, @folio_exe_p, @id_tarea_p,
   @b_error_p OUTPUT, @error_p OUTPUT, @msg_error_p OUTPUT'
   SET @parametros =
   N'@pIdCliente_p int,@pCveEmpresa_p varchar(4),@pCodigoUsuario_p varchar(20),@pCveAplicacion_p varchar(10),@pAnoPeriodo_p varchar(6), 
   @pIdProceso_p numeric(9), @folio_exe_p int,@id_tarea_p numeric(9), 
   @b_error_p bit OUT, @error_p varchar(80) OUT,
   @msg_error_p varchar(400) OUT'
   EXEC sp_executesql
        @sql,
        @parametros,
        @pIdCliente_p     = @pIdCliente,
        @pCveEmpresa_p    = @pCveEmpresa,
        @pCodigoUsuario_p = @pCodigoUsuario,
        @pCveAplicacion_p = @pCveAplicacion,
        @pAnoPeriodo_p    = @pAnoPeriodo,
        @pIdProceso_p     = @pIdProceso,
        @folio_exe_p      = @pFolioExe OUT,
        @id_tarea_p       = @id_tarea,
        @b_error_p        = @pBError   OUT,
        @error_p          = @pError    OUT, 
        @msg_error_p      = @pMsgError OUT;

    IF  @pBError =  @k_verdadero
    BEGIN
      RETURN
    END

-------------------------------------------------------------------------
/*  Ejecución de registro de datos de término del proceso              */
------------------------------------------------------------------------- 

    EXEC  spRegFinProceso    @pIdCliente, @pCveEmpresa, @pCodigoUsuario, @pCveAplicacion, @pAnoPeriodo, @pIdProceso, @id_tarea,
                             @pFolioExe, @pHoraFin OUT, @pBError OUT, @pError OUT,  @pMsgError OUT 
						  
  END TRY

  BEGIN CATCH
    SET @pError    =  '(E) Lanzar Proceso;'
    SET @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
 
    IF EXISTS (SELECT 1
                FROM FC_TAREA
                WHERE CVE_EMPRESA = @pCveEmpresa
                  AND ID_PROCESO  = @pIdProceso
                  AND FOLIO_EXEC  = @pFolioExe
                  AND ID_TAREA    = @id_tarea)
    BEGIN
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @id_tarea, @k_error, @pError, @pMsgError
    END
	SET  @pBError  =  @k_verdadero
  END CATCH
END
GO