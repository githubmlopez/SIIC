USE ADMON01

DROP TABLE FC_MENU
DROP TABLE FC_SEG_CAPACIDAD
DROP TABLE FC_SEG_APLICACION

/*==============================================================*/
/* Table: FC_SEG_APLICACION                                     */
/*==============================================================*/
create table dbo.FC_SEG_APLICACION (
   CODIGO_APLICACION    varchar(20)          collate Traditional_Spanish_CI_AS not null,
   NOMBRE_APLICACION    varchar(100)         collate Traditional_Spanish_CI_AS not null,
   COD_USUARIO_RESP     varchar(20)          collate Traditional_Spanish_CI_AS not null,
   FH_REGISTRO          datetime             not null,
   COD_USUARIO_REG      varchar(20)          collate Traditional_Spanish_CI_AS not null,
   FH_ULT_MOD           datetime             null,
   COD_USUARIO_ULT_MOD  varchar(20)          collate Traditional_Spanish_CI_AS null,
   SIT_APLICACION       varchar(1)           collate Traditional_Spanish_CI_AS not null
      constraint CK01_CF_SEG_Aplicacion check (SIT_APLICACION in ('A','I')),
   constraint PK_CF_SEG_APLICACION primary key (CODIGO_APLICACION)
         on "PRIMARY"
)
on "PRIMARY"
go



/*==============================================================*/
/* Table: FC_SEG_CAPACIDAD                                      */
/*==============================================================*/
create table dbo.FC_SEG_CAPACIDAD (
   CODIGO_APLICACION    varchar(20)          collate Traditional_Spanish_CI_AS not null,
   CODIGO_CAPACIDAD     varchar(100)         collate Traditional_Spanish_CI_AS not null,
   DESC_CAPACIDAD       varchar(500)         collate Traditional_Spanish_CI_AS not null,
   FH_REGISTRO          datetime             not null,
   COD_USUARIO_REG      varchar(20)          collate Traditional_Spanish_CI_AS not null,
   FH_ULT_MOD           datetime             null,
   COD_USUARIO_ULT_MOD  varchar(20)          collate Traditional_Spanish_CI_AS null,
   constraint PK_CF_SEG_CAPACIDAD primary key (CODIGO_APLICACION, CODIGO_CAPACIDAD)
         on "PRIMARY"
)
on "PRIMARY"
go

alter table dbo.FC_SEG_CAPACIDAD
   add constraint FK_CF_SEG_C_REF_27_CF_SEG_A foreign key (CODIGO_APLICACION)
      references dbo.FC_SEG_APLICACION (Codigo_Aplicacion)
go


/*==============================================================*/
/* Table: FC_MENU                                               */
/*==============================================================*/
create table FC_MENU (
   CODIGO_APLICACION    varchar(20)          not null,
   CODIGO_CAPACIDAD     varchar(100)         not null,
   CODIGO_APLICACION_P  varchar(20)          null,
   CODIGO_CAPACIDAD_P   varchar(100)         null,
   URL                  varchar(200)         null,
   constraint PK_FC_MENU primary key (CODIGO_APLICACION, CODIGO_CAPACIDAD)
)
go

alter table FC_MENU
   add constraint FK_FC_MENU_REFERENCE_FC_SEG_C foreign key (CODIGO_APLICACION, CODIGO_CAPACIDAD)
      references dbo.FC_SEG_CAPACIDAD (CODIGO_APLICACION, CODIGO_CAPACIDAD)
go

alter table FC_MENU
   add constraint FK_FC_MENU_REFERENCE_FC_MENU foreign key (CODIGO_APLICACION_P, CODIGO_CAPACIDAD_P)
      references FC_MENU (CODIGO_APLICACION, CODIGO_CAPACIDAD)
go

-- Creación de registros FC_SEG_APLICACION

