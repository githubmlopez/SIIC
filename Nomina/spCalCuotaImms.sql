USE [ADNOMINA01]
GO
/****** Calcula cuotas del IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spCalCuotaImms')
BEGIN
  DROP  PROCEDURE spCalCuotaImms
END
GO
--EXEC spCalCuotaImms 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,842.894918,' ',' '
CREATE PROCEDURE [dbo].[spCalCuotaImms]
(										 
@pIdProceso       int,
@pIdTarea         int,
@pCodigoUsuario   varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pSBC             numeric(16,6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN

  DECLARE  @NunRegistros      int, 
           @RowCount          int

  DECLARE  @cve_entidad       varchar(4),
		   @id_ramo           int,
		   @id_concepto       int

-------------------------------------------------------------------------------
-- Calculo de Conceptos para IMSS - INFONAVIT - SAR
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TConcImss        TABLE
          (RowID             int  identity(1,1),
		   CVE_ENTIDAD       varchar(4),
		   ID_RAMO           int,
		   ID_CONCEPTO       int)

  INSERT  @TConcImss (CVE_ENTIDAD, ID_RAMO, ID_CONCEPTO) 
  SELECT  c.CVE_ENTIDAD, c.ID_RAMO, c.ID_CONCEPTO
  FROM    NO_CONC_CUOTA c

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_entidad = c.CVE_ENTIDAD, @id_ramo = c.ID_RAMO, @id_concepto = c.ID_CONCEPTO
	FROM   @TConcImss c   WHERE  RowID = @RowCount

	EXEC spCalCuotObrPat        
    @pIdProceso,
    @pIdTarea,
	@pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @cve_entidad,
    @id_ramo,
    @id_concepto,
    @pSBC,
    @pError OUT,
    @pMsgError OUT

    SET @RowCount     = @RowCount + 1
  END
END

