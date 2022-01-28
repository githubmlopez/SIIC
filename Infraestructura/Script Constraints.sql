USE ADMON01
GO

DROP TABLE FC_GEN_PROCESO_BIT

/*==============================================================*/
/* Table: FC_PROCESO_BIT                                        */
/*==============================================================*/
create table dbo.FC_PROCESO_BIT (
   CVE_EMPRESA          varchar(4)           collate SQL_Latin1_General_CP1_CI_AS not null,
   ID_PROCESO           numeric(9)           not null,
   ID_PROC_SEC          int                  identity(1, 1),
   FT_PROCESO           varchar(8)           collate SQL_Latin1_General_CP1_CI_AS not null,
   GPO_TRANSACCION      int                  null,
   constraint PK_FC_GEN_PROCESO_BIT primary key (CVE_EMPRESA, ID_PROCESO, ID_PROC_SEC)
         on "PRIMARY"
)
on "PRIMARY" 

alter table dbo.FC_PROCESO_BIT
   add constraint FK_FC_PROCE_REFERENCE_FC_PROCE foreign key (CVE_EMPRESA, ID_PROCESO)
      references dbo.FC_PROCESO (CVE_EMPRESA, ID_PROCESO)

--------------------------------------------------------------------------------------------
ALTER TABLE FC_CIFRA_CONTROL DROP CONSTRAINT FK_FC_CIFRA_REFERENCE_FC_GEN_P

DELETE FROM dbo.FC_CIFRA_CONTROL

ALTER table dbo.FC_CIFRA_CONTROL
   add constraint FK_FC_CIFRA_REFERENCE_FC_PROCE foreign key (CVE_EMPRESA, ID_PROCESO)
      references dbo.FC_PROCESO (CVE_EMPRESA, ID_PROCESO)
--------------------------------------------------------------------------------------------
ALTER TABLE CI_INDICADOR    DROP CONSTRAINT FK_CI_INDIC_REFERENCE_FC_GEN_P

ALTER TABLE CI_IND_CHEQUERA DROP CONSTRAINT FK_CI_IND_C_REFERENCE_CI_INDIC1

ALTER TABLE CI_INDICA_PERIODO DROP CONSTRAINT FK_CI_INDIC_REFERENCE_CI_INDIC

ALTER TABLE CI_IND_CUENTA DROP CONSTRAINT FK_CI_IND_C_REFERENCE_CI_INDIC

ALTER TABLE CI_MON_INDICA DROP CONSTRAINT FK_CI_MON_I_REFERENCE_CI_INDIC

ALTER TABLE CI_IND_POLIZA DROP CONSTRAINT FK_CI_IND_P_REFERENCE_CI_INDIC

DELETE FROM CI_INDICADOR

ALTER table dbo.CI_IND_CHEQUERA
   add constraint FK_CI_IND_C_REFERENCE_CI_INDIC1 foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)

alter table dbo.CI_INDICA_PERIODO
   add constraint FK_CI_INDIC_REFERENCE_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)

alter table dbo.CI_IND_CUENTA
   add constraint FK_CI_IND_C_REF_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)
go
alter table dbo.CI_MON_INDICA
   add constraint FK_CI_MON_I_REFERENCE_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)
go

alter table dbo.CI_IND_POLIZA
   add constraint FK_CI_IND_P_REFERENCE_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)
go

alter table dbo.CI_IND_MOVIMIENTO
   add constraint FK_CI_IND_M_REFERENCE_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)
go

alter table dbo.CI_IND_CUENTA
   add constraint FK_CI_IND_C_REFERENCE_CI_INDIC foreign key (CVE_EMPRESA, CVE_INDICADOR)
      references dbo.CI_INDICADOR (CVE_EMPRESA, CVE_INDICADOR)
go


ALTER table dbo.CI_INDICADOR
   add constraint FK_CI_INDIC_REFERENCE_FC_PROCE foreign key (CVE_EMPRESA, ID_PROCESO)
      references dbo.FC_PROCESO (CVE_EMPRESA, ID_PROCESO)
go

DROP TABLE FC_GEN_PROCESO