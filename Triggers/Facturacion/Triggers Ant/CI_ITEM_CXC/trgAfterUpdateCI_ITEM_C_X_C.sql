USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
CREATE TRIGGER [dbo].[trgAfterUpdateCI_ITEM_C_X_C] ON [dbo].[CI_ITEM_C_X_C]
AFTER Update
AS

BEGIN

declare
   @cve_empresa         varchar(4),
   @serie               varchar(6),
   @id_cxc              int,
   @id_item             int,
   @cve_subproducto     varchar(8),
   @imp_bruto_item      numeric(12,2),
   @f_inicio            date,
   @f_fin               date,
   @imp_est_cxp         numeric(12,2),
   @imp_real_cxp        numeric(12,2),
   @cve_proceso1        varchar(4),
   @cve_vendedor1       varchar(4),
   @cve_especial1       varchar(2),
   @imp_desc_comis1     numeric(12,2),
   @imp_com_dir1        numeric(12,2),
   @cve_proceso2        varchar(4),
   @cve_vendedor2       varchar(4),
   @cve_especial2       varchar(2),
   @imp_desc_comis2     numeric(12,2),
   @imp_com_dir2        numeric(12,2),
   @sit_item_cxc        varchar(2),
   @tx_nota             varchar(400),
   @f_fin_instalacion   varchar(2),
   @cve_renovacion      int,
   @cve_empresa_reno    varchar(4),
   @serie_reno          varchar(6),
   @id_cxc_reno         int,
   @id_item_reno        int;
  
declare
   @cve_empresa_d       varchar(4),
   @serie_d             varchar(6),
   @id_cxc_d            int,
   @id_item_d           int,
   @cve_subproducto_d   varchar(8),
   @imp_bruto_item_d    numeric(12,2),
   @f_inicio_d          date,
   @f_fin_d             date,
   @imp_est_cxp_d       numeric(12,2),
   @imp_real_cxp_d      numeric(12,2),
   @cve_proceso1_d      varchar(4),
   @cve_vendedor1_d     varchar(4),
   @cve_especial1_d     varchar(2),
   @imp_desc_comis1_d   numeric(12,2),
   @imp_com_dir1_d      numeric(12,2),
   @cve_proceso2_d      varchar(4),
   @cve_vendedor2_d     varchar(4),
   @cve_especial2_d     varchar(2),
   @imp_desc_comis2_d   numeric(12,2),
   @imp_com_dir2_d      numeric(12,2),
   @sit_item_cxc_d      varchar(2),
   @tx_nota_d           varchar(400),
   @f_fin_instalacion_d varchar(2),
   @cve_renovacion_d    int,
   @cve_empresa_reno_d  varchar(4),
   @serie_reno_d        varchar(6),
   @id_cxc_reno_d       int,
   @id_item_reno_d      int;
  
declare  @cve_producto   varchar(4),
         @tx_error       varchar(200),
         @tx_error_part  varchar(200),
         @b_reg_correcto bit,
         @fol_audit      int;
            
declare  @k_renovada     int,
         @k_no_renovada  int,
         @k_activa       varchar(1), 
         @k_cancelada    varchar(1),
         @k_verdadero    bit,
         @k_falso        bit,
         @k_fol_audit    varchar(4);
         
set      @k_renovada    =  2
set      @k_no_renovada =  1
set      @k_verdadero   =  1
set      @k_falso       =  0
set      @k_activa      = 'A'
set      @k_cancelada   = 'C'
set      @k_fol_audit   = 'AUDI';


set @b_reg_correcto   =  @k_verdadero;

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
select   @cve_renovacion    =  i.CVE_RENOVACION from inserted i;
select   @cve_empresa_reno  =  i.CVE_EMPRESA_RENO from inserted i;
select   @serie_reno        =  i.SERIE_RENO from inserted i;
select   @id_cxc_reno       =  i.ID_CXC_RENO from inserted i;
select   @id_item_reno      =  i.ID_ITEM_RENO from inserted i;

-- Inicialización de datos 

