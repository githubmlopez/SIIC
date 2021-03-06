USE [INFRA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM INFRA.sys.procedures WHERE Name =  'spAltaUsuario')
BEGIN
  DROP  PROCEDURE spAltaUsuario
END
GO
-- exec spAltaUsuario null, 'mario@cs360.com', 'Mario Lopez', 0, ' ', ' '
CREATE PROCEDURE [dbo].[spAltaUsuario]  
@pCveUsuario    varchar(100),
@pEMail         varchar(100),
@pNombre        varchar(100),
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN
  
  DECLARE   @k_verdadero   bit  =  1,
            @k_falso       bit  =  0

  SET  @pBError  =  @k_falso

  IF  EXISTS(SELECT 1 FROM FC_SEG_USUARIO WHERE CVE_USUARIO = @pCveUsuario)
  BEGIN
      SET  @pBError  =  @k_verdadero
      SET  @pError   =  'El Usuario ya existe '    
  END
  ELSE
  BEGIN
    BEGIN TRY
	INSERT FC_SEG_USUARIO (CVE_USUARIO, APELLIDO_PATERNO, APELLIDO_MATERNO, NOMBRE, CVE_EMPRESA, B_BLOQUEADO, B_ACTIVA, NOMBRE_USUARIO, E_MAIL)
	VALUES
	(@pCveUsuario, ' ', ' ', ' ', ' ', 0,0, @pNombre, @pEMail)
	END TRY

	BEGIN CATCH
	  SET  @pBError  =  @k_verdadero
      SET  @pError   =  'Error al dar de alta el usuario '	  
	END CATCH
	
  END

END    
  
  
