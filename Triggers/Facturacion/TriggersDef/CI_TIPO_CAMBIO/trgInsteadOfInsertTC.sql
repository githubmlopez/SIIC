USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertTC]    Script Date: 27/12/2018 09:48:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_TIPO_CAMBIO for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertTC] ON [dbo].[CI_TIPO_CAMBIO]
INSTEAD OF INSERT
AS

BEGIN

  DECLARE
	  @f_operacion        date,
	  @tipo_cambio        numeric(8,4)


  DECLARE
   @b_reg_correcto   bit,
   @b_dia_habil      bit = 0,
   @tx_error         varchar(300),
   @tx_error_part    varchar(300),
   @fol_act          int,
   @fol_audit        int,
   @cve_moneda       varchar(1),
   @dias             int = 0

  DECLARE 
   @k_verdadero      bit = 1,
   @k_falso          bit = 0,
   @k_fol_audit      varchar(4)  =  'AUDI',
   @k_fol_act        varchar(4)  =  'NACT'

  SET  @tx_error_part  =  ' '

  IF  (SELECT COUNT(*) FROM INSERTED) = 1
  BEGIN

    SET  @b_reg_correcto =  @k_verdadero

-- Inicialización de datos 

    SELECT @f_operacion        =  F_OPERACION       FROM INSERTED i
    SELECT @tipo_cambio        =  TIPO_CAMBIO       FROM INSERTED i

    SET @b_reg_correcto   =  @k_verdadero;

    SET @tx_error_part    =  ' ';

    IF  @b_reg_correcto   =  @k_verdadero                                      
    BEGIN
      INSERT   CI_TIPO_CAMBIO 
     (F_OPERACION,            
      TIPO_CAMBIO)            
      VALUES
     (@f_operacion,
      @tipo_cambio)
      SET  @b_dia_habil = @k_falso
      SET  @dias = 0
      WHILE @b_dia_habil = @k_falso
      BEGIN
        SET @dias = @dias + 1
        IF  EXISTS (SELECT 1 FROM CI_DIA_FESTIVO WHERE F_FESTIVA = DATEADD(DAY, @dias, @f_operacion)) OR
            DATEPART(WEEKDAY, DATEADD(DAY, @dias, @f_operacion)) IN (1,7)
        BEGIN
          IF  EXISTS (SELECT 1 FROM CI_TIPO_CAMBIO WHERE F_OPERACION = (DATEADD(DAY, @dias, @f_operacion)))
		  BEGIN
            UPDATE CI_TIPO_CAMBIO  SET TIPO_CAMBIO =@tipo_cambio
			WHERE F_OPERACION = (DATEADD(DAY, @dias, @f_operacion))
		  END
          ELSE
		  BEGIN
		    INSERT   CI_TIPO_CAMBIO 
           (F_OPERACION,            
            TIPO_CAMBIO)            
            VALUES
           (DATEADD(DAY, @dias, @f_operacion),
            @tipo_cambio)
          END
        END
        ELSE
        BEGIN
          SET  @b_dia_habil = @k_verdadero
        END
      END
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

