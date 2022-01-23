SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AcquisitionCost]
AS
BEGIN
	UPDATE TGT
		SET TGT.AcquisitionCostLeaseComponent = SRC.AcquisitionCost_LeaseComponent,
			TGT.AcquisitionCostFinanceComponent = SRC.AcquisitionCost_FinanceComponent	    
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(
			SELECT 
				EA.AssetId
				,ISNULL(ACI.AcquisitionCost_LeaseComponent,0.00) [AcquisitionCost_LeaseComponent]
				,ISNULL(ACI.AcquisitionCost_FinanceComponent,0.00) [AcquisitionCost_FinanceComponent]
			FROM ##Asset_EligibleAssets EA
			LEFT JOIN ##Asset_AcquisitionCostInfo ACI ON ACI.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
