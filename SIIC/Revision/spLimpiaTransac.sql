USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

ALTER PROCEDURE spLimpiaTransac  @pCveEmpresa varchar(4), @pAnoMes  varchar(6), @pIdProceso numeric(9),
                                  @pNomTabla varchar(30), @pNomCampo varchar(30), @ptLista VALOR_ALFA READONLY
AS
BEGIN

  DECLARE  @sql        Nvarchar(500)

  DECLARE  @k_activa   VARCHAR(1)  =  'A'

  DECLARE  @NunRegistros     int, 
           @RowCount         int,
		   @list_valores     Nvarchar(120) =  ' ',
		   @valor            varchar(10) 

  SET @NunRegistros = (SELECT COUNT(*)  FROM  @ptLista)
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @valor =  valor FROM @ptLista
    WHERE RowID = @RowCount
	IF  @RowCount  <>  @NunRegistros
 	BEGIN
	  SET @list_valores  =  @list_valores  + char(39) +  @valor + char(39) + ','    
    END
	ELSE
	BEGIN
 	  SET @list_valores  =  @list_valores  + char(39) +  @valor + char(39)
	END

    SET  @RowCount  =  @RowCount  +  1
  END

--  SELECT 'SALE WHILE'

  SET  @sql =
  'DELETE FC_CIFRA_CONTROL WHERE ' +
  ' CVE_EMPRESA = ' +  char(39) + @pCveEmpresa  + char(39) +  ' AND ' + 
  ' ANO_MES  = ' + char(39) +  @pAnoMes + char(39) +  ' AND ' +        
  ' ID_PROCESO = '  + CONVERT(varchar(10),@pIdProceso) + ' AND ' +
  ' CONCEPTO_PROC IN '  

  IF  @pNomTabla <> ' '
  BEGIN
    SET @sql = @sql + '(SELECT CVE_OPER_CONT FROM ' +  @pNomTabla +  
    ' WHERE ' + @pNomCampo +  ' IN (' + @list_valores + '))'
  END
  ELSE
  BEGIN
    SET @sql = @sql + '(' + @list_valores + ')'
  END

  SELECT @sql
  EXEC(@sql)
  
 -- Borra transacciones creadas con anterioridad
  SET  @sql =
  'DELETE CI_CONCEP_TRANSAC  WHERE ' + 
  ' EXISTS (SELECT 1 FROM  CI_TRANSACCION_CONT t WHERE ID_TRANSACCION = t.ID_TRANSACCION  AND ' +
  ' t.CVE_EMPRESA = ' +  char(39) +  @pCveEmpresa + char(39) + ' AND ' +
  ' t.ANO_MES = ' + char(39) + @pAnoMes + char(39) + ' AND ' +
  ' t.SIT_TRANSACCION = ' + char(39) + @k_activa + char(39) + ' AND ' + 
  ' t.CVE_OPER_CONT IN '

  IF  @pNomTabla <> ' '
  BEGIN
    SET @sql = @sql + '(SELECT CVE_OPER_CONT FROM ' +  @pNomTabla +  
    ' WHERE ' + @pNomCampo +  ' IN (' + @list_valores + ')))'
  END
  ELSE
  BEGIN
    SET @sql = @sql + '(' + @list_valores + '))'
  END

  SELECT @sql
  EXEC(@sql)

  SET  @sql =
  ' DELETE CI_TRANSACCION_CONT WHERE '  +
  ' CVE_EMPRESA = ' + char(39) + @pCveEmpresa + char(39) + ' AND ' +
  ' ANO_MES =  ' + char(39) + @pAnoMes + char(39) + ' AND ' +        
  ' SIT_TRANSACCION  = ' + char(39) + @k_activa + char(39) + ' AND ' + 
  ' CVE_OPER_CONT IN '

  IF  @pNomTabla <> ' '
  BEGIN
    SET @sql = @sql + '(SELECT CVE_OPER_CONT FROM ' +  @pNomTabla +  
    ' WHERE ' + @pNomCampo +  ' IN (' + @list_valores + '))'
  END
  ELSE
  BEGIN
    SET @sql = @sql + '(' + @list_valores + ')'
  END

  SELECT @sql
  EXEC(@sql)

END