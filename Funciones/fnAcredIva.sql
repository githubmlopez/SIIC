USE [ADMON01]
GO
/****** Object:  UserDefinedFunction [dbo].[fnArmaAnoMes]    Script Date: 02/10/2018 09:34:53 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnAcredIva] (@pCveEmpresa varchar(4), @pIdMovtoBancario int)
RETURNS bit
-- WITH EXECUTE AS CALLER
AS
BEGIN
--  DECLARE @pIdMovtoBancario int = 407, @f_pago  date = '2016-05-19' 
  DECLARE  @b_acredita      bit,
           @NumRegistros    int,
		   @RowCount        int,
		   @id_concilia_cxc numeric(9,0),
		   @f_operacion     date,
		   @mes_fact        int,
		   @mes_pago        int,
		   @meses_inc       int,
		   @meses_dif       int,
		   @dias_mes_sat    int,
		   @f_pago          date

  DECLARE  @k_verdadero  bit  =  1,
           @k_falso      bit  =  0,
		   @k_dias_sat   varchar(10) =  'DSAT'


  SET   @dias_mes_sat = (SELECT VALOR_NUMERICO  FROM  CI_PARAMETRO WHERE
                         CVE_PARAMETRO  =  @k_dias_sat)

  SELECT @f_pago = (SELECT F_OPERACION FROM CI_MOVTO_BANCARIO WHERE ID_MOVTO_BANCARIO = @pIdMovtoBancario)

-------------------------------------------------------------------------------
-- Declaración de tabla auxiliar
-------------------------------------------------------------------------------

  DECLARE  @TPagoFactura    TABLE
          (RowID            int  identity(1,1),
		   ID_CONCILIA_CXC  numeric(9,0),
		   F_OPERACION      date)		   
		   
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  INSERT @TPagoFactura  (ID_CONCILIA_CXC, F_OPERACION)  
  SELECT c.ID_CONCILIA_CXC, f.F_OPERACION
  FROM   CI_FACTURA f, CI_CONCILIA_C_X_C c
  WHERE  c.ID_MOVTO_BANCARIO  =  @pIdMovtoBancario  AND
		 c.ID_CONCILIA_CXC    =  f.ID_CONCILIA_CXC ORDER BY f.F_OPERACION DESC
  SET @NumRegistros = @@ROWCOUNT
-----------------------------------------------------------------------------------------------------
  SET @RowCount     = 1
 
  SET @b_acredita  =  @k_falso 

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT @id_concilia_cxc = ID_CONCILIA_CXC, @f_operacion = F_OPERACION FROM @TPagoFactura
	WHERE  RowID  =  @RowCount
	
	IF  @f_operacion = (SELECT MIN(F_OPERACION) FROM CI_FACTURA  WHERE
	    ID_CONCILIA_CXC = @id_concilia_cxc)
	BEGIN
      IF  @f_pago <=  @f_operacion -- Criterio 1 Fecha de pago menor igual a fecha de operación
	  BEGIN
	    SET @b_acredita  =  @k_verdadero
--        SELECT 'C1'
	  END
	  ELSE
	  BEGIN
	    IF  YEAR(@f_pago) >  YEAR(@f_operacion)
		BEGIN
		  SET @meses_inc =  (YEAR(@f_pago) - YEAR(@f_operacion)) * 12
		  SET @meses_dif =  (MONTH(@f_pago) + @meses_inc) - MONTH(@f_operacion)
		END
        ELSE
		BEGIN
          SET @meses_dif =  MONTH(@f_pago) - MONTH(@f_operacion)
		END
--        SELECT CONVERT(varchar(5),  @meses_dif)
        IF  @meses_dif  =  0  -- Criterio 2  El pago se efectúa en el mismo mes  
		BEGIN
		  SET @b_acredita  =  @k_verdadero
--		  SELECT 'C2'
		END
		ELSE
		BEGIN 
		  IF   DAY(@f_pago)  <=  @dias_mes_sat  AND  @meses_dif = 1 -- Criterio 3 El pago en del mes anterior y el día es menor al establecido por el SAT
		  BEGIN
		    SET @b_acredita  =  @k_verdadero
--		    SELECT 'C3'
		  END    
		  ELSE
		  BEGIN
        	IF  EXISTS(SELECT 1 FROM  CI_REC_PAG_BAN_CXC  WHERE -- Cualquier otro caso en que exista un recibo
		               CVE_EMPRESA        =  @pCveEmpresa  AND
					   ID_MOVTO_BANCARIO  =  @pIdMovtoBancario)
		    BEGIN
		      SET @b_acredita  =  @k_verdadero
--			  SELECT 'C4'
		    END 
 		  END
        END
	  END
	END
	ELSE
	BEGIN
	  SET @b_acredita  =  @k_falso 
	END 
    SET @RowCount     =   @RowCount + 1
  END
  RETURN @b_acredita   

--  SELECT   @b_acredita   
END
