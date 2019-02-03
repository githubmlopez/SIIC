USE [ADNOMINA01]
GO
/****** Proceso para generar de Cuotas para el IMSS ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADNOMINA01.sys.procedures WHERE Name =  'spGenInfEmpEmpresa')
BEGIN
  DROP  PROCEDURE spGenInfEmpEmpresa
END
GO
-- EXEC spGenInfEmpEmpresa 1,1,'MARIO',1,'CU','NOMINA','S','201803',' ',' '
CREATE PROCEDURE [dbo].[spGenInfEmpEmpresa] 
(
@pIdProceso       int,
@pIdTarea         int,
@pCveUsuario      varchar(10),
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
           @RowCount          int   =  0

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

    EXEC spRegInfEmpEmpresa
    @pIdProceso,
    @pIdTarea,
    @pCveUsuario,
    @pIdCliente,
    @pCveEmpresa,
    @pCveAplicacion,
    @pCveTipoNomina,
    @pAnoPeriodo,
    @id_empleado,
    @pError OUT,
    @pMsgError OUT

    SET @RowCount     = @RowCount + 1
  END

END

