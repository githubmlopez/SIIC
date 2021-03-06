USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spActConcR]    Script Date: 29/01/2020 06:07:48 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spActConcPag 'CU','201903','MDB437','00021582',807,' ',' '
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spActConcPag')
BEGIN
  DROP  PROCEDURE spActConcPag
END
GO

CREATE PROCEDURE [dbo].[spActConcPag]  
@pCveEmpresa      varchar(4),
@pAnoPeriodo      varchar(6),
@pCveChequera     varchar(6),
@pIdMpvtoBancario int,
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
		   @k_cxp             varchar(3)  =  'CXP'

  DECLARE  @ano_mes             varchar(6),
		   @id_cxp              int

-------------------------------------------------------------------------------
-- Definición de tabla de movimientos referenciados
-------------------------------------------------------------------------------

  DECLARE  @TCuentaPagar     TABLE
          (RowID             int  identity(1,1),
		   CVE_EMPRESA       varchar(4),
		   ANO_PERIODO       varchar(6),
		   ID_CXP            int
          )
SELECT  'pag' + CONVERT(VARCHAR(8),@pIdPago)
SELeCT  'CH' + @pCveChequera		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TCuentaPagar  (CVE_EMPRESA, ANO_PERIODO, ID_CXP)  
  SELECT @pCveEmpresa, @pAnoPeriodo, c.ID_CXP  
  FROM CI_CUENTA_X_PAGAR c, CI_PAGO_CXP p
  WHERE   p.CVE_EMPRESA        =  @pCveEmpresa        AND
          p.ID_PAGO            =  @pIdPago            AND
          p.CVE_EMPRESA        =  c.CVE_EMPRESA       AND
          P.ID_CXP             =  c.ID_CXP            AND
		  c.SIT_C_X_P         <>  @k_cancelado     

  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SELECT * FROM @TCuentaPagar
  SET @RowCount     = 1
 
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @ano_mes            =  ANO_PERIODO,
	       @id_cxp             =  ID_CXP
    FROM   @TCuentaPagar
	WHERE  RowID  =  @RowCount

	IF NOT EXISTS (SELECT 1 FROM CI_CONCILIA_C_X_C WHERE ID_MOVTO_BANCARIO = @pIdMpvtoBancario  AND
	                                                     ID_CONCILIA_CXC   = @id_cxp)
    BEGIN
	  INSERT INTO CI_CONCILIA_C_X_P
     (   
      ID_MOVTO_BANCARIO,
      ID_CONCILIA_CXP,
      SIT_CONCILIA_CXP,
      TX_NOTA,
      ANOMES_PROCESO
     )
      VALUES
     ( 
	  @pIdMpvtoBancario,
	  @id_cxp,
	  @k_conciliado,
	  'PRUEBA ',
	  @pAnoPeriodo
     )
    END
    UPDATE  CI_MOVTO_BANCARIO  SET  SIT_CONCILIA_BANCO =  @k_conciliado  WHERE
                               ANO_MES  =  @pAnoPeriodo  AND  CVE_CHEQUERA = @pCveChequera  AND  ID_MOVTO_BANCARIO = @pIdMpvtoBancario  

    SET    @RowCount = @RowCount + 1
  END

  UPDATE  CI_CUENTA_X_PAGAR  SET  SIT_CONCILIA_CXP =  @k_conciliado  WHERE  CVE_EMPRESA = @pCveEmpresa  AND
                                                                            ID_CXP  =  @id_cxp

END
