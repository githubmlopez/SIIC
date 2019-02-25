USE [ADNOMINA01]
GO
/****** Calcula deducciones por Periodo ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spRegSueldo')
BEGIN
  DROP  PROCEDURE spRegSueldo
END
GO
--EXEC spRegSueldo 1,1,'MARIO',1,'CU','NOMINA','S','201803',1,10000,' ',' '
CREATE PROCEDURE [dbo].[spRegSueldo]
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
@pCvePuesto       varchar(15),
@pCveTipoEmpleado varchar(2),
@pCveTipoPercep   varchar(2),
@pFIngreso        date,
@pSueldoMensual   numeric(16,2),
@pIdRegFiscal     int,
@pIdTipoCont      int,
@pIdBanco         int,
@pIdJorLab        int,
@pIdRegContrat    int,
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
--  SELECT 'spRegSueldo'
  DECLARE  @gpo_transaccion   int           =  0,
           @dias_mes          int           =  0,
		   @dias_periodo      int           =  0,
		   @dias_trabajados   int           =  0,
		   @num_faltas        int           =  0,
		   @num_incap         int           =  0,
		   @salario_diario    numeric(16,2) =  0,
		   @sueldo_deveng     numeric(16,2) = 0

  DECLARE  @k_verdadero       bit         =  1,
		   @k_falso           bit         =  0,
		   @k_error           varchar(1)  =  'E',
		   @k_cve_sdo         varchar(4)  =  '0011'

  BEGIN TRY

  DELETE FROM NO_PRE_NOMINA  WHERE 
  ANO_PERIODO  =  @pAnoPeriodo  AND
  ID_CLIENTE   =  @pIdCliente   AND
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_EMPLEADO  =  @pIdEmpleado  AND
  CVE_CONCEPTO IN (@k_cve_sdo)

  SET @dias_mes = (SELECT NUM_DIAS_MES FROM NO_EMPRESA  WHERE
                   ID_CLIENTE  =  @pIdCliente  AND
				   CVE_EMPRESA =  @pCveEmpresa)
  
  SELECT @num_faltas = NUM_FALTAS, @num_incap = NUM_INCAPACIDAD,
         @salario_diario = SALARIO_DIARIO
		 FROM NO_INF_EMP_PER WHERE
         ID_CLIENTE      =  @pIdCliente     AND
		 CVE_EMPRESA     =  @pCveEmpresa    AND
		 CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		 ANO_PERIODO     =  @pAnoPeriodo    AND
		 ID_EMPLEADO     =  @pIdEmpleado  

  SET  @dias_periodo  = 
  (SELECT NUM_DIAS_PERIODO FROM NO_PERIODO  WHERE 
          ID_CLIENTE      =  @pIdCliente     AND
		  CVE_EMPRESA     =  @pCveEmpresa    AND
		  CVE_TIPO_NOMINA =  @pCveTipoNomina AND
		  ANO_PERIODO     =  @pAnoPeriodo)

  SET @dias_trabajados = @dias_periodo - @num_faltas - @num_incap
  SET @sueldo_deveng   = @salario_diario * @dias_trabajados

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
  @k_cve_sdo,
  @sueldo_deveng,
  @dias_trabajados,
  0,
  0,
  0,
  ' ',
  ' ',
  @pError OUT,
  @pMsgError OUT

  END TRY

  BEGIN CATCH
    SET  @pError    =  'E- Reg. Sueldo ' + CONVERT(VARCHAR(10), @pIdEmpleado) + '(P)' + ERROR_PROCEDURE() 
    SET  @pMsgError =  LTRIM(@pError + '==> ' + isnull(ERROR_MESSAGE(), ' '))
    EXECUTE spCreaTareaEvento 
    @pIdProceso,
    @pIdTarea,
    @pCodigoUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @k_error,
    @pError,
    @pMsgError
  END CATCH

END