SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_ResidualImpairmentAmount]
AS
BEGIN
	UPDATE TGT
		SET TGT.ResidualImpairmentAmountLeaseComponent = SRC.ResidualImpairmentAmount_LeaseComponent,
			TGT.ResidualImpairmentAmountFinanceComponent = SRC.ResidualImpairmentAmount_FinanceComponent
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(SELECT 
			EA.AssetId
			,- ISNULL(LAII.ResidualImpairmentAmount_LeaseComponent,0.00) [ResidualImpairmentAmount_LeaseComponent]
			,- ISNULL(LAII.ResidualImpairmentAmount_FinanceComponent,0.00) [ResidualImpairmentAmount_FinanceComponent]
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_LeaseAmendmentImpairmentInfo LAII ON LAII.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
