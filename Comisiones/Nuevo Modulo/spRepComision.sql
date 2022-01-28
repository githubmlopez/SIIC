USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spLanzaComision]    Script Date: 06/11/2020 02:19:06 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF  EXISTS( SELECT 1 FROM ADMON01.sys.procedures WHERE Name =  'spRepComision')
DROP PROCEDURE [dbo].[spRepComision]
GO
-- Exec spRepComision 'CU', 202010, 'DAFU'

CREATE PROCEDURE [dbo].[spRepComision]		
(
--@pIdCliente     int,
@pCveEmpresa    varchar(4),
--@pCodigoUsuario varchar(20),
--@pCveAplicacion varchar(10),
@pAnoPeriodo    varchar(8),
@pCveVendedor   varchar(4)
--@pIdProceso     numeric(9),
--@pFolioExe      int,
--@pIdTarea       numeric(9),
--@pBError        bit OUT,
--@pError         varchar(80) OUT, 
--@pMsgError      varchar(400) OUT
)
	
AS
BEGIN

  SELECT 
  c.ANO_MES as 'Año Mes',
  c.CVE_EMPRESA as 'Cve. Empresa', 
  c.SERIE as 'Serie', 
  c.ID_CXC as 'Id CXC',
  c.ID_ITEM as 'Id Item',
  s.DESC_SUBPRODUCTO 'Subproducto',
  c.CVE_VENDEDOR as 'Vendedor',
  c.CVE_PROCESO as 'Cve Porceso',
  c.CVE_ESPECIAL as 'Cve Especial',
  f.IMP_F_BRUTO as 'Imp Bruto Fact',
  f.CVE_F_MONEDA as 'Cve Moneda',
  i.IMP_BRUTO_ITEM as 'imp Bruto Item',
  c.PJE_COMISION 'Pje Comis',
  c.IMP_BASE_PAGADO 'Imp Base Pag',
  c.IMP_BASE_PAGADO * (c.PJE_COMISION/100) as 'imp Comision',
  v.IMP_COMIS_DIR as 'Imp Com Dir',
  v.IMP_DESCUENTO as 'Imp Descto',
  c.IMP_COM_BANC as 'Imp Com Banc',
  c.IMP_CUPON as 'Imp Cupon',
  c.TX_NOTA as 'Nota'
  FROM VTA_CUPON_COMISION c, CI_ITEM_C_X_C i, CI_FACTURA f, CI_SUBPRODUCTO s, VTA_COMIS_ITEM v
  WHERE
--  c.CVE_VENDEDOR   =  @pCveVendedor    AND
--  c.ANO_MES        =  @pAnoPeriodo     AND
  c.CVE_EMPRESA      = v.CVE_EMPRESA     AND
  c.SERIE            = v.SERIE           AND
  c.ID_CXC           = v.ID_CXC          AND
  c.ID_ITEM          = v.ID_ITEM         AND
  c.CVE_PROCESO      = v.CVE_PROCESO     AND
  f.CVE_EMPRESA      = c.CVE_EMPRESA     AND
  f.SERIE            = c.SERIE           AND
  f.ID_CXC           = c.ID_CXC          AND 
   i.CVE_EMPRESA     = v.CVE_EMPRESA     AND
  i.SERIE            = c.SERIE           AND
  i.ID_CXC           = c.ID_CXC          AND
  i.ID_ITEM          = c.ID_ITEM         AND       
  i.CVE_SUBPRODUCTO  = s.CVE_SUBPRODUCTO 
END 