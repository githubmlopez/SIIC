USE [ADMON01]
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--DROP PROCEDURE spCreaTransaccionCont
ALTER PROCEDURE spCreaTransaccionCont  
   @pIdProceso          NUMERIC(9),
   @pIdTarea            NUMERIC(9),
   @pIdTransaccion      NUMERIC(9),
   @pCveUsuario         varchar(20),	
   @pCveEmpresa         varchar(4),
   @pAnoMes             varchar(6),
   @pCveOperCont        varchar(4),
   @pFOperacion         date,
   @pIdentTransac       varchar(50),
   @pNomTitular         varchar(120),
   @pTxNota             varchar(250),
   @pGpoTransaccion     int,
   @pError              varchar(100) OUT,
   @pMsgError           varchar(400) OUT

AS
BEGIN

--SELECT   '@pIdProceso ' + CONVERT(VARCHAR(10),@pIdProceso) 
--SELECT   '@pIdTarea ' + CONVERT(VARCHAR(10),@pIdTarea) 

--SELECT   '@pCveEmpresa ' + @pCveEmpresa
--SELECT   '@pAnoMes '  + @pAnoMes
--SELECT   '@pIdTransaccion' + CONVERT(VARCHAR(10),@pIdTransaccion)
--SELECT   '@pCveOperacion ' + @pCveOperCont
--SELECT   '@pFOperacion '  + LEFT(CONVERT(VARCHAR, @pFOperacion, 120), 10)
--SELECT   '@pIdentTransac ' + @pIdentTransac
--SELECT   '@pNomTitular' + @pNomTitular
--SELECT   '@pGpoTransaccion' + CONVERT(VARCHAR(10),@pGpoTransaccion)	
--SELECT   '@pCveUsuario' + @pCveUsuario
--SELECT   '@pTxNota' + @pTxNota            

--SELECT   '@pError '  +  @pError     
--SELECT   '@pMsgError '  + @pMsgError


  DECLARE
   @k_falso             bit,
   @k_activa            varchar(1),
   @k_tran_contable     varchar(4),
   @k_nom_procedure     varchar(50),
   @k_inc_pct           int,
   @k_error             varchar(1)

  SET  @k_falso         =  0
  SET  @k_activa        =  'A'
  SET  @k_tran_contable =  'TRAC'
  SET  @k_nom_procedure =  'spCreaTransaccionCont'
  SET  @pMsgError       =  ' '
  SET  @k_inc_pct       =  1
  SET  @k_error         =  'E'
      
  
--  SELECT 'FOLIO TRAN ' + CONVERT(VARCHAR(10), @pIdTransaccion)
--  SELECT ' Entro a Store crear transaccion '

 BEGIN TRY
--    SELECT ' **VOY A CREAR TRANSACCION '
    INSERT  INTO CI_TRANSACCION_CONT
   (CVE_EMPRESA,
    ANO_MES,
    ID_TRANSACCION,
    CVE_OPER_CONT,
    F_OPERACION,
	IDENT_TRANSAC,
	NOM_TITULAR,
    GPO_TRANSACCION,
    CVE_USUARIO,
	F_REGISTRO,
	B_PROCESADA,
    TX_NOTA,
	SIT_TRANSACCION)  VALUES 
   (@pCveEmpresa,
    @pAnoMes,
    @pIdTransaccion,  
    @pCveOperCont,
    @pFOperacion,
	@pIdentTransac,
	@pNomTitular,
    @pGpoTransaccion,
	@pCveUsuario,
	GETDATE(),
	@k_falso,
	@pTxNota,
	@k_activa)

 --   select ' insert correcto ****** '

	EXEC spActCifControl  
         @pIdProceso,
         @pIdTarea,
         @pCveOperCont,
         @pCveEmpresa,
	     @pIdTransaccion,
         @pAnoMes,
	     @pError OUT,
         @pMsgError OUT
    
  END TRY 
 
  BEGIN CATCH
    IF (SELECT CURSOR_STATUS('global','cur_transaccion'))  =  1 
	BEGIN
	  CLOSE cur_transaccion
      DEALLOCATE cur_transaccion
    END

    SET  @pError    =  'Error al insertar Insetar registro de Transaccion'
	SET  @pMsgError =  @pError + '==> ' + ISNULL(ERROR_MESSAGE(), ' ')
    SELECT ' ERROR **** ' + @pMsgError
	EXECUTE spCreaTareaEvento @pCveEmpresa, @pIdProceso, @pIdTarea, @k_error, @pError, @pMsgError
  END CATCH;

END

 
