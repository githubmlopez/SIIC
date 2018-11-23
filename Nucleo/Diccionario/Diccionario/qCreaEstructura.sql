USE [DICCIONARIO]

drop table FC_CONSTR_CAMPO
drop table FC_CONSTRAINT
drop table FC_TABLA_COLUMNA
drop table FC_TABLA 
drop table FC_TABLA_COL_EX
drop table FC_TABLA_EX 
drop table FC_PARAM_FORMA

/*==============================================================*/
/* Table: FC_TABLA                                              */
/*==============================================================*/
create table FC_TABLA (
   NOM_TABLA            varchar(30)          not null,
   constraint PK_FC_TABLA primary key (NOM_TABLA)
)
go

/*==============================================================*/
/* Table: FC_TABLA_COLUMNA                                      */
/*==============================================================*/
create table FC_TABLA_COLUMNA (
   NOM_TABLA            varchar(30)          not null,
   NOM_CAMPO            varchar(30)          not null,
   TIPO_CAMPO           varchar(20)          null,
   LONGITUD             int                  null,
   ENTEROS              int                  null,
   DECIMALES            int                  null,
   POSICION             int                  null,
   B_NULO               bit                  null,
   constraint PK_FC_TABLA_COLUMNA primary key (NOM_TABLA, NOM_CAMPO)
)
go

alter table FC_TABLA_COLUMNA
   add constraint FK_FC_TABLA_REFERENCE_FC_TABLA foreign key (NOM_TABLA)
      references FC_TABLA (NOM_TABLA)
go

/*==============================================================*/
/* Table: FC_CONSTRAINT                                         */
/*==============================================================*/
create table FC_CONSTRAINT (
   NOM_TABLA            varchar(30)          not null,
   NOM_CONSTRAINT       varchar(100)         not null,
   NOM_TABLA_REF        varchar(30)          null,
   TIPO_LLAVE           varchar(2)           not null,
   constraint PK_FC_CONSTRAINT primary key (NOM_TABLA, NOM_CONSTRAINT)
)
go

alter table FC_CONSTRAINT
   add constraint FK_FC_CONST_REFERENCE_FC_TABLA_2 foreign key (NOM_TABLA)
      references FC_TABLA (NOM_TABLA)
go

/*==============================================================*/
/* Table: FC_CONSTR_CAMPO                                       */
/*==============================================================*/
create table FC_CONSTR_CAMPO (
   NOM_TABLA            varchar(30)          not null,
   NOM_CONSTRAINT       varchar(100)         not null,
   NOM_CAMPO            varchar(30)          not null,
   NOM_CAMPO_REF        varchar(30)          null,
   constraint PK_FC_CONSTR_CAMPO primary key (NOM_TABLA, NOM_CONSTRAINT, NOM_CAMPO)
)
go

alter table FC_CONSTR_CAMPO
   add constraint FK_FC_CONST_REFERENCE_FC_CONST foreign key (NOM_TABLA, NOM_CONSTRAINT)
      references FC_CONSTRAINT (NOM_TABLA, NOM_CONSTRAINT)
go

alter table FC_CONSTR_CAMPO
   add constraint FK_FC_CONST_REFERENCE_FC_TABLA_3 foreign key (NOM_TABLA, NOM_CAMPO)
      references FC_TABLA_COLUMNA (NOM_TABLA, NOM_CAMPO)
go

/*==============================================================*/
/* Table: FC_TABLA_EX                                           */
/*==============================================================*/
create table FC_TABLA_EX (
   NOM_TABLA            varchar(30)          not null,
   DESC_TABLA           varchar(30)          null,
   SINONIMO             varchar(6)           null,
   constraint PK_FC_TABLA_EX primary key (NOM_TABLA)
)
go

/*==============================================================*/
/* Table: FC_TABLA_COL_EX                                       */
/*==============================================================*/
create table FC_TABLA_COL_EX (
   NOM_TABLA            varchar(30)          not null,
   NOM_CAMPO            varchar(30)          not null,
   DESC_CAMPO           varchar(200)         null,
   ETIQUETA             varchar(20)          null,
   B_CAPTURA            bit                  null,
   B_BUSCADOR           bit                  null,
   constraint PK_FC_TABLA_COL_EX primary key (NOM_TABLA, NOM_CAMPO)
)
go

alter table FC_TABLA_COL_EX
   add constraint FK_FC_TABLA_REFERENCE_FC_TABLA_4 foreign key (NOM_TABLA)
      references FC_TABLA_EX (NOM_TABLA)
go 

/*==============================================================*/
/* Table: FC_PARAM_FORMA                                        */
/*==============================================================*/
create table FC_PARAM_FORMA (
   BASE_DATOS           varchar(30)          not null,
   NOM_TABLA            varchar(20)          not null,
   NOM_CAMPO            varchar(30)          not null,
   TX_ETIQUETA          varchar(20)          null,
   NOM_ETIQUETA         varchar(30)          null,
   TIPO_COMPONENTE      varchar(4)           null,
   B_REQUERIDO          bit                  null,
   LONG_CAMPO           int                  null,
   LONG_MAXIMA          int                  null,
   SQL_COMPONENTE       int                  null,
   LONG_LOOKUP          int                  null,
   LONG_MAX_LKUP        int                  null,
   SQL_LKUP             int                  null,
   PATRON_UBIC          varchar(4)           null,
   PATRON_UBIC_B        varchar(4)           null,
   PARAM_VALIDA         varchar(4)           null,
   TIPO_CAMPO           varchar(20)          null,
   LONGITUD             int                  null,
   ENTEROS              int                  null,
   DECIMALES            int                  null,
   LINEA                int                  null,
   B_BUSCADOR           bit                  null,
   constraint PK_FC_PARAM_FORMA primary key (BASE_DATOS, NOM_TABLA, NOM_CAMPO)
)
go
