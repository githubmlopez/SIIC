USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfDeletetAnt] ON [dbo].[CI_ANTICIPO_MOVTO]
INSTEAD OF DELETE
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
  @k_falso         bit = 0

  SET  @tx_error_part  =  ' '

  IF  (SELECT COUNT(*) FROM DELETED) = 1
  BEGIN

  SET  @b_reg_correcto =  @k_verdadero

-- Inicialización de datos 

  SELECT @cve_empresa        =  CVE_EMPRESA       FROM DELETED d
  SELECT @id_anticipo        =  ID_ANTICIPO       FROM DELETED d
  SELECT @cve_tipo_ant       =  CVE_TIPO_ANT      FROM DELETED d
  SELECT @id_movto_bancario  =  ID_MOVTO_BANCARIO FROM DELETED d
  SELECT @imp_iva_pagado     =  IMP_IVA_PAGADO    FROM DELETED d
  SELECT @ano_mes_aplic      =  ANO_MES_APLIC     FROM DELETED d
  SELECT @b_ultimo           =  B_ULTIMO          FROM DELETED d

  SET @b_reg_correcto   =  @k_verdadero;

  SET @tx_error_part    =  ' ';

  IF   NOT EXISTS (SELECT * FROM CI_ANTICIPO_MOVTO  WHERE  CVE_EMPRESA       =  @cve_empresa  AND
                                                           ID_ANTICIPO       =  @id_anticipo  AND
													       CVE_TIPO_ANT      =  @cve_tipo_ant AND
													       ID_MOVTO_BANCARIO =  @id_movto_bancario)
  BEGIN
    SET @b_reg_correcto   =  @k_falso;
    SET @tx_error_part    =  SUBSTRING(@tx_error_part + ': El Anticipo NO existe-' + CONVERT(varchar(8),@id_anticipo),1,300)
  END                                          

  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
   BEGIN TRY
    DELETE CI_ANTICIPO_MOVTO WHERE
    CVE_EMPRESA       = @cve_empresa   AND
    ID_ANTICIPO       = @id_anticipo   AND
    CVE_TIPO_ANT      = @cve_tipo_ant  AND
    ID_MOVTO_BANCARIO = @id_movto_bancario

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
    SET @tx_error_part    =  @tx_error_part + ': No se permiten DELETEs multiples'
	RAISERROR(@tx_error_part,11,1)  
  END

END
