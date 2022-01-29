USE [INFRA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM INFRA.sys.procedures WHERE Name =  'spInfMenus')
BEGIN
  DROP  PROCEDURE spInfMenus
END
GO
-- exec spInfMenus '6c1022ee-8e65-4b20-a0b1-15726a962e41', 'INFRA', null
CREATE PROCEDURE spInfMenus @pCveUsuario varchar(100), @pCveAplicacion varchar(10), @pPerfil varchar(20)
AS
BEGIN

  DECLARE  @NunRegistros      int   =  0, 
           @RowCount          int   =  0,
		   @cve_perfil        varchar(20)

  DECLARE  @TSegMenu            TABLE
          (RowID                int  identity(1,1),            
		   CVE_APLICACION       varchar(10),                
           CVE_MENU             varchar(20),         
           CVE_MENU_P           VARCHAR(20),                 
           DESC_MENU            varchar(100),          
           URL_MENU             varchar(100), 
		   B_HOJA               bit,          
           ICONO_CLS            varchar(100))

  DECLARE  @cve_aplicacion      varchar(10),                
           @cve_menu            varchar(20),         
           @cve_menu_p          varchar(20),                 
           @desc_menu           varchar(100),          
           @url_menu            varchar(100), 
		   @b_hoja              bit,          
           @icono_cls           varchar(100)


  IF  ISNULL(@pPerfil, ' ') = ' ' 
  BEGIN 
    SET @cve_perfil = (SELECT CVE_PERFIL FROM FC_SEG_APLIC_USUARIO_PERFIL  WHERE
    CVE_USUARIO    =  @pCveUsuario     AND
    CVE_APLICACION =  @pCveAplicacion)
  END
  ELSE
  BEGIN
    SET  @cve_perfil  =  @pPerfil
  END

  INSERT INTO @TSegMenu (CVE_APLICACION, CVE_MENU, CVE_MENU_P, DESC_MENU, URL_MENU, B_HOJA, ICONO_CLS)
  SELECT
  CVE_APLICACION,
  CVE_MENU,
  CVE_MENU_P,
  DESC_MENU,
  URL_MENU,
  B_HOJA,
  ICONO_CLS
  FROM INFRA.dbo.INF_SEG_MENU WHERE CVE_APLICACION = @pCveAplicacion 

  SET @NunRegistros = @@ROWCOUNT
------------------------------------------------------------------------------------------------------
  SET @RowCount     = 1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @cve_aplicacion  =  CVE_APLICACION,                
           @cve_menu        =  CVE_MENU,         
           @cve_menu_p      =   CVE_MENU_P,                 
           @desc_menu       =   DESC_MENU,          
           @url_menu        =   URL_MENU,
		   @b_hoja          =   B_HOJA,           
           @icono_cls       =   ICONO_CLS
		   FROM  @TSegMenu WHERE  RowID  =  @RowCount 

    IF EXISTS (SELECT 1 FROM FC_SEG_PERFIL_MENU  WHERE CVE_APLICACION = @cve_aplicacion AND CVE_MENU = @cve_menu AND CVE_PERFIL = @cve_perfil)
	BEGIN
	 IF EXISTS (SELECT 1 FROM FC_SEG_PERFIL_MENU  WHERE CVE_APLICACION = @cve_aplicacion AND CVE_MENU = @cve_menu AND CVE_PERFIL = @cve_perfil) 
	 BEGIN
       DELETE FROM @TSegMenu  WHERE CVE_MENU_P = @cve_menu
	   DELETE FROM @TSegMenu  WHERE CVE_MENU   = @cve_menu
	 END

	END
		   
   SET @RowCount  = @RowCount  + 1
END

  SELECT
  CVE_APLICACION,
  CVE_MENU,
  CVE_MENU_P,
  DESC_MENU,
  URL_MENU,
  B_HOJA,
  ICONO_CLS
  FROM   @TSegMenu


END