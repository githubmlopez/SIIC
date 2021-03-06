USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spActConcR]    Script Date: 29/01/2020 06:07:48 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spActConcRef 'CU','201906','MDB437','00021582',807,' ',' '
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcRef')
BEGIN
  DROP  PROCEDURE spActConcRef
END
GO
----------------------------------------------------------------------------------------------------------
-- Concilia movimientos bancarios por referencia, esta situación se da cuando una cuenta por cobrar     --
-- se concilia contra movimientos que traen una misma referencia. Los movimientos que traen una         --
-- misma referencia generalmente son los movimientos de chequeras como Banamex en el que un  movimiento --
-- bancario trae asociado un movimiento de comisió e IVA                                                --
----------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spActConcRef]  
@pCveEmpresa      varchar(4),
@pAnoPeriodo      varchar(6),
@pReferencia      varchar(20),
@pCveChequera     varchar(6),
@pIdConciliaCxC   int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_conciliado      varchar(2)  =  'CC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_cxc             varchar(3)  =  'CXC',
		   @k_normal          varchar(1)  =  'N',
		   @k_referencia      varchar(1)  =  'R'

  DECLARE  @ano_mes             varchar(6),
		   @cve_chequera        varchar(6),
		   @id_movto_bancario   int,
		   @id_concilia_cxc     int

-------------------------------------------------------------------------------
-- Definición de tabla de movimientos referenciados
-------------------------------------------------------------------------------

  DECLARE  @TMovBancario     TABLE
          (RowID             int  identity(1,1),
		   CVE_EMPRESA       varchar(4),
		   ANO_PERIODO       varchar(6),
		   ID_MOVTO_BANCARIO int,
		   CVE_CHEQUERA      varchar(6)
          )
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------

 INSERT @TMovBancario  (CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, CVE_CHEQUERA)  
  SELECT @pCveEmpresa, m.ANO_MES, m.ID_MOVTO_BANCARIO, m.CVE_CHEQUERA 
  FROM CI_MOVTO_BANCARIO m
  WHERE   m.CVE_EMPRESA        =  @pCveEmpresa     AND
          m.REFERENCIA         =  @pReferencia     AND
          m.CVE_CHEQUERA       =  @pCveChequera    AND
		  m.SIT_MOVTO         <>  @k_cancelado     

  SET @NunRegistros = @@ROWCOUNT

      ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Registros ' + CONVERT(VARCHAR(10), @NunRegistros ))   
        -------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_PERIODO,
	       @cve_chequera       =  CVE_CHEQUERA,
		   @id_movto_bancario  =  ID_MOVTO_BANCARIO
    FROM   @TMovBancario
	WHERE  RowID  =  @RowCount

	    ------------------------- LOG  ----------------------------------------
        INSERT INTO FC_LOG (TEXTO) VALUES ('Entro while Referencia' + CONVERT(VARCHAR(10),@id_movto_bancario) + ',' + CONVERT(VARCHAR(10),@pIdConciliaCxC))   
        -------------------------------------------------------------------------------------------------------------------
 

	INSERT INTO CI_CONCILIA_C_X_C
   (   
    CVE_EMPRESA,
	ID_MOVTO_BANCARIO,
    ID_CONCILIA_CXC,
    SIT_CONCILIA_CXC,
    TX_NOTA,
    ANOMES_PROCESO,
    IMP_PAGO_AJUST
   )
    VALUES
   ( 
    @pCveEmpresa,
	@id_movto_bancario,
	@pIdConciliaCxC,
	@k_conciliado,
	'PRUEBA2',
	@pAnoPeriodo,
  	0
   )


    SET    @RowCount = @RowCount + 1
  END

  UPDATE  CI_CUENTA_X_COBRAR  SET  SIT_CONCILIA_CXC =  @k_conciliado  WHERE  CVE_EMPRESA  =  @pCveEmpresa  AND
                                                                             ID_CONCILIA_CXC  =  @pIdConciliaCxC

END
