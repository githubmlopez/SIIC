USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spActDocumentos] 
AS
BEGIN

  declare  @nom_documento     varchar(50),
           @cve_empresa       varchar(4),
           @serie             varchar(6),
           @id_cxc            int,
           @id_item           int,
           @cve_tipo_docum    varchar(2),
           @situacion         varchar(1)
 
  declare  @k_falso           bit,
           @k_verdadero       bit

  set @k_falso     = 0
  set @k_verdadero = 1

  declare docum_cursor cursor for   SELECT NOM_DOCUMENTO FROM CI_DOCUM_DIR

  open  docum_cursor 

  FETCH docum_cursor INTO  @nom_documento  
   
  WHILE (@@fetch_status = 0 )
  BEGIN
    set @cve_tipo_docum  =  SUBSTRING(@nom_documento,1,2)
    set @cve_empresa     =  SUBSTRING(@nom_documento,3,4)
    set @serie           =  SUBSTRING(@nom_documento,5,7)
    set @id_cxc          =  CONVERT(INT,SUBSTRING(@nom_documento,8,12))
    set @id_cxc          =  CONVERT(INT,SUBSTRING(@nom_documento,13,17))
    set @situacion       =  CONVERT(INT,SUBSTRING(@nom_documento,18,18))

    IF  EXISTS  (SELECT 1 FROM  CI_DOCUM_ITEM WHERE CVE_EMPRESA     = @cve_empresa  and
                                                    SERIE           = @serie        and
                                                    ID_CXC          = @id_cxc       and
                                                    ID_ITEM         = @id_item      and
                                                    CVE_TIPO_DOCUM  =  @cve_tipo_docum)             
    BEGIN
      UPDATE  CI_DOCUM_ITEM  SET  SITUACION  =  @situacion  WHERE CVE_EMPRESA     = @cve_empresa  and
                                                                  SERIE           = @serie        and
                                                                  ID_CXC          = @id_cxc       and
                                                                  ID_ITEM         = @id_item      and
                                                                  CVE_TIPO_DOCUM  =  @cve_tipo_docum

    END 
     
    FETCH docum_cursor INTO @nom_documento
               
  END 

  close docum_cursor 
  deallocate docum_cursor 
                                                                                                   
END
