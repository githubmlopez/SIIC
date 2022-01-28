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

--EXEC spCancMovConc 1,'CU','MARIO','SIIC','201903',200,1,1,2919,0,' ',' '
CREATE PROCEDURE [dbo].[spCancMovConc]  
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pTipoMovto       varchar(4),
@pIdMovtoBancario int,
@pBError          bit,
@pError           varchar(80)  OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int,
		   @id_concilia       int,
		   @id_movto_bancario int,
		   @referencia        varchar(20)

  DECLARE  @k_error           varchar(1)
   
  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_cxc             varchar(4)  =  'CXC',
		   @k_cxp             varchar(4)  =  'CXP', 
           @k_verdadero       bit         =  1
  -------------------------------------------------------------------------------
  -- Definición de tabla de movimientos de facturas a des-conciliar
  -------------------------------------------------------------------------------

  DECLARE  @TFactMovBanc     TABLE
          (RowID             int  identity(1,1),
	       ID_CONCILIA       int)

  DECLARE  @TMovBancRef      TABLE
          (RowID             int  identity(1,1),
	       ID_MOVTO_BANCARIO int)

  -----------------------------------------------------------------------------------------------------
  -- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
  -----------------------------------------------------------------------------------------------------
  IF  @pTipoMovto  =  @k_cxc
  BEGIN
    INSERT @TFactMovBanc  (ID_CONCILIA)
    SELECT f.ID_CONCILIA_CXC
    FROM   CI_CONCILIA_C_X_C cc, CI_FACTURA f
    WHERE  cc.ID_MOVTO_BANCARIO  =  @pIdMovtoBancario AND
           cc.ID_CONCILIA_CXC    =  f.ID_CONCILIA_CXC
    SET @NunRegistros = @@ROWCOUNT
  END
  ELSE
  BEGIN
    INSERT @TFactMovBanc  (ID_CONCILIA)
    SELECT c.ID_CONCILIA_CXP
    FROM   CI_CONCILIA_C_X_P cc, CI_CUENTA_X_PAGAR c
    WHERE  cc.ID_MOVTO_BANCARIO  =  @pIdMovtoBancario AND
           cc.ID_CONCILIA_CXP    =  c.ID_CONCILIA_CXP
    SET @NunRegistros = @@ROWCOUNT
  END

-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TFactMovBanc

  SET @RowCount     = 1

  BEGIN TRAN

  BEGIN TRY
  -----------------------------------------------------------------------------------
  --  Ciclo para actualizar los movimientos de CXC o CXP para cambiar la situacion --
  -----------------------------------------------------------------------------------
  WHILE @RowCount <= @NunRegistros
  BEGIN

    SELECT @id_concilia  =  ID_CONCILIA
	FROM   @TFactMovBanc
	WHERE  RowID  =  @RowCount	

    IF  @pTipoMovto  =  @k_cxc
    BEGIN
      UPDATE  CI_FACTURA  SET  SIT_CONCILIA_CXC  =  @k_no_concilia  WHERE ID_CONCILIA_CXC  =  @id_concilia
    END
    ELSE
	BEGIN
      UPDATE  CI_CUENTA_X_PAGAR  SET  SIT_CONCILIA_CXP  =  @k_no_concilia  WHERE ID_CONCILIA_CXP  =  @id_concilia
 	END

    SET @RowCount     =   @RowCount  +  1 
  END

---------------------------------------------------------------
-- Se verifica si es un movimiento compuesto (referenciado)  --
---------------------------------------------------------------

  SET  @referencia = (SELECT  REF_EMP  FROM  CI_MOVTO_BANCARIO  WHERE ID_MOVTO_BANCARIO = @pIdMovtoBancario) 

  IF  EXISTS (SELECT 1 FROM CI_BMX_ACUM_REF  WHERE  REFERENCIA =  @referencia)
  BEGIN
    INSERT @TMovBancRef (ID_MOVTO_BANCARIO)
    SELECT ID_MOVTO_BANCARIO
    FROM   CI_MOVTO_BANCARIO
    WHERE  REF_EMP  =  @referencia
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

    IF  @pTipoMovto  =  @k_cxc
    BEGIN
      DELETE  FROM CI_CONCILIA_C_X_C  WHERE ID_MOVTO_BANCARIO  =  @id_movto_bancario
    END
	ELSE
	BEGIN
      DELETE  FROM CI_CONCILIA_C_X_P  WHERE ID_MOVTO_BANCARIO  =  @id_movto_bancario
	END
    SET @RowCount     =   @RowCount  +  1 
  END
  	
  END TRY

  BEGIN CATCH
    SET  @PError  =  @k_verdadero
    SET  @pError    =  '(E) Cancelacion de operaciones ' 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*') 
	EXECUTE spCreaTareaEventoB @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH
  
  IF  @@TRANCOUNT >= 1
  BEGIN
    IF  @pBError  =  1
	BEGIN
	  ROLLBACK TRAN
	END
	ELSE
	BEGIN
      COMMIT TRAN
	END
  END

END

