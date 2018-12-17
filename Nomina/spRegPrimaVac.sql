USE [ADNOMINA01]
GO
/****** Calcula Cuotas Obrero Patronales ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegPrimaVac')
BEGIN
  DROP  PROCEDURE spRegPrimaVac
END
GO
--EXEC spRegPrimaVac 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '

CREATE PROCEDURE [dbo].[spRegPrimaVac]   
(
@pIdProceso       numeric(9),
@pIdTarea         numeric(9),
@pCodigoUsuario   varchar(20),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pIdEmpleado      int,
@pZona            int,
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
  DECLARE  @imp_concepto  numeric(16,2)

  DECLARE  @k_prima_vac   varchar(4)  =  '11'

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_prima_vac)

  IF  ISNULL((SELECT DIAS_PRIMA_VAC FROM NO_INF_EMP_PER
             WHERE  ID_CLIENTE      =  @pIdCliente     AND
			        CVE_EMPRESA     =  @pCveEmpresa    AND
 			        ID_EMPLEADO     =  @pIdEmpleado    AND
					CVE_TIPO_NOMINA =  @pCveTipoNomina AND
					ANO_PERIODO     =  @pAnoPeriodo),0) <> 0
  BEGIN
    SET  @imp_concepto  =  ISNULL((SELECT (PJE_PRIMA_VAC / 100)   FROM NO_EMPRESA
                           WHERE  ID_CLIENTE  =  @pIdCliente  AND
	                              CVE_EMPRESA =  @pCveEmpresa),0)  *
                          (SELECT DIAS_PRIMA_VAC * (@pSueldoMensual / 30) FROM NO_INF_EMP_PER
                           WHERE  ID_CLIENTE      =  @pIdCliente     AND
						          CVE_EMPRESA     =  @pCveEmpresa    AND
 						          ID_EMPLEADO     =  @pIdEmpleado    AND
							      CVE_TIPO_NOMINA =  @pCveTipoNomina AND
							      ANO_PERIODO     =  @pAnoPeriodo)

    EXEC spInsPreNomina  
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @pIdEmpleado,
    @k_prima_vac,
    @imp_concepto,
    0,
    0,
    0,
    ' ',
    ' ',
    @pError OUT,
    @pMsgError OUT

  END

END

