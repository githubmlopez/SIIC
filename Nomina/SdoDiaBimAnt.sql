USE [ADNOMINA01]
GO
/****** Calcula dias de incapacidad por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spSdoDiaBimAnt')
BEGIN
  DROP  PROCEDURE spSdoDiaBimAnt
END
GO
-- EXEC spSdoDiaBimAnt 1,1,1,'CU','NOMINA','S','201801',1,1.0519,737.7049,0,0,' ',' '
CREATE PROCEDURE [dbo].[spSdoDiaBimAnt]
(@pIdProceso       int,
 @pIdTarea         int,
 @pIdCliente       int,
 @pCveEmpresa      varchar(4),
 @pCveAplicacion   varchar(10),
 @pCveTipoNomina   varchar(2),
 @pAnoPeriodo      varchar(6),
 @pIdEmpleado      int,
 @pFactIntegracion numeric(16,6),
 @pSdoDiaBimAnt    numeric(16,6),
 @pSdi             numeric(16,6) OUT, 
 @pSbc             numeric(16,6)OUT, 
 @pError           varchar(80) OUT,
 @pMsgError        varchar(400) OUT)

AS
BEGIN
  DECLARE  @sueldo    numeric(16,2),
           @dias_mes  varchar(6)
         
  IF EXISTS(
  SELECT 1 FROM NO_EMPLEADO e  WHERE 
  e.ID_CLIENTE      = @pIdCliente      AND
  e.CVE_EMPRESA     = @pCveEmpresa     AND
  e.ID_EMPLEADO     = @pIdEmpleado)      
  BEGIN
      SELECT @sueldo =  SUELDO_MENSUAL
      FROM NO_EMPLEADO e  WHERE 
      e.ID_CLIENTE      = @pIdCliente      AND
      e.CVE_EMPRESA     = @pCveEmpresa     AND
      e.ID_EMPLEADO     = @pIdEmpleado      
  END
  ELSE
  BEGIN
    SET  @sueldo    =  0
  END

  SELECT @dias_mes = DIAS_MES_FIN  FROM  NO_PERIODO  WHERE 
  ID_CLIENTE      =  @pIdCliente  AND
  CVE_EMPRESA     =  @pCveEmpresa AND
  CVE_TIPO_NOMINA =  @pCveTipoNomina  AND
  ANO_PERIODO     =  @pAnoPeriodo

  SET  @pSdi  =  @sueldo  *  @pFactIntegracion
  SET  @pSBC  = (@pSdi / @dias_mes) + @pSdoDiaBimAnt

END