INSERT INTO [ADMON01].[dbo].[FC_SEG_APLICACION]
           ([CODIGO_APLICACION]
           ,[NOMBRE_APLICACION]
           ,[COD_USUARIO_RESP]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD]
           ,[SIT_APLICACION])
     VALUES
           ('SECU'
           ,'SISTEMA DE SEGURIDADES'
           ,'MLOPEZ'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL
           ,'A')
GO

-- Creación de registros FC_SEG_CAPACIDAD

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_root'
           ,'Descrip. Level Root'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1'
           ,'Descrip. Level MN_r-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2'
           ,'Descrip. Level MN_r-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3'
           ,'Descrip. Level MN_r-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4'
           ,'Descrip. Level MN_r-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5'
           ,'Descrip. Level MN_r-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1-1'
           ,'Descrip. Level MN_r-1-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1-2'
           ,'Descrip. Level MN_r-1-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1-3'
           ,'Descrip. Level MN_r-1-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1-4'
           ,'Descrip. Level MN_r-1-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-1-5'
           ,'Descrip. Level MN_r-1-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

---
INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2-1'
           ,'Descrip. Level MN_r-2-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2-2'
           ,'Descrip. Level MN_r-2-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2-3'
           ,'Descrip. Level MN_r-2-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2-4'
           ,'Descrip. Level MN_r-2-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-2-5'
           ,'Descrip. Level MN_r-2-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO


----

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3-1'
           ,'Descrip. Level MN_r-3-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3-2'
           ,'Descrip. Level MN_r-3-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3-3'
           ,'Descrip. Level MN_r-3-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3-4'
           ,'Descrip. Level MN_r-3-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-3-5'
           ,'Descrip. Level MN_r-3-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4-1'
           ,'Descrip. Level MN_r-4-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4-2'
           ,'Descrip. Level MN_r-4-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4-3'
           ,'Descrip. Level MN_r-4-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4-4'
           ,'Descrip. Level MN_r-4-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-4-5'
           ,'Descrip. Level MN_r-4-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5-1'
           ,'Descrip. Level MN_r-5-1'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5-2'
           ,'Descrip. Level MN_r-5-2'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5-3'
           ,'Descrip. Level MN_r-5-3'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5-4'
           ,'Descrip. Level MN_r-5-4'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)
GO

INSERT INTO [ADMON01].[dbo].[FC_SEG_CAPACIDAD]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[DESC_CAPACIDAD]
           ,[FH_REGISTRO]
           ,[COD_USUARIO_REG]
           ,[FH_ULT_MOD]
           ,[COD_USUARIO_ULT_MOD])
     VALUES
           ('SECU'
           ,'MN_r-5-5'
           ,'Descrip. Level MN_r-5-5'
           ,'2017-04-17'
           ,'MLOPEZ'
           ,NULL
           ,NULL)

-- Creación de registros FC_MENU

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_root'
           ,NULL
           ,NULL
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1'
           ,'SECU'
           ,'MN_root'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2'
           ,'SECU'
           ,'MN_root'
           ,'url/prueba')
GO


INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3'
           ,'SECU'
           ,'MN_root'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4'
           ,'SECU'
           ,'MN_root'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5'
           ,'SECU'
           ,'MN_root'
           ,'url/prueba')
GO

---

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1-1'
           ,'SECU'
           ,'MN_r-1'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1-2'
           ,'SECU'
           ,'MN_r-1'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1-3'
           ,'SECU'
           ,'MN_r-1'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1-4'
           ,'SECU'
           ,'MN_r-1'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-1-5'
           ,'SECU'
           ,'MN_r-1'
           ,'url/prueba')
GO

----

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2-1'
           ,'SECU'
           ,'MN_r-2'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2-2'
           ,'SECU'
           ,'MN_r-2'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2-3'
           ,'SECU'
           ,'MN_r-2'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2-4'
           ,'SECU'
           ,'MN_r-2'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-2-5'
           ,'SECU'
           ,'MN_r-2'
           ,'url/prueba')
