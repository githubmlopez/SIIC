		USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spRegConcilia')
BEGIN
  DROP  PROCEDURE spRegConcilia
END
GO

--EXEC spActConcilia 'CU','MARIO','201903',135,1,'MDB437',' ',' '
CREATE PROCEDURE [dbo].[spRegConcilia]  
(
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCodigoUsuario   varchar(20),
@pCveAplicacion   varchar(10),
@pAnoPeriodo      varchar(8),
@pIdProceso       numeric(9),
@pFolioExe        int,
@pIdTarea         numeric(9),
@pIdMovtoBancario int,
@pIdConciliaCxc   int,
@pBError          bit,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE
  @sit_concilia_cxc  varchar(2),
  @tx_nota           varchar(200)

  DECLARE
  @b_reg_correcto   bit,
  @f_operacion      date,
  @cve_chequera     varchar(6),
  @cve_mon_movto    varchar(1),
  @ano_mes          varchar(4),
  @sit_transaccion  varchar(2),
  @firma            varchar(10),
  @imp_movto        numeric(12,2),
  @tx_error         varchar(300),
  @tx_error_part    varchar(300),
  @tx_error_rise    varchar(300),
  @fol_audit        int,
  @ano_mes_con      varchar(6)

  DECLARE
  @RowCount         int,
  @NunRegistros     int,
  @tipo_error       varchar(1)

  DECLARE
  @k_verdadero     bit        = 1,
  @k_falso         bit        = 0,
  @k_activa        varchar(1) = 'A', 
  @k_cancelada     varchar(1) = 'C',
  @k_error         varchar(1) = 'E',
  @k_peso         varchar(1)  = 'P',
  @k_fol_audit     varchar(4),
  @k_fol_concilia  varchar(4)  

  DECLARE  @TvpError TABLE
  (
    RowID int IDENTITY(1,1) NOT NULL,
    TIPO_ERROR VARCHAR(1),
    ERROR VARCHAR(80),
    MSG_ERROR varchar (400)
  )

  SET  @k_fol_audit     = 'AUDI'
  SET  @k_fol_concilia  = 'MPRO'
    
  SET  @b_reg_correcto =  @k_verdadero;
  SET  @tx_error_part  =  ' ';

  SET  @sit_transaccion   =  @k_activa
  SET  @b_reg_correcto    =  @k_verdadero

  IF  NOT EXISTS (SELECT 1 FROM CI_CUENTA_X_COBRAR WHERE  CVE_EMPRESA = @pCveEmpresa AND ID_CONCILIA_CXC =  @pIdConciliaCxc) 
  BEGIN
    SET  @pError    =  '(E) No existe la factura a conciliar ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET  @pBError  =  @k_verdadero
  END 
  ELSE
  BEGIN
    SELECT @sit_transaccion = SIT_TRANSACCION  FROM CI_CUENTA_X_COBRAR                  
      WHERE  CVE_EMPRESA = @pCveEmpresa AND ID_CONCILIA_CXC =  @pIdConciliaCxc
                                                                                                                           
    IF  @sit_transaccion = @k_cancelada
    BEGIN
      SET  @pError    =  '(E) La factura esta cancelada ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
      SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
      EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
      SET  @pBError  =  @k_verdadero
    END
    ELSE
    BEGIN
      IF  NOT EXISTS (SELECT 1 FROM CI_MOVTO_BANCARIO  WHERE  CVE_EMPRESA = @pCveEmpresa AND ID_MOVTO_BANCARIO  =  @pIdMovtoBancario)
      BEGIN
        SET  @pError    =  '(E) No existe el movimiento bancario ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
        SET  @pBError  =  @k_verdadero
      END
      ELSE
      BEGIN

        SELECT @f_operacion = F_OPERACION, @cve_chequera = CVE_CHEQUERA FROM CI_MOVTO_BANCARIO  WHERE  
                              CVE_EMPRESA = @pCveEmpresa AND ID_MOVTO_BANCARIO  =  @pIdMovtoBancario

        SELECT @cve_mon_movto  = CVE_MONEDA  FROM   CI_CHEQUERA  WHERE
		      CVE_EMPRESA = @pCveEmpresa AND CVE_CHEQUERA  =  @cve_chequera

        IF  EXISTS (SELECT 1 FROM  CI_CHEQUERA ch, CI_MOVTO_BANCARIO mo, dbo.CI_CONCILIA_C_X_C c
		                           WHERE    c.ID_CONCILIA_CXC     =  @pIdConciliaCxc     AND
									        c.ID_MOVTO_BANCARIO   =  mo.ID_MOVTO_BANCARIO AND
                                            mo.CVE_CHEQUERA       =  ch.CVE_CHEQUERA      AND
                                            ch.CVE_MONEDA        <>  @cve_mon_movto)
        BEGIN
          SET  @pError    =  '(E) Existen pagos en una moneda diferente ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
          SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
          EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
          SET  @pBError  =  @k_verdadero
        END
        ELSE
        BEGIN
          IF @cve_mon_movto <> @k_peso and (NOT EXISTS
		 (SELECT 1 FROM CI_TIPO_CAMBIO WHERE CVE_EMPRESA = @pCveEmpresa  AND 
		  CVE_MONEDA =  @cve_mon_movto AND F_OPERACION = @f_operacion))
          BEGIN
            SET  @pError    =  '(E) No existe tipo de cambio para la moneda ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
            SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
            EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
            SET  @pBError  =  @k_verdadero
          END
          ELSE
          BEGIN
            IF  EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO mo, dbo.CI_CONCILIA_C_X_C c
		                         WHERE c.ID_CONCILIA_CXC     =   @pIdConciliaCxc     AND
			                     c.ID_MOVTO_BANCARIO   =   mo.ID_MOVTO_BANCARIO AND
                                 mo.CVE_CHEQUERA       <>  @cve_chequera)
            BEGIN                                                                        
              SET  @pError    =  '(E) Los movimientos ya existen conciliados ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
              SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
              EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
              SET  @pBError  =  @k_verdadero
            END
          END  
        END
      END
    END
  END

  SET  @ano_mes_con  =
  ISNULL(CONVERT(varchar(6),(select NUM_FOLIO from CI_FOLIO WHERE CVE_FOLIO = @k_fol_concilia)),' ') 
  
  IF  @ano_mes_con   = ' '
  BEGIN
    SET  @pError    =  '(E) No existe folio de cierre de conciliacion ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
    SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET  @pBError  =  @k_verdadero
  END
    
  IF  @b_reg_correcto  =  @k_verdadero
  BEGIN

    BEGIN TRAN
	
	BEGIN TRY

    INSERT INTO CI_CONCILIA_C_X_C (CVE_EMPRESA,ID_MOVTO_BANCARIO,ID_CONCILIA_CXC,SIT_CONCILIA_CXC,ANOMES_PROCESO,TX_NOTA) 
           VALUES(
                  @pCveEmpresa,
                  @pIdMovtoBancario,
                  @pIdConciliaCxc,         
                  @sit_concilia_cxc,
                  @ano_mes_con,        
                  @tx_nota)  
        
    END TRY 

    BEGIN CATCH	
        SET  @pError    =  '(E) No fue posible realizar la insercion ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError (TIPO_ERROR, ERROR, MSG_ERROR)  VALUES
		(@k_error, @pError, @pMsgError) 
        SET  @pBError  =  @k_verdadero
    END CATCH;

    
    BEGIN TRY

      UPDATE CI_CUENTA_X_COBRAR SET SIT_CONCILIA_CXC =  @sit_concilia_cxc
	  WHERE  
      CVE_EMPRESA      = @pCveEmpresa      AND
	  ID_CONCILIA_CXC  =  @pIdConciliaCxc            

    END TRY
 
    BEGIN CATCH
        SET  @pError    =  '(E) No fue posible actualizar la cuenta por cobrar ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError (TIPO_ERROR, ERROR, MSG_ERROR)  VALUES
		(@k_error, @pError, @pMsgError) 
        SET  @pBError  =  @k_verdadero
    END CATCH;
 

    BEGIN TRY
      UPDATE CI_MOVTO_BANCARIO SET SIT_CONCILIA_BANCO =  @sit_concilia_cxc  WHERE                            
                               CVE_EMPRESA      = @pCveEmpresa      AND
                               ID_MOVTO_BANCARIO  =  @pIdMovtoBancario            
    END TRY
    
    BEGIN CATCH
        SET  @pError    =  '(E) No fue posible actualizar el movimiento bancario ' +  ISNULL(ERROR_PROCEDURE(), ' ') 
        SET  @pMsgError =  @pError +  ISNULL(SUBSTRING(ERROR_MESSAGE(),1,320),'*')
        INSERT INTO @TvpError (TIPO_ERROR, ERROR, MSG_ERROR)  VALUES
		(@k_error, @pError, @pMsgError) 
        SET  @pBError  =  @k_verdadero
    END CATCH;

    IF  @@TRANCOUNT > 0
    BEGIN
      IF  @pBError  =  @k_verdadero
	  BEGIN
        ROLLBACK TRAN
      END
	  ELSE
	  BEGIN
       COMMIT TRAN
      END
    END

  SET @NunRegistros = (SELECT COUNT(*)
  FROM @TvpError )

  IF  @NunRegistros >  0
  BEGIN
    SET  @pBError  =  @k_verdadero
  END
 
  SET @RowCount =  1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @tipo_error = TIPO_ERROR, @pError = ERROR, @pMsgError = MSG_ERROR
    FROM @TvpError
    WHERE  RowID = @RowCount
    EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pFolioExe, @pIdTarea, @k_error, @pError, @pMsgError
    SET @RowCount =  @RowCount  +  1
  END
  END
END 