select   @cve_empresa_d       =  d.CVE_EMPRESA from deleted d;
select   @serie_d             =  d.SERIE from deleted d;
select   @id_cxc_d            =  d.ID_CXC from deleted d;
select   @id_item_d           =  d.ID_ITEM from deleted d;
select   @cve_subproducto_d   =  d.CVE_SUBPRODUCTO from deleted d;
select   @imp_bruto_item_d    =  d.IMP_BRUTO_ITEM from deleted d;
select   @f_inicio_d          =  d.F_INICIO from deleted d;
select   @f_fin_d             =  d.F_FIN from deleted d;
select   @imp_est_cxp_d       =  d.IMP_EST_CXP from deleted d;
select   @imp_real_cxp_d      =  d.IMP_REAL_CXP from deleted d;
select   @cve_proceso1_d      =  d.CVE_PROCESO1 from deleted d;
select   @cve_vendedor1_d     =  d.CVE_VENDEDOR1 from deleted d;
select   @cve_especial1_d     =  d.CVE_ESPECIAL1 from deleted d;
select   @imp_desc_comis1_d   =  d.IMP_DESC_COMIS1 from deleted d;
select   @imp_com_dir1_d      =  d.IMP_COM_DIR1 from deleted d;
select   @cve_proceso2_d      =  d.CVE_PROCESO2 from deleted d;
select   @cve_vendedor2       =  d.CVE_VENDEDOR2 from deleted d;
select   @cve_especial2_d     =  d.CVE_ESPECIAL2 from deleted d;
select   @imp_desc_comis2_d   =  d.IMP_DESC_COMIS2 from deleted d;
select   @imp_com_dir2_d      =  d.IMP_COM_DIR2 from deleted d;
select   @sit_item_cxc_d      =  d.SIT_ITEM_CXC from deleted d;
select   @tx_nota_d           =  d.TX_NOTA from deleted d;
select   @f_fin_instalacion_d =  d.F_FIN_INSTALACION from deleted d;
select   @cve_renovacion_d    =  d.CVE_RENOVACION from deleted d;
select   @cve_empresa_reno_d  =  d.CVE_EMPRESA_RENO from deleted d;
select   @serie_reno_d        =  d.SERIE_RENO from deleted d;
select   @id_cxc_reno_d       =  d.ID_CXC_RENO from deleted d;
select   @id_item_reno_d      =  d.ID_ITEM_RENO from deleted d;

set @tx_error_part    =  ' '

--set  @cve_producto  =  (SELECT CVE_PRODUCTO FROM CI_SUBPRODUCTO WHERE  CVE_SUBPRODUCTO  =  @cve_subproducto)	

--IF   @cve_producto  IS NULL
--BEGIN
--  set @b_reg_correcto   =  @k_falso;
--  set @tx_error_part    =  @tx_error_part + ': No existe el subproducto';
--END                                          

IF  UPDATE(F_INICIO)  OR  UPDATE(F_FIN)
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
        BEGIN
          IF  DATEDIFF(DAY, @f_inicio, @f_fin) < 90 
          BEGIN
            set @b_reg_correcto   =  @k_falso;
            set @tx_error_part    =  @tx_error_part + ': Inc. en dias/periodo';
          END
        END
      END
    END
END

IF  UPDATE(CVE_VENDEDOR1)  OR  UPDATE(CVE_PROCESO1)  OR  UPDATE(CVE_ESPECIAL1)
BEGIN

  --IF   NOT EXISTS (SELECT * FROM CI_VENDEDOR   WHERE  CVE_VENDEDOR   =  @cve_vendedor1) 
  --BEGIN
  --  set @b_reg_correcto   =  @k_falso;
  --  set @tx_error_part = @tx_error_part + ': Inconsistencia en el vendedor 1';
  --END                                          
  --ELSE
  --BEGIN
    IF  NOT EXISTS (SELECT * FROM CI_PROD_PROCESO  WHERE  CVE_PRODUCTO    =  @cve_producto   and
                                                          CVE_PROCESO     =  @cve_proceso1   and
                                                          CVE_VENDEDOR    =  @cve_vendedor1  and
                                                          CVE_ESPECIAL    =  @cve_especial1) and
                                                          @cve_vendedor1 not in ('GNCO','INFI','NOAN','VESC')  
    BEGIN
      set @b_reg_correcto   =  @k_falso;
      set @tx_error_part = @tx_error_part + ': No existe comision para vendedor1';
    END                                                      
--  END
END

IF  (UPDATE(CVE_VENDEDOR2)  OR  UPDATE(CVE_PROCESO2)  OR  UPDATE(CVE_ESPECIAL2)) and
     @cve_vendedor2 is not null
