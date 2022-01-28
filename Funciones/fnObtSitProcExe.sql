USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.objects 
WHERE   type IN (N'FN') AND Name =  'fnObtSitProcExe')
BEGIN
  DROP  FUNCTION fnObtSitProcExe
END

GO

-- EXEC  spObtSitProcExe 'EGG', 1,1, '202106', 1500, ' ', ' ',' ', ' '

--------------------------------------------------------------------------------------------
-- Verifica el estatus de un proceso que se ejecuta en una ETPA/PASO                      --
--------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fnObtSitProcExe] 
(
@pCveEmpresa    varchar(4),
@pIdEtapa       int,
@pIdPaso        int,
@pAnoPeriodo    varchar(10),
@pIdProceso     numeric(9)
)
RETURNS varchar(2)
AS
BEGIN

  DECLARE @RegMaxExec    int,
          @sit_proceso   varchar(2)
  
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

	IF  @RegMaxExec  =  0 
	BEGIN
      SET  @sit_proceso  =  @k_pendiente
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
	    SET @sit_proceso  =  @k_error
	  END
      ELSE
	  BEGIN
	    SET @sit_proceso  =  @k_correcto
	  END
	END
    RETURN  @sit_proceso
  END