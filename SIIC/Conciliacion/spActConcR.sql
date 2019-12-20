USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcP')
BEGIN
  DROP  PROCEDURE spActConcP
END
GO

--EXEC spActConcR 'CU','201903','MDB437','00021582',807,' ',' '
CREATE PROCEDURE [dbo].[spActConcP]  
@pCveEmpresa      varchar(4),
@pAnoPeriodo      varchar(6),
@pCveChequera     varchar(6),
@pIdMovtoBancario int,
@pIdPago          int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
AS
BEGIN
  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @k_no_concilia     varchar(2)  =  'NC',
           @k_conciliado      varchar(2)  =  'CC',
           @k_cancelado       varchar(2)  =  'CA',
		   @k_cxp             varchar(3)  =  'CXP',
		   @k_normal          varchar(1)  =  'N',
		   @k_pago            varchar(1)  =  'P'


  DECLARE  @ano_mes             varchar(6),
		   @cve_chequera        varchar(6),
		   @id_concilia_cxp     int,
		   @id_pago             int

-------------------------------------------------------------------------------
-- Definición de tabla de movimientos referenciados
-------------------------------------------------------------------------------

  DECLARE  @TMovCxp          TABLE
          (RowID             int  identity(1,1),
		   CVE_EMPRESA       varchar(4),
		   ANO_PERIODO       varchar(6),
		   ID_CONCILIA_CXP           int
          )
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TMovCxp  (CVE_EMPRESA, ANO_PERIODO, ID_CONCILIA_CXP)  
  SELECT @pCveEmpresa, @pAnoPeriodo, p.ID_CXP 
  FROM CI_PAGO_CXP p, CI_CUENTA_X_PAGAR c
  WHERE   p.CVE_EMPRESA =  @pCveEmpresa  AND
		  p.ID_PAGO     =  @pIdPago      AND
		  p.CVE_EMPRESA =  c.CVE_EMPRESA AND
		  p.ID_CXP      =  c.ID_CONCILIA_CXP

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TMovCxp
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_PERIODO,
		   @id_concilia_cxp    =  ID_CONCILIA_CXP
    FROM   @TMovCxp
	WHERE  RowID  =  @RowCount

	INSERT INTO CI_CONCILIA_C_X_C
   (   
    ID_MOVTO_BANCARIO,
    ID_CONCILIA_CXC,
    SIT_CONCILIA_CXC,
    TX_NOTA,
    ANOMES_PROCESO,
    IMP_PAGO_AJUST
   )
    VALUES
   ( 
	@pIdMovtoBancario,
	@id_concilia_cxp,
	@k_conciliado,
	'PRUEBA2',
	@pAnoPeriodo,
  	0
   )

    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
                               ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @cve_chequera  AND  ID_MOVTO_BANCARIO = @pIdMovtoBancario  

    SET    @RowCount = @RowCount + 1
  END

  UPDATE  CI_CUENTA_X_PAGAR  SET  SIT_CONCILIA_CXP =  @k_conciliado  WHERE
                      ID_CONCILIA_CXP  =  @id_concilia_cxp

END
