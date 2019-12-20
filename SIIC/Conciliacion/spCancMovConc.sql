USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCancMovConc')
BEGIN
  DROP  PROCEDURE spCancMovConc
END
GO

--EXEC spCancMovConc 'CU','MARIO','201903',135,1,'MDB437',' ',' '
CREATE PROCEDURE [dbo].[spCancMovConc]  
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pAnoPeriodo      varchar(6),
@pIdMovtoBancario int,
@pError           varchar(80)  OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @id_concilia_cxc   int,
		   @id_movto_bancario int,
		   @referencia        varchar(20)
   
  DECLARE  @k_no_concilia     varchar(2)  =  'NC'
  -------------------------------------------------------------------------------
  -- Definición de tabla de movimientos de facturas a des-conciliar
  -------------------------------------------------------------------------------

  DECLARE  @TFactMovBanc     TABLE
          (RowID             int  identity(1,1),
	       ID_CONCILIA_CXC   int)

  DECLARE  @TMovBancRef      TABLE
          (RowID             int  identity(1,1),
	       ID_MOVTO_BANCARIO int)

  -----------------------------------------------------------------------------------------------------
  -- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
  -----------------------------------------------------------------------------------------------------
  INSERT @TFactMovBanc  (ID_CONCILIA_CXC)
  SELECT f.ID_CONCILIA_CXC
  FROM   CI_CONCILIA_C_X_C cc, CI_FACTURA f
  WHERE  cc.ID_MOVTO_BANCARIO  =  @pIdMovtoBancario AND
         cc.ID_CONCILIA_CXC    =  f.ID_CONCILIA_CXC
 
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TFactMovBanc
  SET @RowCount     = 1
  BEGIN TRAN
  BEGIN TRY
  WHILE @RowCount <= @NunRegistros
  BEGIN

    SELECT @id_concilia_cxc  =  ID_CONCILIA_CXC
	FROM   @TFactMovBanc
	WHERE  RowID  =  @RowCount	

	UPDATE  CI_FACTURA  SET  SIT_CONCILIA_CXC  =  @k_no_concilia  WHERE ID_CONCILIA_CXC  =  @id_concilia_cxc

    SET @RowCount     =   @RowCount  +  1 
  END

  SET  @referencia = (SELECT  REFERENCIA  FROM  CI_MOVTO_BANCARIO  WHERE ID_MOVTO_BANCARIO = @pIdMovtoBancario) 

  IF  EXISTS (SELECT 1 FROM CI_BMX_ACUM_REF  WHERE  REFERENCIA =  @referencia)
  BEGIN
    INSERT @TMovBancRef (ID_MOVTO_BANCARIO)
    SELECT ID_MOVTO_BANCARIO
    FROM   CI_MOVTO_BANCARIO
    WHERE  REFERENCIA  =  @referencia
  END
  ELSE
  BEGIN
    INSERT @TMovBancRef (ID_MOVTO_BANCARIO) VALUES (@pIdMovtoBancario)
  END

  SET @NunRegistros =  (SELECT COUNT(*) FROM @TMovBancRef)
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TMovBancRef 
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_movto_bancario  =  ID_MOVTO_BANCARIO
	FROM   @TMovBancRef
	WHERE  RowID  =  @RowCount	
    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO  =  @k_no_concilia  WHERE ID_MOVTO_BANCARIO  =  @id_movto_bancario
    DELETE  FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO  =  @id_movto_bancario
    SET @RowCount     =   @RowCount  +  1 
  END
  	
  END TRY

  BEGIN CATCH
    IF  @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRAN
    END
 
    SET  @pError    =  'Error al Cancelar Conciliacion ' + ISNULL(ERROR_PROCEDURE(), ' ') + '-' 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' '))
  END CATCH
  
  IF @@TRANCOUNT > 0  
  COMMIT TRAN

END

