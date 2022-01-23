SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_AccumulatedAssetImpairmentAmount]
AS
BEGIN
	UPDATE TGT
	SET TGT.AccumulatedAssetImpairmentAmountLeaseComponent = SRC.AccumulatedAssetImpairmentAmount_LeaseComponent,
	    TGT.AssetImpairmentLeaseComponent = SRC.AssetImpairmentAmount_LeaseComponent,
	    TGT.AccumulatedAssetImpairmentAmountFinanceComponent = SRC.AccumulatedAssetImpairmentAmount_FinanceComponent,
		TGT.AssetImpairmentFinanceComponent = SRC.AssetImpairmentAmount_FinanceComponent
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(
			SELECT 
					EA.AssetId
				,- ISNULL(AII.AccumulatedAssetImpairmentAmount_LeaseComponent,0.00) [AccumulatedAssetImpairmentAmount_LeaseComponent]
				,ISNULL(AII.AccumulatedAssetImpairmentAmount_LeaseComponent + AII.ClearedAssetImpairmentAmount_LeaseComponent,0.00) [AssetImpairmentAmount_LeaseComponent]
				,- ISNULL(AII.AccumulatedAssetImpairmentAmount_FinanceComponent,0.00) [AccumulatedAssetImpairmentAmount_FinanceComponent]
				,ISNULL(AII.AccumulatedAssetImpairmentAmount_FinanceComponent + AII.ClearedAssetImpairmentAmount_FinanceComponent,0.00) [AssetImpairmentAmount_FinanceComponent] 
			FROM ##Asset_EligibleAssets EA
			LEFT JOIN ##Asset_AssetImpairmentInfo AII ON AII.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
