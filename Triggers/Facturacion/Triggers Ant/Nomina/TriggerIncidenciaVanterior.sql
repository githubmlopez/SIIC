USE [ADNOMINA01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertIncidencia]    Script Date: 18/12/2017 01:23:47 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table NO_INCIDENCIA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertIncidencia] ON [dbo].[NO_INCIDENCIA]
INSTEAD OF Insert
AS

-- Buffer de registro insertado NO_INCIDENCIA

declare
   @cve_tipo_nomina    varchar(2),
   @id_empleado        int,
   @id_incidencia      int,
   @ano_periodo        varchar(6),
   @cve_concepto       varchar(4),
   @id_perc_deduc      int,
   @f_incidencia       date,
   @imp_incidencia     numeric(12,2),
   @firma              varchar(10),
   @tx_nota            varchar(200),
   @b_mov_automatico   bit,
   @sit_incidencia     varchar(1),
   @dias_vacaciones    int;

declare

    @b_reg_correcto    bit,
    @tx_error          varchar(300),
    @tx_error_part     varchar(300),
    @fol_incidencia    int,
    @fol_audit         int;

declare 

    @k_verdadero      bit,
    @k_falso          bit,
    @k_activa         varchar(1),
    @k_cancelada      varchar(1),
    @k_importe        varchar(1),
    @k_cantidad       varchar(1),
    @k_incidencia     varchar(1),
    @k_fol_incidencia varchar(4),
    @k_fol_audit      varchar(4),
    @k_sueldo         varchar(4),
    @k_comision       varchar(4)
select   
    
    @k_verdadero      = 1,
    @k_falso          = 0,
    @k_activa         = 'A', 
    @k_cancelada      = 'C',
    @k_importe        = 'I',
    @k_cantidad       = 'C',
    @k_incidencia     = 'I',
    @k_sueldo         = 'P001',
    @k_comision       = 'P002',
    @k_fol_incidencia = 'INC',
    @k_fol_audit      = 'AUDI'
    

set  @b_reg_correcto =  @k_verdadero;
set  @tx_error       =  ' ';
set  @tx_error_part  =  ' ';

select   @cve_tipo_nomina    = i.CVE_TIPO_NOMINA from inserted i;
select   @id_empleado        = i.ID_EMPLEADO from inserted i;
select   @ano_periodo        = i.ANO_PERIODO from inserted i;
select   @id_incidencia      = i.ID_INCIDENCIA from inserted i;
select   @cve_concepto       = i.CVE_CONCEPTO from inserted i;
select   @f_incidencia       = i.F_INCIDENCIA from inserted i;
select   @imp_incidencia     = i.IMP_INCIDENCIA from inserted i;
select   @firma              = i.FIRMA from inserted i;
select   @tx_nota            = i.TX_NOTA from inserted i;
select   @b_mov_automatico   = i.B_MOV_AUTOMATICO from inserted i;
select   @sit_incidencia     = i.SIT_INCIDENCIA from inserted i;
select   @dias_vacaciones    = i.DIAS_VACACIONES from inserted i;

BEGIN 
  SET NOCOUNT ON;

  set  @firma             =  ' '
  set  @b_reg_correcto    =  @k_verdadero
  set  @tx_error_part     =  ' '

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

  IF  ((NOT EXISTS (SELECT * FROM NO_DED_PERC_PERIODO dc  WHERE  dc.CVE_TIPO_NOMINA    =  @cve_tipo_nomina AND
                                                                 dc.ID_EMPLEADO        =  @id_empleado     AND
                                                                 dc.CVE_CONCEPTO       =  @cve_concepto))  AND
       (@cve_concepto     NOT IN (@k_sueldo, @k_comision)))  and
       (@k_incidencia                <>
       (SELECT CVE_TIPO_CONCEPTO  FROM NO_CONCEPTO c WHERE @cve_concepto = c.CVE_CONCEPTO)) 
                                                                                           
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': No existe Percep deduccion' + @cve_concepto;
  END

  IF  @sit_incidencia not in (@k_activa, @k_cancelada)          
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': Situacion con error';
  END
           
  IF  @b_reg_correcto  =  @k_verdadero                                      
  BEGIN

    SELECT @fol_incidencia = NUM_FOLIO 
    FROM NO_FOLIO WHERE CVE_FOLIO =  @k_fol_incidencia
    
    set @fol_incidencia = @fol_incidencia + 1
       
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
           SIT_INCIDENCIA,
           DIAS_VACACIONES)
           values     
          (@cve_tipo_nomina,
           @id_empleado,
           @ano_periodo,
           @fol_incidencia,
           @cve_concepto,
           @f_incidencia,
           @imp_incidencia,
           @firma,
           @tx_nota,
           @b_mov_automatico,
           @sit_incidencia,
           @dias_vacaciones)
           
    UPDATE NO_FOLIO
    SET NUM_FOLIO = @fol_incidencia + 1
    WHERE  CVE_FOLIO     = @k_fol_incidencia

-- Actualizando acumulados de NO_PERCEPCION_DEDUCCION

	SELECT ' ** VOY A ACTUALIZAR ACUMULADOS ** ' + CAST( ISNULL((SELECT SUM(IMP_INCIDENCIA) FROM NO_INCIDENCIA WHERE SIT_INCIDENCIA    = @k_activa        AND
	                                                            CVE_TIPO_NOMINA   = @cve_tipo_nomina AND
	                                                            ID_EMPLEADO       = @id_empleado     AND
	                                                            CVE_CONCEPTO      = @cve_concepto), 0) AS varchar(10))
	
	UPDATE NO_DED_PERC_PERIODO
    SET    IMP_ACUMULADO    = 
    ISNULL((SELECT SUM(IMP_INCIDENCIA) FROM NO_INCIDENCIA WHERE SIT_INCIDENCIA    = @k_activa        AND
	                                                            CVE_TIPO_NOMINA   = @cve_tipo_nomina AND
	                                                            ID_EMPLEADO       = @id_empleado     AND
	                                                            CVE_CONCEPTO      = @cve_concepto), 0) + IMP_ACUMULADO
    WHERE  CVE_TIPO_NOMINA  =  @cve_tipo_nomina AND
           ID_EMPLEADO      =  @id_empleado     AND
           CVE_CONCEPTO     =  @cve_concepto    AND
           SIT_PER_DEDUC    =  @k_activa
     
  END
  ELSE
  BEGIN
    set @tx_error = 'Error NO_INCIDENCIA : ' + @cve_tipo_nomina + ' ' + CAST(@id_empleado AS varchar(10)) + ' ' + @cve_concepto + ':' + @tx_error_part
 
    set @fol_audit  =  (select NUM_FOLIO FROM NO_FOLIO WHERE CVE_FOLIO = @k_fol_audit)
    
    UPDATE NO_FOLIO
           SET NUM_FOLIO = @fol_audit + 1
    WHERE  CVE_FOLIO     = @k_fol_audit

    insert into  NO_AUDIT_ERROR (
                 ID_FOLIO,
                 F_OPERACION,
                 TX_ERROR)      
           values
                (@fol_audit,
                 GETDATE(),
                 @tx_error)
    COMMIT
    RAISERROR('El INSERT TIENE INCONSISTENCIA DE INFORMACION',11,1)
  END    
END



