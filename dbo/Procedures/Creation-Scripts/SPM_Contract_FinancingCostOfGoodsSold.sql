SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_FinancingCostOfGoodsSold]
AS
BEGIN

	UPDATE TGT 
	SET FinancingCostOfGoodsSold = SRC.FinancingCostOfGoodsSold
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			Select EC.ContractId, Sum (PayoffAssets.AssetValuation_Amount) FinancingCostOfGoodsSold 
			FROM PayoffAssets WITH(NOLOCK)
				INNER JOIN Payoffs WITH(NOLOCK) ON PayoffAssets.PayoffId = Payoffs.Id 
				INNER JOIN LeaseAssets WITH(NOLOCK) ON PayoffAssets.LeaseAssetId = LeaseAssets.Id 
				INNER JOIN LeaseFinances WITH(NOLOCK) ON LeaseFinances.Id = Payoffs.LeaseFinanceId
				INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = LeaseFinances.ContractId
			where Payoffs.Status='Activated' And LeaseAssets.IsLeaseAsset=0 AND 
				PayoffAssets.Status in ('Purchase','Repossessed')
			Group by EC.ContractId
		) SRC
		ON (TGT.Id = SRC.ContractId)  
END

GO
