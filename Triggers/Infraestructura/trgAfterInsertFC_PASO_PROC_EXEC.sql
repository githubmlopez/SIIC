USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[trgAfterInsertFC_PASO_PROC_EXEC] ON [dbo].[FC_PASO_PROC_EXEC]
AFTER INSERT
AS

BEGIN

  DECLARE
     @periodo        varchar(10),
     @cve_empresa    varchar(4),
     @id_etapa       int,
     @id_paso        int,
     @id_proceso     numeric(9),
     @folio_exec     int,
     @sit_proceso    varchar(2)

  DECLARE
     @k_verdadero    bit = 1,
     @k_falso        bit = 0
         

-- Inicialización de datos 

  SELECT @periodo       =  i.PERIODO     FROM inserted i
  SELECT @cve_empresa   =  i.CVE_EMPRESA FROM inserted i
  SELECT @id_etapa      =  i.ID_ETAPA    FROM inserted i
  SELECT @id_paso       =  i.ID_PASO     FROM inserted i
  SELECT @id_proceso    =  i.ID_PROCESO  FROM inserted i
  SELECT @folio_exec    =  i.FOLIO_EXEC  FROM inserted i
  SELECT @sit_proceso   =  i.SIT_PROCESO FROM inserted i

  EXEC spRecSitPasoEtapa @periodo, @cve_empresa, @id_etapa, @id_paso  

END