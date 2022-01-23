SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetAssetsForEIPOutBoundInterface]
(
@ActiveStatus NVARCHAR(20)
,@NoneStatus NVARCHAR(20)
,@SoldStatus NVARCHAR(20)
,@InventoryStatus NVARCHAR(20)
,@LeasedStatus NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON;
WITH AssetHistory_CTE
AS
(
	SELECT
	AssetId
	,Reason
	,ActivityStatusDate
	,Status
	FROM
	(
		SELECT
		AssetId=AssetHistories.AssetId
		,Reason = CASE WHEN (Reason!='New') THEN  'U'
		WHEN (Reason ='New') THEN 'N'
		END
		,ActivityStatusDate=AssetHistories.AsOfDate
		,Status=CASE AssetValueHistories.SourceModule
		WHEN 'InventoryBookDepreciation' THEN @ActiveStatus
		WHEN 'FixedTermDepreciation' THEN @ActiveStatus
		WHEN 'OTPDepreciation' THEN @ActiveStatus
		ELSE @NoneStatus
		END
		,RANK=ROW_NUMBER() OVER(Partition By AssetHistories.AssetId Order By AssetHistories.Id desc)
		FROM AssetHistories
		LEFT JOIN AssetValueHistories ON AssetValueHistories.AssetId=AssetHistories.AssetId AND AssetValueHistories.IsLessorOwned = 1
	) AS TEMP1
	Where RANK=1
),
CTE_AssetsOriginalAcqisitionCost
AS
(
	SELECT
	AssetId
	,OriginalAcquisitionCost
	FROM
	(
		SELECT
		AssetId
		,OriginalAcquisitionCost=NetValue_Amount
		,LatestAssetEntry=ROW_NUMBER() OVER (PARTITION BY AssetValueHistories.AssetId ORDER BY AssetValueHistories.Id DESC)
		FROM AssetValueHistories
		INNER JOIN Assets ON Assets.Id=AssetValueHistories.AssetId AND AssetValueHistories.IsLessorOwned = 1
	) AS AssetWithLargestAcquistionCosts
	WHERE AssetWithLargestAcquistionCosts.LatestAssetEntry=1
),
CTE_AssetSerialNumberDetails AS
(
	SELECT 
		ASN.AssetId,
		SerialNumber = MAX(ASN.SerialNumber)
	FROM AssetSerialNumbers ASN 
	WHERE ASN.IsActive = 1
	GROUP BY ASN.AssetId
	HAVING Count(ASN.Id) = 1
),
CTE_ContractAssets AS
(
	SELECT
		Period=CONVERT(NVARCHAR(10),CONVERT(date,GETDATE()),101)
		,LeaseNumber=Contracts.SequenceNumber
		,AssetNumber=Assets.Id
		,AssetId=Assets.Id
		,AcquisitionDate=CONVERT(NVARCHAR(10),Assets.AcquisitionDate,101)
		,ClassCode=AssetClassCodes.ClassCode
		,OffLeaseFlag=CAST(
		CASE
		WHEN LeaseAssets.IsActive =1
		THEN '0'
		ELSE '1'
		END AS NVARCHAR
		)
		,AssetAddress1=Locations.AddressLine1
		,AssetCity=Locations.City
		,AssetState=States.ShortName
		,AssetZipCode=Locations.PostalCode
		,AssetDescription=replace(replace(Assets.Description,char(10),''),char(13),'')
		,OriginalAcquisitionCost=CTE_AssetsOriginalAcqisitionCost.OriginalAcquisitionCost
		,ResidualAmount=LeaseAssets.BookedResidual_Amount
		,DepreciationStatus=CASE WHEN Assets.Status IN ('Donated','Scrap','WriteOff','Sold') THEN @SoldStatus
		WHEN Assets.Status IN ('Investor','Inventory','Collateral') THEN @InventoryStatus
		WHEN Assets.Status IN ('CollateralonLoan','InvestorLeased','Leased') THEN @LeasedStatus
		END
		,AssetCountryCode=Countries.ShortName
		,ClassDescription=replace(replace(AssetClassCodes.Description,char(10),''),char(13),'')
	FROM
		Contracts
		INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
		AND LeaseFinances.IsCurrent=1 AND LeaseFinances.BookingStatus='Commenced'
		INNER JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId=LeaseFinances.Id
		AND LeaseAssets.IsActive=1
		INNER JOIN Assets ON Assets.Id=LeaseAssets.AssetId
		INNER JOIN AssetTypes ON Assets.TypeId=AssetTypes.Id
		AND AssetTypes.IsActive=1
		INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId
		AND AssetClassCodes.IsActive=1
		LEFT JOIN CTE_AssetsOriginalAcqisitionCost ON Assets.Id=CTE_AssetsOriginalAcqisitionCost.AssetId
		LEFT JOIN AssetLocations ON AssetLocations.AssetId=Assets.Id
		AND AssetLocations.IsActive=1
		AND AssetLocations.IsCurrent=1
		LEFT JOIN Locations ON Locations.Id=AssetLocations.LocationId
		AND Locations.IsActive=1
		AND Locations.ApprovalStatus='Approved'
		LEFT JOIN States ON States.Id=Locations.StateId
		AND States.IsActive=1
		LEFT JOIN Countries ON Countries.Id=States.CountryId
		AND Countries.IsActive=1
	UNION ALL
	SELECT
		Period=CONVERT(NVARCHAR(10),CONVERT(date,GETDATE()),101)
		,LeaseNumber=Contracts.SequenceNumber
		,AssetNumber=Assets.Id
		,AssetId=Assets.Id
		,AcquisitionDate=CONVERT(NVARCHAR(10),Assets.AcquisitionDate,101)
		,ClassCode=AssetClassCodes.ClassCode
		,OffLeaseFlag=CAST(
		CASE
		WHEN CollateralAssets.IsActive =1
		THEN '0'
		ELSE '1'
		END AS NVARCHAR
		)
		,AssetAddress1=Locations.AddressLine1
		,AssetCity=Locations.City
		,AssetState=States.ShortName
		,AssetZipCode=Locations.PostalCode
		,AssetDescription= replace(replace(Assets.Description,char(10),''),char(13),'')
		,OriginalAcquisitionCost=CTE_AssetsOriginalAcqisitionCost.OriginalAcquisitionCost
		,ResidualAmount=CollateralAssets.AcquisitionCost_Amount
		,DepreciationStatus=CASE WHEN Assets.Status IN ('Donated','Scrap','WriteOff','Sold') THEN @SoldStatus
		WHEN Assets.Status IN ('Investor','Inventory','Collateral') THEN @InventoryStatus
		WHEN Assets.Status IN ('CollateralonLoan','InvestorLeased','Leased') THEN @LeasedStatus
		END
		,AssetCountryCode=Countries.ShortName
		,ClassDescription=replace(replace(AssetClassCodes.Description,char(10),''),char(13),'')
	FROM
		Contracts
		INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
		AND LoanFinances.IsCurrent=1 AND LoanFinances.Status='Commenced'
		INNER JOIN CollateralAssets ON CollateralAssets.LoanFinanceId=LoanFinances.Id
		AND CollateralAssets.IsActive=1
		INNER JOIN Assets ON Assets.Id=CollateralAssets.AssetId
		INNER JOIN AssetTypes ON Assets.TypeId=AssetTypes.Id
		AND AssetTypes.IsActive=1
		INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId
		AND AssetClassCodes.IsActive=1
		LEFT JOIN CTE_AssetsOriginalAcqisitionCost ON Assets.Id=CTE_AssetsOriginalAcqisitionCost.AssetId
		LEFT JOIN AssetLocations ON AssetLocations.AssetId=Assets.Id
		AND AssetLocations.IsActive=1
		AND AssetLocations.IsCurrent=1
		LEFT JOIN Locations ON Locations.Id=AssetLocations.LocationId
		AND Locations.IsActive=1
		AND Locations.ApprovalStatus='Approved'
		LEFT JOIN States ON States.Id=Locations.StateId
		AND States.IsActive=1
		LEFT JOIN Countries ON Countries.Id=States.CountryId
		AND Countries.IsActive=1
)
SELECT
Period
,LeaseNumber
,AssetNumber
,AssetIdentification = CTE_AssetSerialNumberDetails.SerialNumber
,AcquisitionDate
,ClassCode
,NewOrUsedCode=AssetHistory_CTE.Reason
,OffLeaseFlag
,AssetAddress1
,AssetCity
,AssetState
,AssetZipCode
,AssetDescription
,OriginalAcquisitionCost
,ResidualAmount
,DepreciationStatus
,ActivityStatusDate=CONVERT(NVARCHAR(10),AssetHistory_CTE.ActivityStatusDate,101)
,AssetCountryCode
,ClassDescription
FROM
CTE_ContractAssets
INNER JOIN AssetHistory_CTE ON AssetHistory_CTE.AssetId=CTE_ContractAssets.AssetId
LEFT JOIN CTE_AssetSerialNumberDetails ON CTE_ContractAssets.AssetId = CTE_AssetSerialNumberDetails.AssetId
ORDER BY CTE_ContractAssets.LeaseNumber
END

GO
