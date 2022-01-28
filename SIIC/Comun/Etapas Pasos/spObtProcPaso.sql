USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT  ON 
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spObtProcPaso')
BEGIN
  DROP  PROCEDURE spObtProcPaso
END
GO

-- EXEC spObtProcPaso 'EGG', 1, 'MARIO', 'PASOS', '202109', 1, 1, 0, ' ', ' '

--------------------------------------------------------------------------------------------
-- Obtiene los procesos que serán ejecutados dependiendo de ssu situación en su           --
-- ETAPA/PASO                                                                  --
--------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spObtProcPaso]  
@pCveEmpresa    varchar(4),
@pIdCliente     int,
@pCodigoUsuario varchar(20),
@pCveAplicacion varchar(10),
@pPeriodo    varchar(8),
@pIdEtapa       int,
@pIdPaso        int,
@pBError        bit          OUT,
@pError         varchar(80)  OUT,
@pMsgError      varchar(400) OUT
AS
BEGIN

  DECLARE @NumRegistros  int,
          @RowCount      int,
		  @id_proceso    varchar(9),
		  @sit_proceso   varchar(2),
		  @RegMaxExec    int

  DECLARE @k_verdadero   bit = 1,
          @k_falso       bit = 0,
		  @k_pendiente   varchar(2)  =  'PE',
		  @k_error       varchar(2)  =  'ER',
		  @k_correcto    varchar(2)  =  'CO'

  DECLARE @TvProceso  TABLE 
 (
  RowID           int IDENTITY(1,1) NOT NULL,
  ID_ETAPA        int,
  ID_PASO         int,
  ID_PROCESO      numeric(9),
  SIT_EXEC        varchar(2),
  SEC_PROCESO     varchar(2)
 )

  INSERT @TvProceso (ID_ETAPA, ID_PASO, ID_PROCESO, SIT_EXEC, SEC_PROCESO)
  SELECT ID_ETAPA, ID_PASO, ID_PROCESO, ' ', SEC_PROCESO FROM FC_PASO_PROCESO  WHERE 
  CVE_EMPRESA  =  @pCveEmpresa  AND
  ID_ETAPA     =  @pIdEtapa     AND
  ID_PASO      =  @pIdPaso     

  SET @NumRegistros = (SELECT COUNT(*) FROM @TvProceso)
-----------------------------------------------------------------------------------------------------
  SET  @pBError  =  @k_falso

  SET @RowCount     = 1

  WHILE @RowCount <= @NumRegistros
  BEGIN
    SELECT  @id_proceso = ID_PROCESO FROM  @TvProceso  WHERE  RowID  =  @RowCount

    EXEC spObtSitProcExe  
    @pCveEmpresa,
    @pIdEtapa,
    @pIdPaso,
    @pPeriodo,
    @id_proceso,
    @sit_proceso  OUT,
    @pBError      OUT,
    @pError       OUT,
    @pMsgError    OUT
                    
    UPDATE  @TvProceso  SET  SIT_EXEC = @sit_proceso  WHERE  RowID  =  @RowCount     

	SET @RowCount     = @RowCount + 1

  END

--  SELECT ID_ETAPA, ID_PASO, ID_PROCESO, SIT_EXEC, SEC_PROCESO  FROM  @TvProceso  

  INSERT INTO #PROCESO (ID_ETAPA, ID_PASO, ID_PROCESO, SIT_EXEC, SEC_PROCESO)
  SELECT ID_ETAPA, ID_PASO, ID_PROCESO, SIT_EXEC, SEC_PROCESO  FROM  @TvProceso  WHERE SIT_EXEC <> @k_correcto 

  END