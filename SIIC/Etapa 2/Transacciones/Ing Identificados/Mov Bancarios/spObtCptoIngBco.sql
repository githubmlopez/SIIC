USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC spObtCptoIngBco 2075
ALTER PROCEDURE [dbo].[spObtCptoIngBco] (@pIdMovtoBancario numeric(9,0), @pConcepto varchar(50) OUT)
AS
BEGIN
  DECLARE @NunRegistros    int, 
          @RowCount        int,
		  @id_concilia_cxc numeric(9,0)

  DECLARE  @TFactIngBco  TABLE
  (RowID           int  identity(1,1),
  ID_CONCILIA_CXC   numeric(9,0) NOT NULL)

  INSERT  @TFactIngBco  (ID_CONCILIA_CXC )
  SELECT  f.ID_CONCILIA_CXC
  FROM    CI_MOVTO_BANCARIO m, CI_CONCILIA_C_X_C cc, CI_FACTURA f
  WHERE   m.ID_MOVTO_BANCARIO  =  @pIdMovtoBancario         AND
          m.ID_MOVTO_BANCARIO  =  cc.ID_MOVTO_BANCARIO  AND
		  cc.ID_CONCILIA_CXC   =  f.ID_CONCILIA_CXC

  SET @NunRegistros = @@ROWCOUNT
  SET @RowCount     = 1
  SET @pConcepto    = ' '
  
  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_concilia_cxc  =  ID_CONCILIA_CXC
    FROM   @TFactIngBco
    WHERE  RowID = @RowCount
    SELECT  @pConcepto = LTRIM(@pConcepto + 
   (SELECT  f.SERIE + CONVERT(varchar(10), f.ID_CXC)  FROM CI_FACTURA f WHERE f.ID_CONCILIA_CXC = @id_concilia_cxc))
    SET  @RowCount =  @RowCount + 1
  END
--  SELECT @concepto
END

