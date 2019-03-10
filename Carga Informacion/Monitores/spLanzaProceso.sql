USE [CARGADOR]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM CARGADOR.sys.procedures WHERE Name =  'spLanzaProceso')
BEGIN
  DROP  PROCEDURE [dbo].[spLanzaProceso]
END
GO
-- exec spLanzaProceso 1,'MARIO',1,'CU','CARGAINF','CARGASAT','201811', spCargaFile,0,' ',' '
CREATE PROCEDURE [dbo].[spLanzaProceso]
(
@pIdProceso       numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveMonitor      varchar(10),
@pAnoPeriodo      varchar(6),
@pStoreProc       varchar(50),
@pIdTarea         numeric(9) OUT,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)

AS
BEGIN
--  select 'entro lanza tarea'
  DECLARE  @k_error      varchar(1) = 'E',
           @k_abierto    varchar(1) = 'A'

  DECLARE  @error        varchar(80),
           @msg_error    varchar(400),
		   @id_tarea     numeric(9),
		   @sql          nvarchar(max),
		   @parametros   nvarchar(max),
		   @sit_periodo  varchar(1)
 
  SET      @error      =  ' '
  SET      @msg_error  =  ' '
  SET      @id_tarea   =  0

  EXEC  spCreaTarea
  @pIdProceso,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCodigoUsuario,
  @pAnoPeriodo,
  @id_tarea OUT, 
  @error OUT,
  @msg_error OUT
  
  SET @sql = N'EXEC ' + @pStoreProc +  
 N' @IdProceso_p,'     +
  '@id_tarea_p,'      +
  '@CodigoUsuario_p,' +
  '@IdCliente_p,'      +
  '@CveEmpresa_p,'    +
  '@CveAplicacion_p,'   +
  '@AnoPeriodo_p,'    +
  '@error_p OUTPUT,'  +
  '@msg_error_p OUTPUT'    

  SET @parametros =
 N'@IdProceso_p numeric(9),'      +
  '@id_tarea_p numeric(9),'       +
  '@CodigoUsuario_p varchar(20),' +
  '@IdCliente_p int,'              +
  '@CveEmpresa_p varchar(4),'     +
  '@CveAplicacion_p varchar(10),'    +
  '@AnoPeriodo_p varchar(6),'     +
  '@error_p varchar(80) OUT,'     +
  '@msg_error_p varchar(400) OUT'

--   SELECT ' sql==> ' + @sql

  EXEC sp_executesql @sql, @parametros,
  @IdProceso_p     = @pIdProceso,
  @id_tarea_p      = @id_tarea,
  @CodigoUsuario_p = @pCodigoUsuario,
  @IdCliente_p     = @pIdCliente,
  @CveEmpresa_p    = @pCveEmpresa,
  @CveAplicacion_p = @pCveAplicacion,
  @AnoPeriodo_p    = @pAnoPeriodo,
  @error_p         = @error OUTPUT, 
  @msg_error_p     = @msg_error OUTPUT;

  EXEC  spActPctTarea 
  @pIdProceso,
  @id_tarea,
  @pIdCliente,
  @pCveEmpresa,
  @pCveAplicacion,
  @pCodigoUsuario,
  100,
  @pError OUT,
  @pMsgError OUT 

  UPDATE FC_GEN_TAREA  SET HORA_FINAL =  CONVERT(varchar(10), GETDATE(), 108)  WHERE
         ID_CLIENTE     =  @pIdCliente     AND
		 CVE_EMPRESA    =  @pCveEmpresa    AND
		 CVE_APLICACION =  @pCveAplicacion AND
		 ID_PROCESO     =  @pIdProceso     AND
		 ID_TAREA       =  @id_tarea

--    SELECT 'ERROR *' + @error
--    SELECT 'MSG *' + @msg_error
END

