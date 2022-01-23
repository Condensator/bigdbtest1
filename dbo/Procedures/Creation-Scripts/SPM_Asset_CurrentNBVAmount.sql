SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_CurrentNBVAmount]
AS
BEGIN
	UPDATE TGT
		SET TGT.CurrentNBVAmountLeaseComponent = SRC.CurrentNBVAmount_LeaseComponent,
			TGT.CurrentNBVAmountFinanceComponent = SRC.CurrentNBVAmount_FinanceComponent
	FROM ##AssetMeasures TGT
		INNER JOIN 
		(SELECT 
			EA.AssetId
			,ISNULL(CNI.CurrentNBVAmount_LeaseComponent,0.00) [CurrentNBVAmount_LeaseComponent]
			,ISNULL(CNI.CurrentNBVAmount_FinanceComponent,0.00) [CurrentNBVAmount_FinanceComponent]
		FROM
			##Asset_EligibleAssets EA
		LEFT JOIN
			##Asset_CurrentNBVInfo CNI ON CNI.AssetId = EA.AssetId
		) SRC
		ON TGT.ID = SRC.AssetId
END

GO
