USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spVerCondProc')
BEGIN
  DROP  PROCEDURE spVerCondProc
END
GO

--------------------------------------------------------------------------------------------
-- Verifica si los procesos a los que está condicionada la ejecución del proceso fueron   --
-- Ejecurados con exito.                                                                  --
--------------------------------------------------------------------------------------------

-- EXEC  spVerCondProc 'EGG', 1, 'MARIO', 'PASOS', 1,1, '202109', 1002, 0, ' ',' '

CREATE PROCEDURE [dbo].[spVerCondProc]  
@pCveEmpresa    varchar(4),
@pIdCliente     int,
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pIdEtapa       int,
@pIdPaso        int,
@pPeriodo       varchar(8),
@pIdProceso     numeric(9),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  DECLARE @NumRegistros  int,
          @RowCount      int, 
		  @IdProcCond    numeric(9),
		  @id_tarea      numeric(9),
		  @folio_exe     int,
		  @hora_inicio   varchar(10) = ' ',
		  @hora_fin      varchar(10) = ' ',
		  @sit_proceso   varchar(2),
		  @b_error       bit,
		  @error         varchar(80)

  DECLARE @k_verdadero   bit = 1,
          @k_falso       bit = 0,
		  @k_error       varchar(2)  =  'ER',
		  @k_correcto    varchar(2)  =  'CO',
		  @k_pendiente   varchar(2)  =  'PE'

  SET  @b_error =  @k_falso

  DECLARE @TvProceso  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  ID_PROC_COND    numeric(9)
 )

  INSERT @TvProceso (ID_PROC_COND)
  SELECT ID_PROC_COND FROM FC_PASO_PROC_COND  WHERE 
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_ETAPA     =  @pIdEtapa     AND
  ID_PASO      =  @pIdPaso      AND
  ID_PROCESO   =  @pIdProceso

  SET @NumRegistros = (SELECT COUNT(*) FROM @TvProceso)
-----------------------------------------------------------------------------------------------------
--  SELECT * FROM @TvProceso

  SET @RowCount     = 1

  SET  @sit_proceso = @k_correcto

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT  @IdProcCond = ID_PROC_COND  FROM  @TvProceso  WHERE  RowID  =  @RowCount

	SET  @b_error     =  @k_falso

    EXEC spObtSitProcExe  
    @pCveEmpresa,
    @pIdEtapa,
    @pIdPaso,
    @pPeriodo,
    @IdProcCond,
    @sit_proceso  OUT,
    @b_error      OUT,
    @error        OUT,
    @pMsgError    OUT

    IF  @sit_proceso  =  @k_pendiente
	BEGIN
	  SET  @b_error = @k_verdadero
	  SET  @error = 'No existen procesos ejecutados para el proceso ' + CONVERT(varchar(10), @IdProcCond)
	END
	ELSE
	BEGIN
	  IF   @sit_proceso  =  @k_error
      BEGIN
		SET  @b_error  =  @k_verdadero
		SET  @error   =  'El proceso dependiente ' + CONVERT(varchar(10), @IdProcCond) + 'no se ha ejecutado correctamente'
	  END
      ELSE
	  BEGIN
	    SET  @b_error  =  @k_falso
	  END
	END

	IF  @b_error  =  @k_verdadero
	BEGIN
    
	BEGIN TRY
	  EXEC spCreaInstancia
      @pIdCliente,
      @pCveEmpresa,
      @pCodigoUsuario,
      @pCveAplicacion,
      @pPeriodo,
      @pIdProceso,
      @id_tarea      OUT,
      @folio_exe     OUT,
      @k_falso,
      @hora_inicio   OUT,
      @hora_fin      OUT,
      @pBError       OUT,
      @pError        OUT,
      @pMsgError     OUT	

	  EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @folio_exe, @id_tarea, @k_error, @error, @error
	  
	  EXEC spCreaProcExePaso
	  @pCveEmpresa,
      @pIdEtapa,
      @pIdPaso,
      @pPeriodo,
      @pIdProceso,
      @folio_exe,     
      @k_error,
      @pBError       OUT,
      @pError        OUT,
      @pMsgError     OUT

	  SET  @pBError  =  @k_verdadero
	  SET  @pError   =  @error
	  SET  @RowCount =  @NumRegistros

	END TRY
 
	BEGIN CATCH
	  SET  @pBError  =  @k_verdadero
	  SET  @pError   =  'Error al obtener verificación ' + CONVERT(varchar(9),@IdProcCond)
	  SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
	  SET  @RowCount =  @NumRegistros
	END CATCH

	END
    
	SET @RowCount     =  @RowCount + 1
  END
END