USE [ADNOMINA01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
CREATE TRIGGER [dbo].[trgInsteadOfInsertNO_INCIDENCIA] ON [dbo].[NO_INCIDENCIA]
INSTEAD OF Insert
AS

BEGIN

  DECLARE  @cve_tipo_nomina  varchar(2),
           @id_empleado      int,
	       @ano_periodo      varchar(6),
           @id_incidencia    int,
		   @cve_concepto     varchar(4),
		   @f_incidencia     date,
		   @imp_inicidencia  numeric(12,2),
	   	   @firma            varchar(10),
		   @tx_nota          varchar(200),
		   @b_mov_automatico bit,
		   @sit_incidencia   varchar(1)

  DECLARE  @b_reg_correcto  bit,
           @tx_error_part   varchar(300),
		   @ano             varchar(4)   

  DECLARE  @k_verdadero     bit,
           @k_falso         bit,
           @k_activa        varchar(1), 
           @k_cancelada     varchar(1),
		   @k_vacaciones    varchar(6)
    
  SET    @k_verdadero     = 1
  SET    @k_falso         = 0
  SET    @k_cancelada     = 'C'
  SET    @k_vacaciones    = 'O001'
  SET    @k_activa        = 'A'
    
-- Corrección de datos

-- Inicialización de datos 

  SELECT   @cve_tipo_nomina   =  i.CVE_TIPO_NOMINA from inserted i;
  SELECT   @id_empleado       =  i.ID_EMPLEADO from inserted i;
  SELECT   @ano_periodo       =  i.ANO_PERIODO from inserted i;
  SELECT   @id_incidencia     =  i.ID_INCIDENCIA from inserted i;
  SELECT   @cve_concepto      =  i.CVE_CONCEPTO from inserted i;
  SELECT   @f_incidencia      =  i.F_INCIDENCIA from inserted i;
  SELECT   @imp_inicidencia   =  i.IMP_INCIDENCIA from inserted i;
  SELECT   @firma             =  i.FIRMA from inserted i;
  SELECT   @tx_nota           =  i.TX_NOTA from inserted i;
  SELECT   @b_mov_automatico  =  i.B_MOV_AUTOMATICO from inserted i;
  SELECT   @sit_incidencia    =  i.SIT_INCIDENCIA from inserted i;

  SET NOCOUNT ON;

  SET @b_reg_correcto   =  @k_verdadero;
  SET @tx_error_part    =  ' '

  IF   EXISTS (SELECT 1 FROM NO_INCIDENCIA  WHERE  CVE_TIPO_NOMINA    =  @cve_tipo_nomina AND
                                                   ID_EMPLEADO        =  @id_empleado     AND
                                                   ID_INCIDENCIA      =  @id_incidencia   AND
                                                   ANO_PERIODO        =  @ano_periodo)
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': La Incidencia ya existe';
  END                                          

  IF   NOT EXISTS (SELECT 1 FROM NO_EMPLEADO WHERE CVE_TIPO_NOMINA    =  @cve_tipo_nomina AND
                                                   ID_EMPLEADO        =  @id_empleado)    
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': No existe el empleado';
  END                                          

  IF   NOT EXISTS (SELECT 1 FROM NO_ANOMES_PERIODO   WHERE  CVE_TIPO_NOMINA    =  @cve_tipo_nomina AND
                                                            ANO_PERIODO        =  @ano_periodo)
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': No existe el periodo';
  END                                          

  IF  NOT EXISTS (SELECT 1 FROM NO_CONCEPTO   WHERE  CVE_CONCEPTO  =  @cve_concepto)                                    
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': No existe el concepto';
  END                             

  IF  @sit_incidencia not in (@k_activa, @k_cancelada)          
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': Situacion con error';
  END
           
  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
 
    set @sit_incidencia   =  @k_activa;

    Insert into NO_INCIDENCIA 
               (CVE_TIPO_NOMINA,
                ID_EMPLEADO,
                ANO_PERIODO,
                ID_INCIDENCIA,
                CVE_CONCEPTO,
                F_INCIDENCIA,
                IMP_INCIDENCIA,
                FIRMA,
                TX_NOTA,
                B_MOV_AUTOMATICO,
                SIT_INCIDENCIA)
           values     
               (@cve_tipo_nomina,
                @id_empleado,
                @ano_periodo,
                @id_incidencia,
				@cve_concepto,
				@f_incidencia,
                isnull(@imp_inicidencia,0),
                @firma,
                @tx_nota,
                @k_falso,
                @sit_incidencia)
 
	IF  @cve_concepto  =  @k_vacaciones
    BEGIN
--	  SET @ano  =  CONVERT(varchar(4), YEAR(@f_incidencia))
	  SET @ano  =  SUBSTRING(@ano_periodo,1,4)
	  
	  IF  EXISTS(SELECT 1  FROM  NO_VACACIONES_PERIODO  
	      WHERE  CVE_TIPO_NOMINA  =  @cve_tipo_nomina  AND
			     ID_EMPLEADO      =  @id_empleado      AND
			     ANO              =  @ano)
	  BEGIN
	  
	    UPDATE  NO_VACACIONES_PERIODO  SET  DIAS_DISFRUTADOS =  DIAS_DISFRUTADOS + isnull(@imp_inicidencia,0)
	            WHERE  CVE_TIPO_NOMINA  =  @cve_tipo_nomina  AND
			           ID_EMPLEADO      =  @id_empleado      AND
				       ANO              =  @ano
      END
	  ELSE
	  BEGIN
        SET @tx_error_part = @tx_error_part + ': No existe el periodo a Actualizar';
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