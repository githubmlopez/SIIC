USE [ADMON01BK]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgInsteadOfInsertCXCI] ON [dbo].[CI_ITEM_C_X_C]
INSTEAD OF Insert
AS
declare
   @cve_empresa       varchar(4),
   @serie             varchar(6),
   @id_cxc            int,
   @id_item           int,
   @cve_subproducto   varchar(8),
   @imp_bruto_item    numeric(12,2),
   @f_inicio          date,
   @f_fin             date,
   @imp_est_cxp       numeric(12,2),
   @imp_real_cxp      numeric(12,2),
   @cve_proceso1      varchar(4),
   @cve_vendedor1     varchar(4),
   @cve_especial1     varchar(2),
   @imp_desc_comis1   numeric(12,2),
   @imp_com_dir1      numeric(12,2),
   @cve_proceso2      varchar(4),
   @cve_vendedor2     varchar(4),
   @cve_especial2     varchar(2),
   @imp_desc_comis2   numeric(12,2),
   @imp_com_dir2      numeric(12,2),
   @sit_item_cxc      varchar(2),
   @tx_nota           varchar(400),
   @f_fin_instalacion varchar(2);

declare

    @b_reg_correcto   bit,
    @b_gen_segundo    bit,
    @tx_error         varchar(300),
    @tx_error_part    varchar(300),
    @fol_act          int,
    @fol_audit        int;

declare 

    @cve_producto     varchar(4),
    @dias_poliza      int,
    @dias_act_vale1   int,
    @fecha_act_vale1  date,
    @fecha_act_vale2  date;

declare 

    @k_verdadero     bit,
    @k_falso         bit,
    @k_poliza        varchar(2),
    @k_activa        varchar(1), 
    @k_cancelada     varchar(1),
    @k_pend_liberar  varchar(2),
    @k_proc_renov    int,
    @k_fol_audit     varchar(4),
    @k_fol_act       varchar(4);

select   
   
    @k_verdadero     = 1,
    @k_falso         = 0,
    @k_proc_renov    = 1,
    @k_cancelada     = 'C',
    @k_activa        = 'A', 
    @k_cancelada     = 'C',
    @k_poliza        = 'PO',
    @k_pend_liberar  = 'PL',
    @k_fol_audit     = 'AUDI',
    @k_fol_act       = 'NACT';
    
set  @b_reg_correcto =  @k_verdadero
set  @b_gen_segundo  =  @k_falso
set  @tx_error_part  =  ' '

-- Corrección de datos

IF  @f_inicio  = '1900-01-01'
BEGIN
  set @f_inicio = NULL
END

IF  @f_fin  = '1900-01-01'
BEGIN
  set @f_fin = NULL
END

IF  @cve_vendedor2  = ' '
BEGIN
  set @cve_vendedor2   = NULL
  set @cve_proceso2    = NULL
  set @cve_especial2   = NULL
END

-- Inicialización de datos 

select   @cve_empresa       =  i.CVE_EMPRESA from inserted i;
select   @serie             =  i.SERIE from inserted i;
select   @id_cxc            =  i.ID_CXC from inserted i;
select   @id_item           =  i.ID_ITEM from inserted i;
select   @cve_subproducto   =  i.CVE_SUBPRODUCTO from inserted i;
select   @imp_bruto_item    =  i.IMP_BRUTO_ITEM from inserted i;
select   @f_inicio          =  i.F_INICIO from inserted i;
select   @f_fin             =  i.F_FIN from inserted i;
select   @imp_est_cxp       =  i.IMP_EST_CXP from inserted i;
select   @imp_real_cxp      =  i.IMP_REAL_CXP from inserted i;
select   @cve_proceso1      =  i.CVE_PROCESO1 from inserted i;
select   @cve_vendedor1     =  i.CVE_VENDEDOR1 from inserted i;
select   @cve_especial1     =  i.CVE_ESPECIAL1 from inserted i;
select   @imp_desc_comis1   =  i.IMP_DESC_COMIS1 from inserted i;
select   @imp_com_dir1      =  i.IMP_COM_DIR1 from inserted i;
select   @cve_proceso2      =  i.CVE_PROCESO2 from inserted i;
select   @cve_vendedor2     =  i.CVE_VENDEDOR2 from inserted i;
select   @cve_especial2     =  i.CVE_ESPECIAL2 from inserted i;
select   @imp_desc_comis2   =  i.IMP_DESC_COMIS2 from inserted i;
select   @imp_com_dir2      =  i.IMP_COM_DIR2 from inserted i;
select   @sit_item_cxc      =  i.SIT_ITEM_CXC from inserted i;
select   @tx_nota           =  i.TX_NOTA from inserted i;
select   @f_fin_instalacion =  i.F_FIN_INSTALACION from inserted i;

