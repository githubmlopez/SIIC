USE [ADNOMINA01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trgInsteadOfDeleteNO_INCIDENCIA] ON [dbo].[NO_INCIDENCIA]
INSTEAD OF Delete
AS

BEGIN

  DECLARE  @dcve_tipo_nomina  varchar(2),
           @did_empleado      int,
	       @dano_periodo      varchar(6),
           @did_incidencia    int,
		   @dcve_concepto     varchar(6),
		   @df_incidencia     date,
		   @dimp_inicidencia  numeric(12,2),
	   	   @dfirma            varchar(10),
		   @dtx_nota          varchar(200),
		   @db_mov_automatico bit,
		   @dsit_incidencia   varchar(1)

  DECLARE  @b_reg_correcto  bit,
           @tx_error_part   varchar(300),
		   @ano             varchar(4)   

  DECLARE  @k_verdadero     bit,
           @k_falso         bit,
		   @k_vacaciones    varchar(6)
    
  SET    @k_verdadero     = 1
  SET    @k_falso         = 0
  SET    @k_vacaciones    = 'O001'
    
-- Corrección de datos

-- Inicialización de datos 

  SELECT   @dcve_tipo_nomina   =  d.CVE_TIPO_NOMINA from DELETED d;
  SELECT   @did_empleado       =  d.ID_EMPLEADO from DELETED d;
  SELECT   @dano_periodo       =  d.ANO_PERIODO from DELETED d;
  SELECT   @did_incidencia     =  d.ID_INCIDENCIA from DELETED d;
  SELECT   @dcve_concepto      =  d.CVE_CONCEPTO from DELETED d;
  SELECT   @df_incidencia      =  d.F_INCIDENCIA from DELETED d;
  SELECT   @dimp_inicidencia   =  d.IMP_INCIDENCIA from DELETED d;
  SELECT   @dfirma             =  d.FIRMA from DELETED d;
  SELECT   @dtx_nota           =  d.TX_NOTA from DELETED d;
  SELECT   @db_mov_automatico  =  d.B_MOV_AUTOMATICO from DELETED d;
  SELECT   @dsit_incidencia    =  d.SIT_INCIDENCIA from DELETED d;

  SET NOCOUNT ON;

  SET @b_reg_correcto   =  @k_verdadero
  SET @tx_error_part    =  ' '

  IF   NOT EXISTS (SELECT 1 FROM NO_INCIDENCIA  WHERE  CVE_TIPO_NOMINA    =  @dcve_tipo_nomina AND
                                                       ID_EMPLEADO        =  @did_empleado     AND
                                                       ID_INCIDENCIA      =  @did_incidencia   AND
                                                       ANO_PERIODO        =  @dano_periodo)
  BEGIN
    set @b_reg_correcto   =  @k_falso
    set @tx_error_part    =  @tx_error_part + 'El registro a dar de baja no existe' + @dcve_tipo_nomina -- +
	                         -- convert(varchar(12), @did_empleado) + convert(varchar(12), @did_incidencia) +
							 -- @dano_periodo
  END                                          

           
  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
 
    IF  @dcve_concepto  =  @k_vacaciones
    BEGIN
--	  SET @ano  =  CONVERT(varchar(4), YEAR(@df_incidencia))
 	  SET @ano  =  SUBSTRING(@dano_periodo,1,4)
	  
	  IF  EXISTS(SELECT 1  FROM  NO_VACACIONES_PERIODO  
	      WHERE  CVE_TIPO_NOMINA  =  @dcve_tipo_nomina  AND
			     ID_EMPLEADO      =  @did_empleado      AND
			     ANO              =  @ano)
	  BEGIN
	  
	    UPDATE  NO_VACACIONES_PERIODO  SET  DIAS_DISFRUTADOS =  DIAS_DISFRUTADOS - isnull(@dimp_inicidencia,0)
	            WHERE  CVE_TIPO_NOMINA  =  @dcve_tipo_nomina  AND
			           ID_EMPLEADO      =  @did_empleado      AND
				       ANO              =  @ano
      END
	  ELSE
	  BEGIN
        SET @tx_error_part = @tx_error_part + ': No existe periodo de vacaciones a Actualizar';
        SET @tx_error_part =  LTRIM('Error : ' + @tx_error_part)
	    RAISERROR(@tx_error_part,11,1)
	  END
	END
  END
  ELSE
  BEGIN
    SET @tx_error_part =  LTRIM('Error : ' + @tx_error_part)
	RAISERROR(@tx_error_part,11,1)
  END    
END
