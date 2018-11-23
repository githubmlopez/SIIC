USE [ADMON01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec spRegSegVentas 
alter PROCEDURE [dbo].[spRegSegVentas] 
(@pCveEmpresa varchar(4), @pSerie varchar(6), @pIdCxC int, @pIdItem int, @pCveSituacion varchar(1), @pTxtNota varchar(200))
AS
BEGIN
  INSERT  INTO CI_SEG_RENOVACION  
  (CVE_EMPRESA,
  SERIE,
  ID_CXC,
  ID_ITEM,
  CVE_SITUACION,
  TX_NOTA) VALUES
  (@pCveEmpresa,
  @pSerie,
  @pIdCxC,
  @pIdItem,
  @pCveSituacion,
  @pTxtNota)
END