BEGIN 
  SET NOCOUNT ON;

  set @b_reg_correcto   =  @k_verdadero;

  set  @cve_producto  =  (SELECT CVE_PRODUCTO FROM CI_SUBPRODUCTO WHERE  CVE_SUBPRODUCTO  =  @cve_subproducto)	

  IF   @cve_producto  IS NULL
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': No existe el subproducto';
  END                                          

  IF   EXISTS (SELECT * FROM CI_ITEM_C_X_C  WHERE  CVE_EMPRESA    =  @cve_empresa AND
                                                   SERIE          =  @serie       AND
                                                   ID_CXC         =  @id_cxc      AND
                                                   ID_ITEM        =  @id_item)
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part    =  @tx_error_part + ': El ITEM ya existe';
  END                                          

  IF   @cve_producto  =   @k_poliza 
  BEGIN

    IF  (@f_inicio is not null and @f_fin is null) or
        (@f_inicio is null     and @f_fin is not null)
    BEGIN
      set @b_reg_correcto   =  @k_falso;
      set @tx_error_part    =  @tx_error_part + ': Inconsistencia en fechas';
    END
    ELSE
    BEGIN
      IF  (@f_inicio is not null and @f_fin is not null) 
      BEGIN
        IF  @f_inicio  >=  @f_fin
        BEGIN
          set @b_reg_correcto   =  @k_falso;
          set @tx_error_part    =  @tx_error_part + ': F Inicio <= F Final';
        END
        ELSE
        BEGIN
          set  @dias_poliza  = DATEDIFF(DAY, @f_inicio, @f_fin)
          IF   @dias_poliza  >  200  
          BEGIN
            set  @b_gen_segundo    =  @k_verdadero
            set  @dias_act_vale1   =  (@dias_poliza / 2) - 60
            set  @fecha_act_vale1  =  DATEADD(day,@dias_act_vale1, @f_inicio) 
            set  @fecha_act_vale2  =  DATEADD(day,-60, @f_fin) 
          END
          ELSE
          BEGIN
            set  @fecha_act_vale1  =  DATEADD(day,-60, @f_fin) 
          END
        END
      END
    END
  END                                          

  IF   NOT EXISTS (SELECT * FROM CI_VENDEDOR   WHERE  CVE_VENDEDOR   =  @cve_vendedor1) 
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': Inconsistencia en el vendedor 1';
  END                                          
  IF   @cve_vendedor2 is not null and
       NOT EXISTS (SELECT * FROM CI_VENDEDOR   WHERE  CVE_VENDEDOR   =  @cve_vendedor2)
  BEGIN
    set @b_reg_correcto   =  @k_falso;
    set @tx_error_part = @tx_error_part + ': Inconsistencia en el vendedor 2';
  END
          
  IF  @b_reg_correcto   =  @k_verdadero                                      
  BEGIN
 
    set @sit_item_cxc   =  @k_activa;
 
    Insert into CI_ITEM_C_X_C 
               (CVE_EMPRESA,
                SERIE,
                ID_CXC,
                ID_ITEM,
                CVE_SUBPRODUCTO,
                IMP_BRUTO_ITEM,
                F_INICIO,
                F_FIN,
                IMP_EST_CXP,
                IMP_REAL_CXP,
                CVE_PROCESO1,
                CVE_VENDEDOR1,
                CVE_ESPECIAL1,
                IMP_DESC_COMIS1,
                IMP_COM_DIR1,
                CVE_PROCESO2,
                CVE_VENDEDOR2,
                CVE_ESPECIAL2,
                IMP_DESC_COMIS2,
                IMP_COM_DIR2,
                SIT_ITEM_CXC,
                TX_NOTA,
                F_FIN_INSTALACION,
                CVE_RENOVACION)
           values     
               (@cve_empresa,
                @serie,
                @id_cxc,
                @id_item,
                @cve_subproducto,
                @imp_bruto_item,
                @f_inicio,
                @f_fin,
                @imp_est_cxp,
                @imp_real_cxp,
                @cve_proceso1,
                @cve_vendedor1,
                @cve_especial1,
                @imp_desc_comis1,
                @imp_com_dir1,
                @cve_proceso2,
                @cve_vendedor2,
                @cve_especial2,
                @imp_desc_comis2,
                @imp_com_dir2,
                @sit_item_cxc,
                @tx_nota,
                @f_fin_instalacion,
                @k_proc_renov)
 
    set @fol_act  =  (select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_act)
    UPDATE CI_FOLIO
           SET NUM_FOLIO        = @fol_act + 1
           WHERE  CVE_FOLIO     = @k_fol_act

    Insert into CI_ACTUALIZACION 
                (CVE_EMPRESA,
                 SERIE,
                 ID_CXC,
                 ID_ITEM,
                 ID_ACTUALIZACION,
                 F_ACT_PROPUESTA,
                 CVE_ESTADO_PROGRAMA,
                 CVE_PROCESO_ACTUALIZACION,
                 F_ACT_PROGRAMADA,
                 B_ENVIO_ARQUITECTURA,
                 CVE_CONSULTOR,
                 F_ACT_REAL,
                 ID_VERSION,
                 NUM_TICKET,
                 TX_NOTA,
                 SIT_ACTUALIZACION)
    values     
                (@cve_empresa,
                 @serie,
                 @id_cxc,
                 @id_item,
                 @fol_act,
                 @fecha_act_vale1,
                 @k_pend_liberar,
                 @k_pend_liberar,
                 NULL,
                 @k_falso,
                 NULL,
                 NULL,
                 NULL,
                 0,
                 ' ',
                 @k_activa)
 
    IF  @b_gen_segundo  =  @k_verdadero
    BEGIN

      set @fol_act  =  (select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_act)
      UPDATE CI_FOLIO
             SET NUM_FOLIO        = @fol_act + 1
             WHERE  CVE_FOLIO     = @k_fol_act

      Insert into CI_ACTUALIZACION 
                  (CVE_EMPRESA,
                   SERIE,
                   ID_CXC,
                   ID_ITEM,
                   ID_ACTUALIZACION,
                   F_ACT_PROPUESTA,
                   CVE_ESTADO_PROGRAMA,
                   CVE_PROCESO_ACTUALIZACION,
                   F_ACT_PROGRAMADA,
                   B_ENVIO_ARQUITECTURA,
                   CVE_CONSULTOR,
                   F_ACT_REAL,
                   ID_VERSION,
                   NUM_TICKET,
                   TX_NOTA,
                   SIT_ACTUALIZACION)
       values     
                  (@cve_empresa,
                   @serie,
                   @id_cxc,
                   @id_item,
                   @fol_act,
                   @fecha_act_vale2,
                   @k_pend_liberar,
                   @k_pend_liberar,
                   NULL,
                   @k_falso,
                   NULL,
                   NULL,
                   NULL,
                   0,
                   ' ',
                   @k_activa)
    END 
  END
  ELSE
  BEGIN
    set @tx_error = 'Error CI_ITEM_C_X_C : ' + @cve_empresa + '  ' + @SERIE + '  ' + CAST(@id_cxc AS varchar(10)) +
                    ' ' + CAST(@id_item AS varchar(10)) + @tx_error_part
 
    set @fol_audit  =  (select NUM_FOLIO FROM CI_FOLIO WHERE CVE_FOLIO = @k_fol_audit)
    
    UPDATE CI_FOLIO
           SET NUM_FOLIO = @fol_audit + 1
    WHERE  CVE_FOLIO     = @k_fol_audit

    insert into  CI_AUDIT_ERROR (
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

