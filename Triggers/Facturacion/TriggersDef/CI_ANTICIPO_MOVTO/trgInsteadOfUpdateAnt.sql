USE [ADMON01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create trigger on table CI_FACTURA for Insert statement
CREATE TRIGGER [dbo].[trgInsteadOfUpdateAnt] ON [dbo].[CI_ANTICIPO_MOVTO]
INSTEAD OF UPDATE 
AS

BEGIN

  DECLARE
  @tx_error_part      varchar(300)

  SET @tx_error_part    =  @tx_error_part + ': No se permiten Modificaciones'
  RAISERROR(@tx_error_part,11,1)  
  

END
