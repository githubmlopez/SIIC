USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertAnt] ON [dbo].[CI_ANTICIPO_MOVTO]
INSTEAD OF INSERT
AS

BEGIN
  DECLARE
  @cve_empresa        varchar(4),
  @id_anticipo        int,
  @cve_tipo_ant       varchar(4),
  @id_movto_bancario  int,
  @imp_iva_pagado     int,
  @ano_mes_aplic      varchar(6),
  @b_ultimo           bit

  DECLARE
  @tx_error_part      varchar(300),
  @b_reg_correcto     bit,
  @imp_acum_ant       numeric(16,2)

  DECLARE 
  @k_verdadero     bit = 1,
  @k_falso         bit = 0,
  @k_cerrado       varchar(1)  =  'C',
  @k_cxc           varchar(4)  =  'CXC',
  @k_cxp           varchar(4)  =  'CXP',
  @k_iva           varchar(10) =  'IVA'

  SET  @tx_error_part  =  ' '

  IF  (SELECT COUNT(*) FROM INSERTED) = 1
  BEGIN

  SET  @b_reg_correcto =  @k_verdadero

-- Inicialización de datos 

  SELECT @cve_empresa        =  CVE_EMPRESA       FROM INSERTED i
  SELECT @id_anticipo        =  ID_ANTICIPO       FROM INSERTED i
  SELECT @cve_tipo_ant       =  CVE_TIPO_ANT      FROM INSERTED i
  SELECT @id_movto_bancario  =  ID_MOVTO_BANCARIO FROM INSERTED i
  SELECT @imp_iva_pagado     =  IMP_IVA_PAGADO    FROM INSERTED i
  SELECT @ano_mes_aplic      =  ANO_MES_APLIC     FROM INSERTED i
  SELECT @b_ultimo           =  B_ULTIMO          FROM INSERTED i

  SET @b_reg_correcto   =  @k_verdadero;

  SET @tx_error_part    =  ' ';

  IF   EXISTS (SELECT * FROM CI_ANTICIPO_MOVTO  WHERE  CVE_EMPRESA       =  @cve_empresa  AND
                                                       ID_ANTICIPO       =  @id_anticipo  AND
													   CVE_TIPO_ANT      =  @cve_tipo_ant AND
													   ID_MOVTO_BANCARIO =  @id_movto_bancario)
											
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': La Anticipo ya existe-' + CONVERT(varchar(8),@id_anticipo),1,300)
  END                                          

  IF  NOT EXISTS (SELECT 1 FROM  CI_MOVTO_BANCARIO WHERE ID_MOVTO_BANCARIO = @id_movto_bancario)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': No Existe Movto Banc -' + CONVERT(varchar(8),@id_movto_bancario),1,300)
  END                         

  IF  @cve_tipo_ant   NOT IN (@k_cxc,@k_cxp)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': Tipo Ant. Invalido-' + CONVERT(varchar(8),@cve_tipo_ant),1,300)
  END 

  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
   BEGIN TRY
   INSERT   CI_ANTICIPO_MOVTO
            (CVE_EMPRESA,            
             ID_ANTICIPO,                  
             CVE_TIPO_ANT,                 
             ID_MOVTO_BANCARIO,            
             IMP_IVA_PAGADO,              
             ANO_MES_APLIC,            
             B_ULTIMO)           
    VALUES
	        (@cve_empresa,
	         @id_anticipo,
	         @cve_tipo_ant,
	         @id_movto_bancario,
		   ((SELECT VALOR_NUMERICO FROM CI_PARAMETRO  WHERE CVE_PARAMETRO = @k_iva) / 100) * 
		    (SELECT SUM(m.IMP_TRANSACCION) FROM CI_MOVTO_BANCARIO m
             WHERE m.ID_MOVTO_BANCARIO = @id_movto_bancario),
	         @ano_mes_aplic,
	         @b_ultimo)

    SET @imp_acum_ant = ISNULL((SELECT SUM(m.IMP_TRANSACCION) FROM CI_ANTICIPO_MOVTO a, CI_MOVTO_BANCARIO m
    WHERE  a.CVE_EMPRESA       = @cve_empresa   AND
           a.ID_ANTICIPO       = @id_anticipo   AND
	       a.CVE_TIPO_ANT      = @cve_tipo_ant  AND
		   a.ID_MOVTO_BANCARIO = m.ID_MOVTO_BANCARIO),0) 

    UPDATE CI_ANTICIPO SET IMP_ACUM_ANT = @imp_acum_ant WHERE
    CVE_EMPRESA       = @cve_empresa   AND
    ID_ANTICIPO       = @id_anticipo   AND
    CVE_TIPO_ANT      = @cve_tipo_ant  

    END TRY

    BEGIN CATCH
	SET @tx_error_part    =  ISNULL(ERROR_MESSAGE(), ' ')
    RAISERROR(@tx_error_part,11,1)
	END CATCH
  END
  ELSE
  BEGIN
    RAISERROR(@tx_error_part,11,1)
  END    

  END

  ELSE
  BEGIN
    SET @tx_error_part    =  @tx_error_part + ': No se permiten INSERTs multiples'
	RAISERROR(@tx_error_part,11,1)  
  END

END


