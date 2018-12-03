USE [ADNOMINA01]
GO
/****** Calcula dias de incapacidad por periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSdoDiaBimAnt] (@pIdCliente       int,
                                        @pCveEmpresa      varchar(4),
									    @pIdEmpleado      int,
									    @pSdi             int OUT, 
										@pSbc            int OUT)
AS
BEGIN
  DECLARE  @sueldo    numeric(16,2)
         
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

  SET  @pSdi  =  @sueldo  *  @pFactIntegracion
  SET  @pSBC  = (@pSdi / @dias_mes) + @pSdoDiaBimAnt

END

