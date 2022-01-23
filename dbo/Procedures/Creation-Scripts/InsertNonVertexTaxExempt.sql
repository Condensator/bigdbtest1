SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexTaxExempt]
(
@ContractTaxExemptRule NVarChar(27) ,
@AssetTaxExemptRule  NVarChar(27) ,
@ReceivableCodeTaxExemptRule NVarChar(27),
@LocationTaxExemptRule NVarChar(27),
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_DistinctAssetIds AS
(
SELECT DISTINCT AssetId,IsCityTaxExempt,IsCountyTaxExempt,IsStateTaxExempt,IsCountryTaxExempt
From NonVertexAssetDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO NonVertexTaxExemptExtract([ReceivableDetailId],[AssetId],[IsCountryTaxExempt],[IsStateTaxExempt],[IsCountyTaxExempt],[IsCityTaxExempt],
                                [CountryTaxExemptRule],[StateTaxExemptRule],[CountyTaxExemptRule],[CityTaxExemptRule],[JobStepInstanceId])
SELECT 
        RD.ReceivableDetailId
       ,RD.AssetId																																					   
       ,IsCountryTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR 
	                                        IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR 
											IsNULL(LocationRule.IsCountryTaxExempt,0) = 1  OR 
											IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1 
											THEN 1 
									    ELSE 0 
								  END AS BIT)
       ,IsStateTaxExempt   = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR 
	                                        IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR 
											IsNULL(LocationRule.IsStateTaxExempt,0) = 1  OR 
											IsNULL(LeaseRule.IsStateTaxExempt,0) = 1 
											THEN 1 
									   ELSE 0 
								  END AS BIT)
	   ,IsCountyTaxExempt  = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR 
										     IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR 
										   	 IsNULL(LocationRule.IsCountyTaxExempt,0) = 1  OR 
										   	 IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1 
											 THEN 1 
										ELSE 0 END AS BIT)
       ,IsCityTaxExempt    = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR
	                                        IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR 
											IsNULL(LocationRule.IsCityTaxExempt,0) = 1  OR 
											IsNULL(LeaseRule.IsCityTaxExempt,0) = 1 
											THEN 1 
									   ELSE 0 END AS BIT)
       ,CountryTaxExemptRule = CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN @ContractTaxExemptRule
	   	                            WHEN AssetRule.IsCountryTaxExempt = 1 THEN @AssetTaxExemptRule
	   	                            WHEN LocationRule.IsCountryTaxExempt = 1 THEN @LocationTaxExemptRule
	   	                            WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
	   	                            ELSE '_' END
       ,StateTaxExemptRule =  CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN @ContractTaxExemptRule 
   	   		                       WHEN AssetRule.IsStateTaxExempt = 1 THEN @AssetTaxExemptRule
   	   		                       WHEN LocationRule.IsStateTaxExempt = 1 THEN @LocationTaxExemptRule
   	   		                       WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
   	   		                       ELSE '_' END
       ,CountyTaxExemptRule = CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN @ContractTaxExemptRule
   						   		   WHEN AssetRule.IsCountyTaxExempt = 1 THEN @AssetTaxExemptRule
   						   		   WHEN LocationRule.IsCountyTaxExempt = 1 THEN @LocationTaxExemptRule
   						   		   WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
   						   		   ELSE '_' END
       ,CityTaxExemptRule = CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN @ContractTaxExemptRule 
			WHEN AssetRule.IsCityTaxExempt = 1 THEN @AssetTaxExemptRule
			WHEN LocationRule.IsCityTaxExempt = 1 THEN @LocationTaxExemptRule
			WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
			ELSE '_' END
       ,RD.JobStepInstanceId
FROM SalesTaxReceivableDetailExtract RD
LEFT JOIN NonVertexReceivableCodeDetailExtract ReceivableCodeRule ON RD.ReceivableCodeId = ReceivableCodeRule.ReceivableCodeId AND RD.StateId = ReceivableCodeRule.StateId AND ReceivableCodeRule.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN NonVertexLocationDetailExtract LocationRule ON  RD.LocationId = LocationRule.LocationId  AND LocationRule.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN CTE_DistinctAssetIds AssetRule ON RD.AssetId = AssetRule.AssetId
LEFT JOIN NonVertexLeaseDetailExtract LeaseRule ON RD.ContractId = LeaseRule.ContractId AND LeaseRule.JobStepInstanceId = @JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
END

GO
