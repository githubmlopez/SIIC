USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegSueldo] (@pIdProceso       numeric(9),
								      @pIdTarea         numeric(9),
									  @pCveUsuario      varchar(8),
									  @pIdCliente       int,
                                      @pCveEmpresa      varchar(4),
								      @pIdEmpleado      int,
								      @pCveTipoNomina   varchar(2),
									  @pAnoPeriodo      varchar(6),
									  @pSueldo          numeric(16,2),
									  @pError           varchar(80) OUT,
									  @pMsgError        varchar(400) OUT)
AS
BEGIN
  DECLARE  @gpo_transaccion   int         =  0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_cve_sdo         varchar(4)  =  'SDO '

  EXEC spInsPreNomina  @pAnoPeriodo,
                       @pIdCliente,
                       @pCveEmpresa,
                       @pCveTipoNomina,
                       @pIdEmpleado,
                       @k_cve_sdo,
                       @pSueldo,            
	                   0,
                       0,
                       @gpo_transaccion,
                       ' '
END