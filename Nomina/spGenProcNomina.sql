USE [ADNOMINA01]
GO
/****** Proceso para generar de Cuotas para el IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spGenProcNomina')
BEGIN
  DROP  PROCEDURE spGenProcNomina
END
GO
-- EXEC spGenProcNomina 1,1,'MARIO',1,'CU','NOMINA','S','201803',' ',' '
CREATE PROCEDURE [dbo].[spGenProcNomina] 
(
@pIdProceso       int,
@pIdTarea         int,
@pCodigoUsuario   varchar(10),
@pIdCliente       int,
@pCveEmpresa      varchar(4),
@pCveAplicacion   varchar(10),
@pCveTipoNomina   varchar(2),
@pAnoPeriodo      varchar(6),
@pError           varchar(80) OUT,
@pMsgError        varchar(400) OUT
)
AS
BEGIN
--  SELECT 'ENTRE A PROCESAR PROCEDIMIENTO'
  DECLARE  @id_cliente		   int,                
           @cve_empresa        varchar(4),         
           @id_empleado        int,                 
           @cve_tipo_nomina    varchar(2),          
           @zona               int,                 
           @cve_puesto         varchar(15),
           @cve_tipo_empleado  varchar(2),          
           @cve_tipo_percep    varchar(2),          
           @f_ingreso          date,                
           @sueldo_mensual     numeric(16,2),       
           @id_reg_fiscal      numeric(16,2),
           @id_tipo_cont       int,
		   @id_banco           int,
           @id_jor_lab         int,
           @id_reg_contrat     int

  DECLARE  @NunRegistros      int   =  0, 
           @RowCount          int   =  0,
		   @store_proc        varchar(30),
		   @sql               nvarchar(max),
		   @parametros        nvarchar(max)

  DECLARE  @dias_falta        int   =  0,
           @dias_incap        int   =  0

  DECLARE  @k_verdadero       bit   =  1,
           @k_falso           bit   =  0,
		   @k_error           varchar(1) = 'W'

-------------------------------------------------------------------------------
-- Generacion de Empleados 
-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- No meter instrucciones intermedias en este bloque porque altera el funcionamiento del @@ROWCOUNT 
-----------------------------------------------------------------------------------------------------
  DECLARE  @TEmpleado           TABLE
          (RowID                int  identity(1,1),            
		   ID_CLIENTE           int,                
           CVE_EMPRESA          varchar(4),         
           ID_EMPLEADO          int,                 
           CVE_TIPO_NOMINA      varchar(2),          
           ZONA                 int,       
		   CVE_PUESTO           varchar(15),          
           CVE_TIPO_EMPLEADO    varchar(2),          
           CVE_TIPO_PERCEP      varchar(2),          
           F_INGRESO            date,                
           SUELDO_MENSUAL       numeric(16,2),       
           ID_REG_FISCAL        int,
           ID_TIPO_CONT         int,
		   ID_BANCO             int,
           ID_JOR_LAB           int,
           ID_REG_CONTRAT       int,
           SALARIO_BASE         int,
           SALARIO_DIARIO       int)

  INSERT  @TEmpleado(
  ID_CLIENTE,
  CVE_EMPRESA, 
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  ZONA,       
  CVE_PUESTO,          
  CVE_TIPO_EMPLEADO,          
  CVE_TIPO_PERCEP,          
  F_INGRESO,                
  SUELDO_MENSUAL,       
  ID_REG_FISCAL,
  ID_TIPO_CONT,
  ID_BANCO,
  ID_JOR_LAB,
  ID_REG_CONTRAT,
  SALARIO_BASE,
  SALARIO_DIARIO)
  SELECT
  ID_CLIENTE,
  CVE_EMPRESA, 
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  ZONA,       
  CVE_PUESTO,          
  CVE_TIPO_EMPLEADO,          
  CVE_TIPO_PERCEP,          
  F_INGRESO,                
  SUELDO_MENSUAL,       
  ID_REG_FISCAL,
  ID_TIPO_CONT,
  ID_BANCO,
  ID_JOR_LAB,
  ID_REG_CONTRAT,
  SALARIO_BASE,
  SALARIO_DIARIO
  FROM    NO_EMPLEADO e
  WHERE
  e.ID_CLIENTE       = @pIdCliente      AND
  e.CVE_EMPRESA      = @pCveEmpresa     AND
  e.CVE_TIPO_NOMINA  = @pCveTipoNomina  
 
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_cliente		 =  ID_CLIENTE,                
           @cve_empresa        =  CVE_EMPRESA,         
           @id_empleado        =  ID_EMPLEADO,                 
           @cve_tipo_nomina    =  CVE_TIPO_NOMINA,          
           @zona               =  ZONA,                 
           @cve_puesto         =  CVE_PUESTO,
           @cve_tipo_empleado  =  CVE_TIPO_EMPLEADO,        
           @cve_tipo_percep    =  CVE_TIPO_PERCEP,          
           @f_ingreso          =  F_INGRESO,                
           @sueldo_mensual     =  SUELDO_MENSUAL,       
           @id_reg_fiscal      =  ID_REG_FISCAL,
           @id_tipo_cont       =  ID_TIPO_CONT,
		   @id_banco           =  ID_BANCO,
           @id_jor_lab         =  ID_JOR_LAB,
           @id_reg_contrat     =  ID_REG_CONTRAT
		   FROM  @TEmpleado  WHERE  RowID  =  @RowCount   

    SELECT @store_proc = LTRIM(PARAMETRO)  FROM FC_GEN_PROCESO WHERE
	ID_CLIENTE     =  @pIdCliente  AND
	CVE_EMPRESA    =  @pCveEmpresa AND
	CVE_APLICACION =  @pCveAplicacion AND
	ID_PROCESO     =  @pIdProceso

    BEGIN TRY
	
	SET @sql = N'EXEC ' + @store_proc +  
	N' @IdProceso_p,@IdTarea_p,@CveUsuario_p,@IdCliente_p,@CveEmpresa_p,@CveAplicacion_p,' + 
	N'@CveTipoNomina_p,@AnoPeriodo_p,@IdEmpleado_p,@Zona_p,@CvePuesto_p,@CveTipoEmpleado_p,' +
	N'@CveTipoPercep_p,@FIngreso_p,@SueldoMensual_p,@IdRegFiscal_p,@IdTipoCont_p, @IdBanco_p,' +
	N'@IdJorLab_p, @IdRegContrat_p,@Error_p OUTPUT,@MsgError_p OUTPUT'
	SET @parametros =
	N' @IdProceso_p numeric(9,0),@IdTarea_p numeric(9,0),@CveUsuario_p varchar(10),' +
	N'@IdCliente_p int,@CveEmpresa_p varchar(4),@CveAplicacion_p varchar(10),' +
	N'@CveTipoNomina_p varchar(2),@AnoPeriodo_p varchar(6),@IdEmpleado_p int,' +
	N'@Zona_p int,@CvePuesto_p varchar(15),@CveTipoEmpleado_p varchar(2),' +
	N'@CveTipoPercep_p varchar(2),@FIngreso_p date,@SueldoMensual_p numeric(16,2),' +
	N'@IdRegFiscal_p int,@IdTipoCont_p int, @IdBanco_p int,' +
	N'@IdJorLab_p int, @IdRegContrat_p int, ' +
	N'@Error_p varchar(80) OUTPUT,@MsgError_p varchar(400) OUTPUT'

--	SELECT @sql
--	SELECT @parametros

	 EXEC sp_executesql @sql, @parametros,
	 @IdProceso_p       = @pIdProceso,
	 @IdTarea_p         = @pIdTarea,
	 @CveUsuario_p      = @pCodigoUsuario,
	 @IdCliente_p       = @pIdCliente,  
	 @CveEmpresa_p      = @pCveEmpresa,
	 @CveAplicacion_p   = @pCveAplicacion,
	 @CveTipoNomina_p   = @pCveTipoNomina,
	 @AnoPeriodo_p      = @pAnoPeriodo,   
	 @IdEmpleado_p      = @id_empleado,
	 @Zona_p            = @zona,
	 @CvePuesto_p       = @cve_puesto,
	 @CveTipoEmpleado_p = @cve_tipo_empleado,
	 @CveTipoPercep_p   = @cve_tipo_percep, 
	 @FIngreso_p        = @f_ingreso,
	 @SueldoMensual_p   = @sueldo_mensual,
	 @IdJorLab          = @id_jor_lab,
	 @idRegContrat_p    = @id_reg_contrat,
	 @Error_p           = @pError OUTPUT,
	 @MsgError_p        = @pMsgError OUTPUT 

	 END TRY
	 BEGIN CATCH
       SET  @pError    =  'E- Al Lanzar proc. ' + @store_proc + '(P)' + ERROR_PROCEDURE() 
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
    SET @RowCount     = @RowCount + 1
  END

END

