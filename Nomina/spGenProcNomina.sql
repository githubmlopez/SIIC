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
           @cve_tipo_empleado  varchar(2),          
           @cve_tipo_percep    varchar(2),          
           @nom_empleado       varchar(100),        
           @f_ingreso          date,                
           @curp               varchar(18),         
           @rfc                varchar(13),         
           @no_imss            varchar(11),         
           @sueldo_mensual     numeric(16,2),       
           @cve_vendedor       varchar(4),          
           @domicilio          varchar(200),        
           @tel_celular        varchar(20),         
           @tel_casa           varchar(20),         
           @sit_empleado       varchar(1)    
  

  DECLARE  @NunRegistros      int   =  0, 
           @RowCount          int   =  0,
		   @store_proc        varchar(30),
		   @sql               nvarchar(max),
		   @parametros        nvarchar(max)

  DECLARE  @dias_falta        int   =  0,
           @dias_incap        int   =  0

  DECLARE  @k_verdadero       bit   =  1,
           @k_falso           bit   =  0

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
           CVE_TIPO_EMPLEADO    varchar(2),          
           CVE_TIPO_PERCEP      varchar(2),          
           NOM_EMPLEADO         varchar(100),        
           F_INGRESO            date,                
           CURP                 varchar(18),         
           RFC                  varchar(13),         
           NO_IMSS              varchar(11),         
           SUELDO_MENSUAL       numeric(16,2),       
           CVE_VENDEDOR         varchar(4),          
           DOMICILIO            varchar(200),        
           TEL_CELULAR          varchar(20),         
           TEL_CASA             varchar(20),         
           SIT_EMPLEADO         varchar(1))     

  INSERT  @TEmpleado(
  ID_CLIENTE,
  CVE_EMPRESA, 
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  ZONA,           
  CVE_TIPO_EMPLEADO,
  CVE_TIPO_PERCEP,
  NOM_EMPLEADO,    
  F_INGRESO,       
  CURP,       
  RFC,             
  NO_IMSS,         
  SUELDO_MENSUAL,  
  CVE_VENDEDOR,    
  DOMICILIO,       
  TEL_CELULAR,     
  TEL_CASA,        
  SIT_EMPLEADO)     
  SELECT
  ID_CLIENTE,
  CVE_EMPRESA, 
  ID_EMPLEADO,
  CVE_TIPO_NOMINA,
  ZONA,           
  CVE_TIPO_EMPLEADO,
  CVE_TIPO_PERCEP,
  NOM_EMPLEADO,    
  F_INGRESO,       
  CURP,       
  RFC,             
  NO_IMSS,         
  SUELDO_MENSUAL,  
  CVE_VENDEDOR,    
  DOMICILIO,       
  TEL_CELULAR,     
  TEL_CASA,        
  SIT_EMPLEADO  
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
           @cve_tipo_empleado  =  CVE_TIPO_EMPLEADO,      
           @cve_tipo_percep    =  CVE_TIPO_PERCEP,          
           @nom_empleado       =  NOM_EMPLEADO,        
           @f_ingreso          =  F_INGRESO,                
           @curp               =  CURP,         
           @rfc                =  RFC,         
           @no_imss            =  NO_IMSS,         
           @sueldo_mensual     =  SUELDO_MENSUAL,       
           @cve_vendedor       =  CVE_VENDEDOR,          
           @domicilio          =  DOMICILIO,        
           @tel_celular        =  TEL_CELULAR,         
           @tel_casa           =  TEL_CASA,         
           @sit_empleado       =  SIT_EMPLEADO
		   FROM  @TEmpleado  WHERE  RowID  =  @RowCount   

    SELECT @store_proc = LTRIM(PARAMETRO)  FROM FC_GEN_PROCESO WHERE
	ID_CLIENTE     =  @pIdCliente  AND
	CVE_EMPRESA    =  @pCveEmpresa AND
	CVE_APLICACION =  @pCveAplicacion AND
	ID_PROCESO     =  @pIdProceso
	
	SET @sql = N'EXEC ' + @store_proc +  
	N' @IdProceso_p,@IdTarea_p,@CveUsuario_p,@IdCliente_p,@CveEmpresa_p,@CveAplicacion_p,' + 
	N'@CveTipoNomina_p,@AnoPeriodo_p,@IdEmpleado_p,@Zona_p,@CveTipoEmpleado_p,' +
	N'@CveTipoPercep_p,@FIngreso_p,@SueldoMensual_p,@Error_p OUTPUT,@MsgError_p OUTPUT'
	SET @parametros =
	N' @IdProceso_p numeric(9,0),@IdTarea_p numeric(9,0),@CveUsuario_p varchar(10),' +
	N'@IdCliente_p int,@CveEmpresa_p varchar(4),@CveAplicacion_p varchar(10),' +
	N'@CveTipoNomina_p varchar(2),@AnoPeriodo_p varchar(6),@IdEmpleado_p int,' +
	N'@Zona_p int,@CveTipoEmpleado_p varchar(2),' +
	N'@CveTipoPercep_p varchar(2),@FIngreso_p date,@SueldoMensual_p numeric(16,2),' +
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
	 @CveTipoEmpleado_p = @cve_tipo_empleado,
	 @CveTipoPercep_p   = @cve_tipo_percep, 
	 @FIngreso_p        = @f_ingreso,
	 @SueldoMensual_p   = @sueldo_mensual,
	 @Error_p           = @pError OUTPUT,
	 @MsgError_p        = @pMsgError OUTPUT 

    SET @RowCount     = @RowCount + 1
  END

END

