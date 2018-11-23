Alter PROCEDURE [dbo].[spInsIsrItem]  @p_anomes_proceso varchar(6),     @p_concepto varchar(6),
                                       @p_imp_concepto numeric(12,2)  
AS
BEGIN

  insert CI_IMP_CPTO_CIER_MES (
         ANO_MES,              
         CVE_CONCEPTO,         
         IMP_CONCEPTO)
         values (
         @p_anomes_proceso,
         @p_concepto,
         @p_imp_concepto)   
END
