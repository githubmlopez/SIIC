USE [ADMON01]
GO

--exec spLanzaPoliza 1,	'CU', '201705','Mario' 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE spLanzaPoliza @pIdProceso numeric(9), @pCveEmpresa varchar(4), @pAnoMes varchar(6), 
                                   @pCveUsuario varchar(8)
                                   
AS
BEGIN

  DECLARE  @error        varchar(80),
           @msg_error    varchar(400),
		   @id_tarea     numeric(9),
		   @cve_poliza   varchar(6)

		   SET      @error      =  ' '
           SET      @msg_error  =  ' '
           SET      @id_tarea   =  0

  EXEC  spCreaTarea  @pCveUsuario, @pIdProceso, @id_tarea OUT, 
                     @error OUT, @msg_error OUT


  SET @cve_poliza = (SELECT SUBSTRING(PARAMETRO, 1,6) FROM FC_GEN_PROCESO  WHERE ID_PROCESO  =  @pIdProceso)
  
  EXEC  spGeneraPolizas @pCveEmpresa, @pAnoMes, @cve_poliza, @pCveUsuario, @pIdProceso, @id_tarea,
                        @error OUT, @msg_error OUT
  EXEC  spActPctTarea @id_tarea, 10
  SELECT 'ERROR ' + @error
  SELECT 'MSG' + @msg_error
END

