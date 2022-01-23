SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AccumulatedNBVImpairmentAmount]
AS
BEGIN
	UPDATE TGT
	SET TGT.AccumulatedNBVImpairmentAmountLeaseComponent = SRC.AccumulatedNBVImpairmentAmount_LeaseComponent,
	    TGT.AccumulatedNBVImpairmentAmountFinanceComponent = SRC.AccumulatedNBVImpairmentAmount_FinanceComponent,
	    TGT.AccumulatedFixedTermDepreciationAmountLeaseComponent = SRC.AccumulatedFixedTermDepreciationAmount_LeaseComponent,
	    TGT.AccumulatedOTPDepreciationAmountLeaseComponent = SRC.AccumulatedOTPDepreciationAmount_LeaseComponent,
	    TGT.AccumulatedOTPDepreciationAmountFinanceComponent = SRC.AccumulatedOTPDepreciationAmount_FinanceComponent
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(
			SELECT 
					ea.AssetId
				,- ISNULL(aavh.AccumulatedNBVImpairmentAmount_LeaseComponent,0.00) [AccumulatedNBVImpairmentAmount_LeaseComponent]
				,- ISNULL(aavh.AccumulatedNBVImpairmentAmount_FinanceComponent,0.00) [AccumulatedNBVImpairmentAmount_FinanceComponent]
				,- ISNULL(aavh.AccumulatedFixedTermDepreciationAmount_LeaseComponent,0.00) [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
				,- ISNULL(aavh.AccumulatedOTPDepreciationAmount_LeaseComponent,0.00) [AccumulatedOTPDepreciationAmount_LeaseComponent]
				,- ISNULL(aavh.AccumulatedOTPDepreciationAmount_FinanceComponent,0.00) [AccumulatedOTPDepreciationAmount_FinanceComponent]
			FROM 
				##Asset_EligibleAssets ea
			LEFT JOIN 
				##Asset_AccumulatedAVHInfo aavh ON aavh.AssetId = ea.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
