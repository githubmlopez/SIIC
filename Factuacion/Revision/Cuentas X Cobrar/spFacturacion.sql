USE [ADMON01]
GO
/****** Object:  StoredProcedure [dbo].[spFacturacion]    Script Date: 06/08/2018 09:40:51 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO 
-- EXEC  spFacturacion 'CU', '201804'
ALTER PROCEDURE [dbo].[spFacturacion]  @pCveEmpresa  varchar(4), @pAnoMes varchar(6)
AS
BEGIN
  DECLARE  @k_activa          varchar(1)  =  'A',
           @k_cancelada       varchar(1)  =  'C',
		   @k_can_mes_act     varchar(2)  =  'CM',
		   @k_act_can_desp    varchar(2)  =  'AD',
		   @k_act_can_mes     varchar(2)  =  'AC',
		   @k_act_can_ant     varchar(2)  =  'CA',
		   @k_otra            varchar(2)  =  'OT',
           @k_legada          varchar(6)  =  'LEGACY',
           @k_peso            varchar(1)  =  'P',
           @k_dolar           varchar(1)  =  'D',
           @k_falso           bit         =  0,
           @k_verdadero       bit         =  1

  SELECT
  LEFT(CONVERT(VARCHAR, f.F_OPERACION, 120), 10) AS F_OPERACION, 
  ISNULL(LEFT(CONVERT(VARCHAR, f.F_CANCELACION, 120), 10),' ') AS F_CANCELACION,    
  CONVERT(VARCHAR(10),c.ID_CLIENTE)AS ID_CLIENTE,
  c.NOM_CLIENTE,
  f.CVE_EMPRESA,
  f.SERIE,
  f.ID_CXC,
  p.DESC_PRODUCTO,
  S.DESC_CORTA_SP,
  CONVERT(VARCHAR(12),f.IMP_F_BRUTO) AS IMP_F_BRUTO,
  CONVERT(VARCHAR(12),f.IMP_F_IVA) AS IMP_F_IVA,
  CONVERT(VARCHAR(12),f.IMP_F_NETO) AS IMP_F_NETO,
  f.CVE_F_MONEDA,
  CONVERT(VARCHAR(12),f.TIPO_CAMBIO) AS TIPO_CAMBIO,
  CONVERT(VARCHAR(12),dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA)) AS IMP_PESOS,  
  CONVERT(VARCHAR(12),i.IMP_BRUTO_ITEM) AS IMP_ITEM, SIT_TRANSACCION, 
  CASE
  WHEN  dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))     = @pAnoMes AND f.SIT_TRANSACCION  = @k_activa
  THEN  @k_activa
  WHEN  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND  f.SIT_TRANSACCION = @k_cancelada AND 
        dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))     = @pAnoMes 
  THEN  @k_can_mes_act
  WHEN  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND  f.SIT_TRANSACCION = @k_cancelada 
  THEN  @k_act_can_desp
  WHEN  dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND  f.SIT_TRANSACCION = @k_cancelada AND
        dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))     < @pAnoMes
  THEN  @k_act_can_ant
  ELSE  @k_otra 
  END AS SIT_CALC
  FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
  WHERE f.CVE_EMPRESA         = i.CVE_EMPRESA      AND         
         f.SERIE               = i.SERIE           AND    
         f.ID_CXC              = i.ID_CXC          AND
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO AND    
         f.ID_VENTA            = v.ID_VENTA        AND    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR   AND    
         v.ID_CLIENTE          = c.ID_CLIENTE      AND    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO    AND                                            
		 f.SERIE               <> @k_legada        AND
       (((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND f.SIT_TRANSACCION     = @k_activa) OR
         (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
        ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes)))  AND				  
		 i.ID_ITEM in    
         (SELECT MIN(i2.ID_ITEM)FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
  UNION    
  SELECT    
  ' ' AS F_OPERACION, ' ' AS F_CANCELACION, 
  ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
  S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ',' ',  CONVERT(VARCHAR(12),i.IMP_BRUTO_ITEM) AS IMP_ITEM,  ' ',' '
  FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
  WHERE 
        f.CVE_EMPRESA         = i.CVE_EMPRESA     AND        
        f.SERIE               = i.SERIE           AND   
        f.ID_CXC              = i.ID_CXC          AND
        i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO AND    
        f.ID_VENTA            = v.ID_VENTA        AND    
        i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR   AND    
        v.ID_CLIENTE          = c.ID_CLIENTE      AND    
        s.CVE_PRODUCTO        = p.CVE_PRODUCTO    AND                                        
	    f.SERIE              <> @k_legada         AND  
       (((dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION))  = @pAnoMes AND f.SIT_TRANSACCION     = @k_activa) OR
         (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA)) OR
        ((dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) > @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA) AND
         (dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes)))  AND		
        i.ID_ITEM not in    
       (SELECT MIN(i2.ID_ITEM)FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
  UNION
-----------
  SELECT
  LEFT(CONVERT(VARCHAR, f.F_OPERACION, 120), 10) AS F_OPERACION, 
  ISNULL(LEFT(CONVERT(VARCHAR, f.F_CANCELACION, 120), 10),' ') AS F_CANCELACION,    
  CONVERT(VARCHAR(10),c.ID_CLIENTE)AS ID_CLIENTE,
  c.NOM_CLIENTE,
  f.CVE_EMPRESA,
  f.SERIE,
  f.ID_CXC,
  p.DESC_PRODUCTO,
  S.DESC_CORTA_SP,
  CONVERT(VARCHAR(12),f.IMP_F_BRUTO) AS IMP_F_BRUTO,
  CONVERT(VARCHAR(12),f.IMP_F_IVA) AS IMP_F_IVA,
  CONVERT(VARCHAR(12),f.IMP_F_NETO) AS IMP_F_NETO,
  f.CVE_F_MONEDA,
  CONVERT(VARCHAR(12),f.TIPO_CAMBIO) AS TIPO_CAMBIO,
  CONVERT(VARCHAR(12),dbo.fnCalculaPesos(f.F_OPERACION, f.IMP_F_NETO, CVE_F_MONEDA)) AS IMP_PESOS,  
  CONVERT(VARCHAR(12),i.IMP_BRUTO_ITEM) AS IMP_ITEM, SIT_TRANSACCION,
  @k_act_can_mes AS SIT_CALC
  FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
  WHERE f.CVE_EMPRESA         = i.CVE_EMPRESA      AND         
         f.SERIE               = i.SERIE           AND    
         f.ID_CXC              = i.ID_CXC          AND
         i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO AND    
         f.ID_VENTA            = v.ID_VENTA        AND    
         i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR   AND    
         v.ID_CLIENTE          = c.ID_CLIENTE      AND    
         s.CVE_PRODUCTO        = p.CVE_PRODUCTO    AND                                            
		 f.SERIE               <> @k_legada        AND
        (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA AND 
	     dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes) AND
		 i.ID_ITEM in    
         (SELECT MIN(i2.ID_ITEM)FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)    
  UNION    
  SELECT    
  ' ' AS F_OPERACION, ' ' AS F_CANCELACION, 
  ' ', ' ', ' ', ' ', f.ID_CXC, p.DESC_PRODUCTO,    
  S.DESC_CORTA_SP, ' ', ' ', ' ', ' ', ' ', ' ',  CONVERT(VARCHAR(12),i.IMP_BRUTO_ITEM) AS IMP_ITEM,  SIT_TRANSACCION,' '
  FROM CI_FACTURA f, CI_ITEM_C_X_C i, CI_SUBPRODUCTO s, CI_PRODUCTO p, CI_VENTA v, CI_VENDEDOR ve, CI_CLIENTE c     
  WHERE 
        f.CVE_EMPRESA         = i.CVE_EMPRESA     AND        
        f.SERIE               = i.SERIE           AND   
        f.ID_CXC              = i.ID_CXC          AND
        i.CVE_SUBPRODUCTO     = s.CVE_SUBPRODUCTO AND    
        f.ID_VENTA            = v.ID_VENTA        AND    
        i.CVE_VENDEDOR1       = ve.CVE_VENDEDOR   AND    
        v.ID_CLIENTE          = c.ID_CLIENTE      AND    
        s.CVE_PRODUCTO        = p.CVE_PRODUCTO    AND                                        
	    f.SERIE              <> @k_legada         AND  
        (dbo.fnArmaAnoMes (YEAR(f.F_CANCELACION), MONTH(f.F_CANCELACION)) = @pAnoMes AND f.SIT_TRANSACCION = @k_CANCELADA AND 
	     dbo.fnArmaAnoMes (YEAR(f.F_OPERACION), MONTH(f.F_OPERACION)) = @pAnoMes) AND        i.ID_ITEM not in    
       (SELECT MIN(i2.ID_ITEM)FROM CI_ITEM_C_X_C i2 WHERE i2.CVE_EMPRESA = i.CVE_EMPRESA AND i2.SERIE = i.SERIE AND i2.ID_CXC = i.ID_CXC)         
        ORDER BY  f.ID_CXC, F_OPERACION DESC  
END