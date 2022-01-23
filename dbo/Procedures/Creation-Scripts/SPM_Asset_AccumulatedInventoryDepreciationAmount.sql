SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AccumulatedInventoryDepreciationAmount]
AS
BEGIN
	UPDATE TGT
	SET TGT.AccumulatedInventoryDepreciationAmountLeaseComponent = SRC.AccumulatedInventoryDepreciationAmount_LeaseComponent,
	    TGT.AccumulatedInventoryDepreciationAmountFinanceComponent = SRC.AccumulatedInventoryDepreciationAmount_FinanceComponent	    
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(
			SELECT 
					EA.AssetId
				,- ISNULL(AIAI.AccumulatedInventoryDepreciationAmount_LeaseComponent,0.00) [AccumulatedInventoryDepreciationAmount_LeaseComponent]
				,- ISNULL(AIAI.AccumulatedInventoryDepreciationAmount_FinanceComponent,0.00) [AccumulatedInventoryDepreciationAmount_FinanceComponent]
			FROM ##Asset_EligibleAssets EA
			LEFT JOIN ##Asset_AssetInventoryAVHInfo AIAI ON AIAI.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
