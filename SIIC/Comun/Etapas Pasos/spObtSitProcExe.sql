USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtSitProcExe')
BEGIN
  DROP  PROCEDURE spObtSitProcExe
END
GO

-- EXEC  spObtSitProcExe 'EGG', 1,1, '202106', 1500, ' ', ' ',' ', ' '

--------------------------------------------------------------------------------------------
-- Verifica el estatus de un proceso que se ejecuta en una ETPA/PASO                      --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spObtSitProcExe]  
@pCveEmpresa    varchar(4),
@pIdEtapa       int,
@pIdPaso        int,
@pAnoPeriodo    varchar(8),
@pIdProceso     numeric(9),
@pSitProceso    varchar(2)   OUT,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  DECLARE @RegMaxExec    int
  
  DECLARE @k_verdadero   bit = 1,
          @k_falso       bit = 0,
		  @k_pendiente   varchar(2)  =  'PE',
		  @k_error       varchar(2)  =  'ER',
		  @k_correcto    varchar(2)  =  'CO'

 	SET @RegMaxExec  = ISNULL(
   (SELECT  MAX(FOLIO_EXEC) FROM  FC_PASO_PROC_EXEC  WHERE 
	PERIODO      =  @pAnoPeriodo  AND
	CVE_EMPRESA  =  @pCveEmpresa  AND
    ID_ETAPA     =  @pIdEtapa     AND
    ID_PASO      =  @pIdPaso      AND
    ID_PROCESO   =  @pIdProceso), 0)

	--SELECT  '*' + ' ' + @pAnoPeriodo  
	--SELECT  '*' + ' ' + @pCveEmpresa  
 --   SELECT  '*' + ' ' + CONVERT(VARCHAR(5),@pIdEtapa)     
 --   SELECT  '*' + ' ' + CONVERT(VARCHAR(5),@pIdPaso)
	--SELECT  '*' + ' ' + CONVERT(VARCHAR(5),@RegMaxExec)
	--SELECT  '*' + ' ' + CONVERT(VARCHAR(5),@pIdProceso)


	IF  @RegMaxExec  =  0 
	BEGIN
      SET  @pSitProceso  =  @k_pendiente
	END
	ELSE
	BEGIN
	  IF  (SELECT SIT_PROCESO  FROM FC_PASO_PROC_EXEC  WHERE
           PERIODO      =  @pAnoPeriodo  AND
	       CVE_EMPRESA  =  @pCveEmpresa  AND
           ID_ETAPA     =  @pIdEtapa     AND
           ID_PASO      =  @pIdPaso      AND
		   FOLIO_EXEC   =  @RegMaxExec   AND
           ID_PROCESO   =  @pIdProceso)  <>  @k_correcto
      BEGIN
	    SET @pSitProceso  =  @k_error
	  END
      ELSE
	  BEGIN
	    SET @pSitProceso  =  @k_correcto
	  END
	END
 
  END