GO

---

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3-1'
           ,'SECU'
           ,'MN_r-3'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3-2'
           ,'SECU'
           ,'MN_r-3'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3-3'
           ,'SECU'
           ,'MN_r-3'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3-4'
           ,'SECU'
           ,'MN_r-3'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-3-5'
           ,'SECU'
           ,'MN_r-3'
           ,'url/prueba')
GO

---

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4-1'
           ,'SECU'
           ,'MN_r-4'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4-2'
           ,'SECU'
           ,'MN_r-4'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4-3'
           ,'SECU'
           ,'MN_r-4'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4-4'
           ,'SECU'
           ,'MN_r-4'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-4-5'
           ,'SECU'
           ,'MN_r-4'
           ,'url/prueba')
GO

---

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5-1'
           ,'SECU'
           ,'MN_r-5'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5-2'
           ,'SECU'
           ,'MN_r-5'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5-3'
           ,'SECU'
           ,'MN_r-5'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5-4'
           ,'SECU'
           ,'MN_r-5'
           ,'url/prueba')
GO

INSERT INTO [ADMON01].[dbo].[FC_MENU]
           ([CODIGO_APLICACION]
           ,[CODIGO_CAPACIDAD]
           ,[CODIGO_APLICACION_P]
           ,[CODIGO_CAPACIDAD_P]
           ,[URL])
     VALUES
           ('SECU'
           ,'MN_r-5-5'
           ,'SECU'
           ,'MN_r-5'
           ,'url/prueba')
GO

--

WITH EstMenu (CODIGO_APLICACION, CODIGO_CAPACIDAD, CODIGO_APLICACION_P, CODIGO_CAPACIDAD_P ,
DESC_CAPACIDAD, Level, URL)
AS
(
-- Definición de Miembro Ancla
    SELECT m.CODIGO_APLICACION, m.CODIGO_CAPACIDAD, m.CODIGO_APLICACION_P, m.CODIGO_CAPACIDAD_P, 
        c.DESC_CAPACIDAD, 0 AS Level, m.URL
    FROM FC_MENU AS m
    INNER JOIN  FC_SEG_CAPACIDAD AS c
          ON m.CODIGO_APLICACION = c.CODIGO_APLICACION AND m.CODIGO_CAPACIDAD = c.CODIGO_CAPACIDAD
    WHERE  m.CODIGO_APLICACION_P IS NULL and m.CODIGO_CAPACIDAD_P IS NULL
    UNION ALL
-- Definición de Miembro Recursivo
    SELECT m.CODIGO_APLICACION, m.CODIGO_CAPACIDAD, m.CODIGO_APLICACION_P, m.CODIGO_CAPACIDAD_P,
        c.DESC_CAPACIDAD, Level + 1, m.URL
    FROM FC_MENU AS m
    INNER JOIN  FC_SEG_CAPACIDAD AS c
          ON m.CODIGO_APLICACION = c.CODIGO_APLICACION AND m.CODIGO_CAPACIDAD = c.CODIGO_CAPACIDAD
    INNER JOIN EstMenu AS d
        ON m.CODIGO_APLICACION_P = d.CODIGO_APLICACION and m.CODIGO_CAPACIDAD_P = d.CODIGO_CAPACIDAD
)
-- Instrucción que ejecuta el CTE

SELECT e.CODIGO_APLICACION, e.CODIGO_CAPACIDAD, e.CODIGO_APLICACION_P, e.CODIGO_CAPACIDAD_P , e.DESC_CAPACIDAD,
e.Level, e.URL,
case 
when (select count(*) from EstMenu es where es.CODIGO_CAPACIDAD_P = e.CODIGO_CAPACIDAD) = 0
then '1'
else '0'
end as 'ultimo'
FROM EstMenu e
OPTION (MAXRECURSION 500);
GO
