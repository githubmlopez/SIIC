USE ADMON01
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name = 'spRecSitPasoEtapa')
BEGIN
  DROP  PROCEDURE spRecSitPasoEtapa
END
GO

-----------------------------------------------------------
/* Inserta registro de instancia de ejecución de proceso  */
-----------------------------------------------------------

--EXEC spRecSitPasoEtapa 
CREATE PROCEDURE [dbo].[spRecSitPasoEtapa]
(
@pPeriodo       varchar(10),
@pCveEmpresa    varchar(4),
@pIdEtapa       int,
@pIdPaso        int
) 
AS
BEGIN

  DECLARE 
  @id_proceso   numeric(9),
  @id_paso      int,
  @situacion    varchar(2),
  @b_existe_pen bit,
  @id_fol_max   numeric(9)

  DECLARE
  @k_verdadero  bit         =  1,
  @k_falso      bit         =  0,
  @k_correcto   varchar(2)  =  'CO',
  @k_error      varchar(2)  =  'ER',
  @k_autorizado varchar(2)  =  'AU',
  @k_pendiente  varchar(2)  =  'PE'

  DECLARE @TvpProceso  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  ID_PROCESO      numeric(9)
 )

  DECLARE @TvpPaso  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  ID_PASO         int
 )

  DECLARE  @NunRegistros       int, 
           @RowCount           int

  INSERT  @TvpProceso (ID_PROCESO)  
  SELECT  ID_PROCESO  FROM  FC_PASO_PROCESO
  WHERE   CVE_EMPRESA  =  @pCveEmpresa  AND
          ID_ETAPA     =  @pIdEtapa     AND
		  ID_PASO      =  @pIdPaso   

  SET @NunRegistros = (SELECT COUNT(*) FROM @TvpProceso)
  SET @RowCount     =   1

  WHILE @RowCount <= @NunRegistros
  BEGIN

    SELECT @id_proceso  =  ID_PROCESO 
    FROM   @TvpProceso
    WHERE  RowID  =  @RowCount

	SET @id_fol_max  = ISNULL(
   (SELECT MAX(FOLIO_EXEC) FROM FC_PASO_PROC_EXEC WHERE PERIODO  =  @pPeriodo     AND
	                                                CVE_EMPRESA  =  @pCveEmpresa  AND
	    								            ID_ETAPA     =  @pIdEtapa     AND
										            ID_PASO      =  @pIdPaso      AND
         						                    ID_PROCESO   =  @id_proceso), 0)

    SELECT @situacion = ISNULL(
   (SELECT SIT_PROCESO FROM FC_PASO_PROC_EXEC WHERE PERIODO      =  @pPeriodo     AND
	                                                CVE_EMPRESA  =  @pCveEmpresa  AND
	    								            ID_ETAPA     =  @pIdEtapa     AND
										            ID_PASO      =  @pIdPaso      AND
         						                    ID_PROCESO   =  @id_proceso   AND
													FOLIO_EXEC   =  @id_fol_max), @k_pendiente)

    IF  @situacion  =  @k_error   
	BEGIN
	  UPDATE FC_PASO_PERIODO SET SIT_PASO_PER = @situacion  WHERE  PERIODO      =  @pPeriodo     AND
	                                                               CVE_EMPRESA  =  @pCveEmpresa  AND
	    								                           ID_ETAPA     =  @pIdEtapa     AND
										                           ID_PASO      =  @pIdPaso      
	    
      SET  @RowCount = @NunRegistros
	END
	ELSE
    IF  @situacion  =  @k_pendiente   
	BEGIN
	  SET @b_existe_pen  = @k_verdadero 
	END
	
    SET @RowCount     =   @RowCount + 1
  END

  IF  @situacion  <>  @k_error
  BEGIN

  IF  @b_existe_pen  = @k_verdadero
  BEGIN
    SET  @situacion  = @k_pendiente
  END
  ELSE
  BEGIN
    SET  @situacion  = @k_correcto
  END

  END

  UPDATE FC_PASO_PERIODO SET SIT_PASO_PER = @situacion  WHERE  PERIODO      =  @pPeriodo     AND
                                                               CVE_EMPRESA  =  @pCveEmpresa  AND
    								                           ID_ETAPA     =  @pIdEtapa     AND
									                           ID_PASO      =  @pIdPaso      
 
-- Actualización de situación de ETAPA

  SET @NunRegistros  =  0 
  SET @RowCount      =  0
  SET @situacion     =  ' '
  SET @b_existe_pen  =  @k_falso

  INSERT  @TvpPaso (ID_PASO)  
  SELECT  ID_PASO  FROM  FC_PASO
  WHERE   CVE_EMPRESA  =  @pCveEmpresa  AND
          ID_ETAPA     =  @pIdEtapa     

  SET @NunRegistros = (SELECT COUNT(*) FROM @TvpPaso)
  SET @RowCount     =   1

  WHILE @RowCount <= @NunRegistros
  BEGIN
    SELECT @id_paso  =  ID_PASO 
    FROM   @TvpPaso
    WHERE  RowID  =  @RowCount

   SELECT @situacion = ISNULL(
  (SELECT SIT_PASO_PER FROM FC_PASO_PERIODO WHERE PERIODO      =  @pPeriodo     AND
	                                               CVE_EMPRESA  =  @pCveEmpresa  AND
	    								           ID_ETAPA     =  @pIdEtapa     AND
										           ID_PASO      =  @pIdPaso), @k_pendiente)
   IF  @situacion  =  @k_error   
   BEGIN
	 UPDATE FC_ETAPA_PERIODO SET SIT_ETAPA_PER = @situacion  WHERE  PERIODO      =  @pPeriodo     AND
	                                                                CVE_EMPRESA  =  @pCveEmpresa  AND
	    								                            ID_ETAPA     =  @pIdEtapa     
     SET  @RowCount = @NunRegistros
   END
   ELSE
   IF  @situacion  =  @k_pendiente   
   BEGIN
	 SET @b_existe_pen  = @k_verdadero 
   END
  
   SET @RowCount     =   @RowCount + 1

   END

  IF  @situacion  <>  @k_error
  BEGIN
   IF  @b_existe_pen  = @k_verdadero
   BEGIN
     SET  @situacion  = @k_pendiente
   END
   ELSE
   BEGIN
     SET  @situacion  = @k_correcto
   END
   END

   UPDATE FC_ETAPA_PERIODO SET SIT_ETAPA_PER = @situacion  WHERE  PERIODO      =  @pPeriodo     AND
                                                                  CVE_EMPRESA  =  @pCveEmpresa  AND
        								                          ID_ETAPA     =  @pIdEtapa   
END
