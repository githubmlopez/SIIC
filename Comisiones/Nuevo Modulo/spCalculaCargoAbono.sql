USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spCalculaComision]    Script Date: 01/10/2016 12:08:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCalculaCargoAbono')
DROP PROCEDURE [dbo].[spCalculaCargoAbono]
GO

--EXEC spCalculaCargoAbono 'CU', '202010'
CREATE PROCEDURE [dbo].[spCalculaCargoAbono]
(
@pCveEmpresa     varchar(4),
@pAnoPeriodo     varchar(6)
) 
AS
BEGIN

  DECLARE  @k_verdadero       bit        =  1,
           @k_falso           bit        =  0,
		   @k_legado          varchar(6) = 'LEGACY',
		   @k_activo          varchar(2) = 'A',   
           @k_abono           varchar(1) = 'A'

  DECLARE  @serie             varchar(6),
           @id_cxc            int,
           @id_concilia_cxc   int

  DECLARE  @NunRegistros      int = 0, 
		   @RowCount          int = 0
		   
  DECLARE @TFactura  TABLE 
 (
  RowID                     int IDENTITY(1,1),   
  SERIE                     varchar(6),
  ID_CXC                    int,
  ID_CONCILIA_CXC           int
 )        

    
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT INTO  @TFactura
  SELECT f.SERIE, f.ID_CXC, ID_CONCILIA_CXC
  FROM   CI_FACTURA f
  WHERE   
--   Verifica que no sea una factura legada                                                   
  f.CVE_EMPRESA  =  @pCveEmpresa                                           AND
  f.SERIE <> @k_legado                                                     AND 
--   Verifica que la factura este activa                                                   
  f.SIT_TRANSACCION  = @k_activo                                           AND
--   Verifica que cuando menos tenga un pago y se haya hecho en el periodo                                                   
  EXISTS(SELECT 1 FROM CI_CONCILIA_C_X_C c WHERE   
  c.ID_CONCILIA_CXC = f.ID_CONCILIA_CXC                                    AND
  c.ANOMES_PROCESO  = @pAnoPeriodo)                                        -- AND
--  f.ID_CONCILIA_CXC = 1114 
  SET @NunRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------

  SET @RowCount = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
 
    SELECT
	@serie            =  SERIE,
	@id_cxc           =  ID_CXC,
	@id_concilia_cxc  =  ID_CONCILIA_CXC
	FROM   @TFactura WHERE  RowID = @RowCount

    INSERT INTO VTA_FACT_PAGO (ANO_MES, CVE_EMPRESA, SERIE, ID_CXC, ID_MOVTO_BANCARIO, CVE_CARGO_ABONO,
                               IMP_TRANSACCION,TX_NOTA)  
    SELECT @pAnoPeriodo, @pCveEmpresa, @serie, @id_cxc, m.ID_MOVTO_BANCARIO, m.CVE_CARGO_ABONO,
                         ISNULL(IMP_PAGO_AJUST,0), ' '  
    FROM   CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m
    WHERE
    c.ID_CONCILIA_CXC   =  @id_concilia_cxc     AND
    c.ANOMES_PROCESO    =  @pAnoPeriodo         AND
    c.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND     
    m.CVE_CARGO_ABONO   =  @k_abono             
 
    INSERT INTO VTA_FACT_PAGO (ANO_MES, CVE_EMPRESA, SERIE, ID_CXC, ID_MOVTO_BANCARIO, CVE_CARGO_ABONO,
                               IMP_TRANSACCION,TX_NOTA)  
    SELECT @pAnoPeriodo, @pCveEmpresa, @serie, @id_cxc, m.ID_MOVTO_BANCARIO, m.CVE_CARGO_ABONO,
                         ISNULL(m.IMP_TRANSACCION,0), ' '  
    FROM   CI_CONCILIA_C_X_C c, CI_MOVTO_BANCARIO m
    WHERE
    c.ID_CONCILIA_CXC   =  @id_concilia_cxc      AND
    c.ANOMES_PROCESO    =  @pAnoPeriodo         AND
    c.ID_MOVTO_BANCARIO =  m.ID_MOVTO_BANCARIO  AND     
    m.CVE_CARGO_ABONO   <> @k_abono

  SET @RowCount  =  @RowCount  +  1 

  END 

END