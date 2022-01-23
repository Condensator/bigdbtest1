SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[UpdateAssetStausAfterMerge]  
(
	 @UserId int
	,@CreatedTime Datetimeoffset
)
AS 
BEGIN
Update Assets
SET  Status  = CASE WHEN SyndicationType = 'FullSale' THEN 'InvestorLeased' ELSE 'Leased' END
	,IsOnCommencedLease = 1
	,UpdatedTime = @CreatedTime
	,UpdatedById = @UserId  
FROM
	Assets
	INNER JOIN LeaseAssets
		ON Assets.Id = LeaseAssets.AssetId 
		AND LeaseAssets.IsActive = 1
	INNER JOIN LeaseFinances
		ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
		AND LeaseFinances.IsCurrent = 1
	INNER JOIN Contracts
		ON LeaseFinances.ContractId = Contracts.Id 

Update Assets
SET  Status  = 'CollateralOnLoan'
	,UpdatedTime = @CreatedTime
	,UpdatedById = @UserId  
FROM
	Assets
	INNER JOIN CollateralAssets
		ON Assets.Id = CollateralAssets.AssetId 
		AND CollateralAssets.IsActive = 1
	INNER JOIN LoanFinances
		ON CollateralAssets.LoanFinanceId = LoanFinances.Id
		AND LoanFinances.IsCurrent = 1
	INNER JOIN Contracts
		ON LoanFinances.ContractId = Contracts.Id 
END

GO