BEGIN

  --IF   NOT EXISTS (SELECT * FROM CI_VENDEDOR   WHERE  CVE_VENDEDOR   =  @cve_vendedor1) 
  --BEGIN
  --  set @b_reg_correcto   =  @k_falso;
  --  set @tx_error_part = @tx_error_part + ': Inconsistencia en el vendedor 1';
  --END                                          
  --ELSE
  --BEGIN
    IF  NOT EXISTS (SELECT * FROM CI_PROD_PROCESO  WHERE  CVE_PRODUCTO    =  @cve_producto   and
                                                          CVE_PROCESO     =  @cve_proceso2   and
                                                          CVE_VENDEDOR    =  @cve_vendedor2  and
                                                          CVE_ESPECIAL    =  @cve_especial2) and
                                                          @cve_vendedor1 not in ('GNCO','INFI','NOAN','VESC')  
    BEGIN
      set @b_reg_correcto   =  @k_falso;
      set @tx_error_part = @tx_error_part + ': No existe comision para vendedor2';
    END                                                      
--  END
END

--IF  UPDATE(SIT_ITEM_CXC)
--BEGIN
--  IF   @sit_item_cxc not in (@k_activa,@k_cancelada) 
--  BEGIN
--    set @b_reg_correcto   =  @k_falso;
--    set @tx_error_part = @tx_error_part + ': Situacion Incorrecta';
--  END 
--END


IF UPDATE(CVE_EMPRESA_RENO) or UPDATE(SERIE_RENO) or UPDATE(ID_CXC_RENO) or UPDATE(ID_ITEM_RENO)
BEGIN
  IF @cve_empresa_reno is NOT NULL or @serie_reno is NOT NULL or @id_cxc_reno is NOT NULL or @id_item_reno is NOT NULL
  BEGIN
    IF  NOT EXISTS
       (SELECT  1 FROM CI_ITEM_C_X_C  WHERE CVE_EMPRESA  =  @cve_empresa_reno  and
                                            SERIE        =  @serie_reno        and
                                            ID_CXC       =  @id_cxc_reno       and
                                            ID_ITEM      =  @id_item_reno)
    BEGIN
      set @b_reg_correcto   =  @k_falso;
      set @tx_error_part = @tx_error_part + ': La referencia a renovar incorrecta';
    END 
    ELSE
    BEGIN
      set  @k_fol_audit   = 'AUDI';

      IF  (SELECT f.SIT_TRANSACCION FROM CI_FACTURA f WHERE   CVE_EMPRESA  =  @cve_empresa_reno and
                                                             SERIE        =  @serie_reno       and
                                                             ID_CXC       =  @id_cxc_reno) <> @K_ACTIVA
      BEGIN
        set @b_reg_correcto   =  @k_falso;
        set @tx_error_part = @tx_error_part + ': Factura de renovación Cancelada';
      --UPDATE  CI_ITEM_C_X_C  set  CVE_RENOVACION  =  @k_renovada  WHERE   CVE_EMPRESA  =  @cve_empresa_reno and
      --                                                                    SERIE        =  @serie_reno       and
      --                                                                    ID_CXC       =  @id_cxc_reno      and 
      --                                                                    ID_ITEM      =  @id_item_reno 
      END
    END
  END 

  IF @cve_empresa_reno_d is NOT NULL and @serie_reno_d is NOT NULL and @id_cxc_reno_d is NOT NULL and @id_item_reno_d is NOT NULL
  BEGIN
    set  @k_fol_audit   = 'AUDI';

    --UPDATE  CI_ITEM_C_X_C  set  CVE_RENOVACION  =  @k_no_renovada  WHERE   CVE_EMPRESA  =  @cve_empresa_reno_d and
    --                                                                       SERIE        =  @serie_reno_d       and
    --                                                                       ID_CXC       =  @id_cxc_reno_d      and 
    --                                                                       ID_ITEM      =  @id_item_reno_d 
  END
END

IF  @b_reg_correcto   =  @k_falso
BEGIN
  BEGIN
    RAISERROR('ERROR AL ACTUALIZAR TIENE INCONSISTENCIA DE INFORMACION',11,1)
    ROLLBACK TRAN

    set @tx_error = 'Error CI_ITEM_C_X_C : ' + @cve_empresa + '  ' + @serie + '  ' + CAST(@id_cxc AS varchar(10)) +
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
--    COMMIT
  END 
END

END
