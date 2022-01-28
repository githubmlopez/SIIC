USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtEventos')
BEGIN
  DROP  PROCEDURE spObtEventos
END
GO

-- exec  spObtEventos 1, 'CU', 'MARIO', 'SIIC', 23, 49, 0, 0, ' ', ' ' 

--------------------------------------------------------------------------------------------
-- Obtener eventos a partir de una instancia de Proceso                                   --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spObtEventos]  
@pIdCliente     int,
@pCveEmpresa    varchar(4),
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pIdProceso     numeric(9),
@pFolioExe      int,
@pIdTarea       int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

SELECT p.NOMBRE_PROCESO, e.F_EJECUCION, e.H_INICIO, te.ID_TAREA, te.ID_EVENTO, te.CVE_TIPO_EVENTO, MSG_ERROR 
FROM FC_PROCESO p, FC_PROC_EXEC e, FC_TAREA t, FC_TAREA_EVENTO te
WHERE  
p.CVE_EMPRESA        =  @pCveEmpresa     AND
p.ID_PROCESO         =  @pIdProceso      AND
e.CVE_EMPRESA        =  p.CVE_EMPRESA    AND
e.ID_PROCESO         =  p.ID_PROCESO     AND
e.FOLIO_EXEC         =  @pFolioExe       AND
t.CVE_EMPRESA        =  e.CVE_EMPRESA    AND
t.ID_PROCESO         =  e.ID_PROCESO     AND
t.FOLIO_EXEC         =  e.FOLIO_EXEC     AND
te.CVE_EMPRESA       =  t.CVE_EMPRESA    AND
te.ID_PROCESO        =  t.ID_PROCESO     AND
te.FOLIO_EXEC        =  t.FOLIO_EXEC     AND
te.ID_TAREA          =  t.ID_TAREA       AND
(te.ID_TAREA         =  @pIdTarea        OR
 ISNULL(@pIdTarea,0) =  0)  

END
