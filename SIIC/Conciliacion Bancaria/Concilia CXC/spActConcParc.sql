USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spActConcR]    Script Date: 29/01/2020 06:07:48 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spActConcParc 'CU','201903','MDB437','00021582',807,' ',' '
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcParc')
BEGIN
  DROP  PROCEDURE spActConcParc
END
GO

CREATE PROCEDURE [dbo].[spActConcParc]  
@pCveEmpresa      varchar(4),
@pAnoPeriodo      varchar(6),
@pIdAnticipo      int,
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
		   @k_cxc             varchar(3)  =  'CXC'

  DECLARE  @ano_mes             varchar(6),
		   @id_movto_bancario   int,
		   @referencia          varchar(50)

-------------------------------------------------------------------------------
-- Definición de tabla de movimientos pagos
-------------------------------------------------------------------------------

  DECLARE  @TMovBancario     TABLE
          (RowID             int  identity(1,1),
		   CVE_EMPRESA       varchar(4),
		   ANO_PERIODO       varchar(6),
		   ID_MOVTO_BANCARIO int,
		   CVE_CHEQUERA      varchar(6))

   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TMovBancario  (CVE_EMPRESA, ANO_PERIODO, ID_MOVTO_BANCARIO, CVE_CHEQUERA)  
  SELECT @pCveEmpresa, am.ANO_MES_APLIC, am.ID_MOVTO_BANCARIO, am.CVE_CHEQUERA  
  FROM   CI_ANTICIPO a, CI_ANTICIPO_MOVTO am
  WHERE  a.CVE_EMPRESA        =  @pCveEmpresa     AND
		 a.CVE_TIPO_ANT       =  @k_cxc           AND
         a.ID_ANTICIPO        =  @pIdAnticipo     AND
         a.CVE_EMPRESA        =  am.CVE_EMPRESA   AND
         a.ID_ANTICIPO        =  am.ID_ANTICIPO   AND
		 a.CVE_TIPO_ANT       =  am.CVE_TIPO_ANT  


  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_PERIODO,
	       @id_movto_bancario  =  ID_MOVTO_BANCARIO
    FROM   @TMovBancario
	WHERE  RowID  =  @RowCount

	IF  EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO  WHERE  CVE_EMPRESA          = @pCveEmpresa        AND
	                                                     ID_MOVTO_BANCARIO    = @id_movto_bancario  AND
	                                                     CVE_TIPO_MOVTO       = @k_cxc              AND
														 ISNULL(REFERENCIA,' ') <> ' ')
    BEGIN
      SET  @referencia = (SELECT Top(1) REF_EMP  FROM  CI_MOVTO_BANCARIO  WHERE  CVE_EMPRESA          = @pCveEmpresa        AND
	                                                                             ID_MOVTO_BANCARIO    = @id_movto_bancario  AND
	                                                                             CVE_TIPO_MOVTO       = @k_cxc              AND
							     							                     ISNULL(REFERENCIA,' ') <> ' ')
      EXEC spActConcRef   
           @pCveEmpresa,
           @pAnoPeriodo,
           @referencia,
           @pCveChequera,
           @pIdConciliaCxC,
           @pError OUT,
           @pMsgError OUT
	END
    ELSE
	BEGIN
	  IF NOT EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_C WHERE CVE_EMPRESA       = @pCveEmpresa        AND
	                                                       ID_MOVTO_BANCARIO = @id_movto_bancario  AND
	                                                       ID_CONCILIA_CXC   = @pIdConciliaCxC)
      BEGIN
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
	    'PRUEBA ',
	    @pAnoPeriodo,
	    0
       )
      END

    END
    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
	                           CVE_EMPRESA  =  @pCveEmpresa  AND 
                               ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @pCveChequera  AND  ID_MOVTO_BANCARIO = @id_movto_bancario  

    SET    @RowCount = @RowCount + 1
  END

  UPDATE  CI_CUENTA_X_COBRAR  SET  SIT_CONCILIA_CXC =  @k_conciliado  WHERE  CVE_EMPRESA      = @pCveEmpresa  AND
                                                                     ID_CONCILIA_CXC  =  @pIdConciliaCxC

END
