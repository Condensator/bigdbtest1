SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_CostOfGoodsSold]
AS
BEGIN

	UPDATE TGT 
	SET CostOfGoodsSold = SRC.CostOfGoodsSold
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)   
	INNER JOIN (
			SELECT SUM (PayoffAssets.AssetValuation_Amount) AS CostOfGoodsSold, EC.ContractId ContractId
				FROM PayoffAssets WITH(NOLOCK)
				INNER JOIN Payoffs WITH(NOLOCK) ON PayoffAssets.PayoffId = Payoffs.Id 
				INNER JOIN LeaseAssets WITH(NOLOCK) ON PayoffAssets.LeaseAssetId = LeaseAssets.Id 
				INNER JOIN ##Contract_EligibleContracts EC WITH(NOLOCK) ON EC.LeaseFinanceID = Payoffs.LeaseFinanceId
				WHERE Payoffs.Status='Activated' AND LeaseAssets.IsLeaseAsset=1 AND PayoffAssets.Status IN ('Purchase','Repossessed')

			Group by EC.ContractId
		) SRC
		ON (TGT.Id = SRC.ContractId)  
END

GO
