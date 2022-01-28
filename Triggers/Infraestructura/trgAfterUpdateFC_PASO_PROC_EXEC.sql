USE [ADMON01]
GO
/****** Object:  Trigger [dbo].[trgInsteadOfInsertCXCI]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
ALTER TRIGGER [dbo].[trgAfterUpdateFC_PASO_PROC_EXEC] ON [dbo].[FC_PASO_PROC_EXEC]
AFTER UPDATE
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
     @periodo_d      varchar(10),
     @cve_empresa_d  varchar(4),
     @id_etapa_d     int,
     @id_paso_d      int,
     @id_proceso_d   numeric(9),
     @folio_exec_d   int,
     @sit_proceso_d  varchar(2)
  
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

-- Inicialización de datos 

  SELECT @periodo_d     =  d.PERIODO     FROM deleted d
  SELECT @cve_empresa_d =  d.CVE_EMPRESA FROM deleted d
  SELECT @id_etapa_d    =  d.ID_ETAPA    FROM deleted d
  SELECT @id_paso_d     =  d.ID_PASO     FROM inserted d
  SELECT @id_proceso_d  =  d.ID_PROCESO  FROM inserted d
  SELECT @folio_exec_d  =  d.FOLIO_EXEC  FROM inserted d
  SELECT @sit_proceso_d =  d.SIT_PROCESO FROM inserted d

  IF  UPDATE(SIT_PROCESO)  
  BEGIN
    EXEC spRecSitPasoEtapa @periodo, @cve_empresa, @id_etapa, @id_paso  
  END
END