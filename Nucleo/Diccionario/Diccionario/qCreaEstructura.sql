USE [DICCIONARIO]
GO

drop table FC_CONSTR_CAMPO
drop table FC_CONSTRAINT
drop table FC_TABLA_COLUMNA
drop table FC_TABLA 
drop table FC_TABLA_COL_EX
drop table FC_TABLA_EX 

USE DICCIONARIO
GO

/*==============================================================*/
/* Table: FC_TABLA                                              */
/*==============================================================*/
create table dbo.FC_TABLA (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   constraint PK_FC_TABLA primary key (BASE_DATOS, NOM_TABLA)
         on "PRIMARY"
)
on "PRIMARY"
go

/*==============================================================*/
/* Table: FC_TABLA_COLUMNA                                      */
/*==============================================================*/
create table dbo.FC_TABLA_COLUMNA (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_CAMPO            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   TIPO_CAMPO           varchar(20)          collate SQL_Latin1_General_CP1_CI_AS not null,
   LONGITUD             int                  not null,
   ENTEROS              int                  not null,
   DECIMALES            int                  not null,
   POSICION             int                  not null,
   B_NULO               bit                  not null,
   B_IDENTITY           bit                  not null,
   constraint PK_FC_TABLA_COLUMNA primary key (BASE_DATOS, NOM_TABLA, NOM_CAMPO)
         on "PRIMARY"
)
on "PRIMARY"
go

alter table dbo.FC_TABLA_COLUMNA
   add constraint FK_FC_TABLA_REFERENCE_FC_TABLA foreign key (BASE_DATOS, NOM_TABLA)
      references dbo.FC_TABLA (BASE_DATOS, NOM_TABLA)
go

/*==============================================================*/
/* Table: FC_CONSTRAINT                                         */
/*==============================================================*/
create table dbo.FC_CONSTRAINT (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_CONSTRAINT       varchar(100)         collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA_REF        varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   TIPO_LLAVE           varchar(2)           collate SQL_Latin1_General_CP1_CI_AS not null,
   SINONIMO             varchar(1)           collate SQL_Latin1_General_CP1_CI_AS not null,
   PREF_TAB_RECUR       varchar(1)           collate SQL_Latin1_General_CP1_CI_AS not null,
   constraint PK_FC_CONSTRAINT primary key (BASE_DATOS, NOM_TABLA, NOM_CONSTRAINT)
         on "PRIMARY"
)
on "PRIMARY"
go

alter table dbo.FC_CONSTRAINT
   add constraint FK_FC_CONST_REFERENCE_FC_TABLA_2 foreign key (BASE_DATOS, NOM_TABLA)
      references dbo.FC_TABLA (BASE_DATOS, NOM_TABLA)
go

/*==============================================================*/
/* Table: FC_CONSTR_CAMPO                                       */
/*==============================================================*/
create table dbo.FC_CONSTR_CAMPO (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_CONSTRAINT       varchar(100)         collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_CAMPO            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_CAMPO_REF        varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   constraint PK_FC_CONSTR_CAMPO primary key (BASE_DATOS, NOM_TABLA, NOM_CONSTRAINT, NOM_CAMPO)
         on "PRIMARY"
)
on "PRIMARY"
go

alter table dbo.FC_CONSTR_CAMPO
   add constraint FK_FC_CONST_REFERENCE_FC_CONST foreign key (BASE_DATOS, NOM_TABLA, NOM_CONSTRAINT)
      references dbo.FC_CONSTRAINT (BASE_DATOS, NOM_TABLA, NOM_CONSTRAINT)
go

alter table dbo.FC_CONSTR_CAMPO
   add constraint FK_FC_CONST_REFERENCE_FC_TABLA_3 foreign key (BASE_DATOS, NOM_TABLA, NOM_CAMPO)
      references dbo.FC_TABLA_COLUMNA (BASE_DATOS, NOM_TABLA, NOM_CAMPO)
go

/*==============================================================*/
/* Table: FC_TABLA_EX                                           */
/*==============================================================*/
create table dbo.FC_TABLA_EX (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   DESC_TABLA           varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   SINONIMO             varchar(6)           collate SQL_Latin1_General_CP1_CI_AS not null,
   constraint PK_FC_TABLA_EX primary key (BASE_DATOS, NOM_TABLA)
         on "PRIMARY"
)
on "PRIMARY"
go

/*==============================================================*/
/* Table: FC_NOMBRE_SIST                                        */
/*==============================================================*/
create table dbo.FC_NOMBRE_SIST (
   BASE_DATOS           varchar(15)          collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TABLA            varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   CVE_IDIOMA           varchar(1)           collate SQL_Latin1_General_CP1_CI_AS not null,
   NOM_TAB_SIST         varchar(30)          collate SQL_Latin1_General_CP1_CI_AS not null,
   constraint PK_CI_NOMBRE_SIST primary key (BASE_DATOS, NOM_TABLA, CVE_IDIOMA)
         on "PRIMARY"
)
on "PRIMARY"
go

alter table dbo.FC_NOMBRE_SIST
   add constraint FK_FC_NOMBR_REFERENCE_FC_TABLA foreign key (BASE_DATOS, NOM_TABLA)
      references dbo.FC_TABLA_EX (BASE_DATOS, NOM_TABLA)
go

