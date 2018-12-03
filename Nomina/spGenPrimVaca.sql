USE [ADNOMINA01]
GO
/****** Proceso para generar Parámetros del proceso por empleado ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGenPrimVaca] (@pIdProceso     numeric(9),        
                                        @pIdTarea       numeric(9),
										@pCveUsuario    varchar(8),
										@pCveTipoNomina varchar(2),
										@AnoPeriodo     varchar(8),
										@pError         varchar(80)  OUT,
								        @pMsgError      varchar(400) OUT)
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
  
  DECLARE  @k_verdadero       bit   =  1,
           @k_falso           bit   =  0

-------------------------------------------------------------------------------
-- Proceso para generar Parámetros del proceso por empleado
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
  SIT_EMPLEADO     
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
  FROM    NO_EMPLEADO
  WHERE
  p.ID_CLIENTE       = @pIdCliente      AND
  p.CVE_EMPRESA      = @pCveEmpresa     AND
  p.CVE_TIPO_NOMINA  = @pCveTipoNomina  
 
  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    EXEC  spCalPrimaVac    @pIdProceso,
                           @pIdTarea,
                           @pIdCliente,
						   @pCveEmpresa,
						   @pAnoPeriodo,
						   @id_empleado,
						   @cve_tipo_nomina 

    SET @RowCount     = @RowCount + 1
  END

END

