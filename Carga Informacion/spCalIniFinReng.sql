USE ADMON01	
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spCalIniFinReng')
BEGIN
  DROP  PROCEDURE spCalIniFinReng
END
GO
-- exec spCargaFile 1,1,'MARIO', 1, 'CU',1,'201812', ' ', ' '
-- BALANZA201804
CREATE PROCEDURE [dbo].[spCalIniFinReng] 
(
@pIdCliente      int,
@pCveEmpresa     varchar(4),
@pCodigoUsuario  varchar(20),
@pCveAplicacion  varchar(10),
@pAnoPeriodo     varchar(8),
@pIdProceso      numeric(9),
@pFolioExe       int,
@pIdTarea        numeric(9),
@pCveTipoBloque  varchar(4),
@pNumRengIni     int,
@pNumRengFin     int,
@pCadenaFin      varchar(3),
@pCadenaEnca     nvarchar(15),
@pNumRengCad     int,
@pResIni         int OUT,
@pResFin         int OUT, 
@pError          varchar(80) OUT,
@pMsgError       varchar(400) OUT
)
AS
BEGIN
  --CREATE TABLE #FILE 
  --(id_renglon  int identity,
  -- Rowfile     varchar(max))

  DECLARE  @num_pos_enca     int  =  0,
           @num_pos_c_ini    int  =  0,
           @num_pos_c_fin    int  =  0

  DECLARE  @k_pos_ini_fin    varchar(4) = 'PIPF',
		   @k_pos_ini_cf     varchar(4) = 'PICF',
		   @k_pos_ini_eof    varchar(4) = 'PIEF',
           @k_pos_den_cf     varchar(4) = 'DECF',
		   @k_pos_den_fin    varchar(4) = 'DEFI',
		   @k_pos_den_eof    varchar(4) = 'DEEF',
		   @k_pos_den_ind    varchar(4) = 'DEIN',
		   @k_pos_ini_ind    varchar(4) = 'PIIN'

  -- Para estos tipos de bloque se determina la posici�n inicial del bloque por una cadena de caracteres especificado
  IF  @pCveTipoBloque  IN  (@k_pos_den_cf, @k_pos_den_fin, @k_pos_den_eof, @k_pos_den_ind)
  BEGIN
	SELECT  @num_pos_c_ini = id_renglon FROM  #FILE  WHERE
	        SUBSTRING(Rowfile,1,LEN(@pCadenaEnca)) LIKE '%' +
			LTRIM(SUBSTRING(@pCadenaEnca,1,LEN(@pCadenaEnca))) + '%'
    SET  @pResIni  =  @num_pos_c_ini + @pNumRengCad  
  END

  -- Para estos tipos de bloque se determina la posici�n inicial del bloque se determina por la posici�n inicial indicada en los 
  -- par�metros de carga
  IF  @pCveTipoBloque  IN  (@k_pos_ini_fin, @k_pos_ini_cf, @k_pos_ini_eof, @k_pos_ini_ind)
  BEGIN
    SET  @pResIni  =  @pNumRengIni   
  END

  -- Para estos tipos de bloque se determina la posici�n final del bloque se determina por la busqueda del caracter final especificado
  -- en los par�metros de carga

  IF  @pCveTipoBloque  IN  (@k_pos_den_cf, @k_pos_ini_cf)
  BEGIN
    SELECT  @num_pos_c_fin = id_renglon FROM  #FILE  WHERE
	        SUBSTRING(Rowfile,1,LEN(@pCadenaEnca)) LIKE '%' +
			LTRIM(SUBSTRING(@pCadenaEnca,1,LEN(@pCadenaEnca))) + '%' AND
			id_renglon  > @pResIni
    SET  @pResFin  =  @num_pos_c_fin - 1   
  END

  -- Para estos tipos de bloque se determina la posici�n final por la posici�n final especificada en los par�metros de carga

  IF  @pCveTipoBloque  IN  (@k_pos_ini_fin, @k_pos_den_fin, @k_pos_den_ind, @k_pos_ini_ind)
  BEGIN
    SET  @pResFin  =  @pNumRengFin 
  END

  -- Para estos tipos de bloque se determina la posici�n final por el fin de registros determinado por mismo archivo CSV

  IF  @pCveTipoBloque  IN  (@k_pos_ini_eof, @k_pos_den_eof)
  BEGIN
    SET  @pResFin  =  (SELECT COUNT(*) FROM #FILE)     
  END


END