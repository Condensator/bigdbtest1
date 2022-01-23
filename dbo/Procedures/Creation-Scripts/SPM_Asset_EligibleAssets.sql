SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_EligibleAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

SELECT
	 a.Id as [AssetId]
	,a.Status [AssetStatus]
	,at.Name [AssetType]
	,at.Id [AssetTypesId]
	,ac.Name [AssetCategory]
	,a.SubStatus
	,a.FinancialType
	,a.PreviousSequenceNumber
	,a.PlaceHolderAssetId
	,CASE WHEN at.IsSoft = 1 THEN 'Yes' ELSE 'No' END [IsSoft]
	,le.Name [LegalEntityName]
	,p.PartyName [CustomerName]
	,a.IsLeaseComponent
	,CAST (0 AS bit) [IsSKU]
	,v.PartyName [RemarketingVendorName]
	,CASE 
		WHEN at.Id IS NOT NULL AND act.Id IS NOT NULL THEN CAST (act.Usefullife AS nvarchar(10))
		WHEN at.Id IS NOT NULL AND act.Id IS NULL THEN CAST (at.EconomicLifeInMonths AS nvarchar(10))
		ELSE 'NA'
	END [TotalEconomicLife]
	,agl.HoldingStatus
	,agl.LineofBusinessId
	,a.ManufacturerId
	,a.AcquisitionDate
	,a.IsSystemCreated  INTO ##Asset_EligibleAssets
FROM 
	Assets a
INNER JOIN
	AssetGLDetails agl ON agl.Id = a.Id
	AND a.Status NOT IN ('Investor','Collateral','CollateralOnLoan')
INNER JOIN
	LegalEntities le ON a.LegalEntityId = le.Id
LEFT JOIN
	AssetTypes at ON a.TypeId = at.Id
LEFT JOIN
	AssetCatalogs act ON a.AssetCatalogId = act.Id
LEFT JOIN
	AssetCategories ac ON a.AssetCategoryId = ac.Id
LEFT JOIN
	Parties p ON a.CustomerId = p.Id
LEFT JOIN
	Parties v ON a.RemarketingVendorId = v.Id
LEFT JOIN
	##Asset_InvestorLeasedAssets il ON il.AssetId = a.Id
LEFT JOIN
	##Asset_CollateralLoanScrapedAssets cl ON cl.AssetId = a.Id
	AND il.AssetId IS NULL AND cl.AssetId IS NULL

CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_EligibleAssets(AssetId);

UPDATE ea
	SET ea.AssetStatus = 'Inventory'
FROM
	##Asset_EligibleAssets ea
LEFT JOIN
	(SELECT DISTINCT ea.AssetId
	FROM
		##Asset_EligibleAssets ea
	INNER JOIN
		LeaseAssets la ON ea.AssetId = la.AssetId
	INNER JOIN
		LeaseFinances lf ON lf.Id = la.LeaseFinanceId
	WHERE
		lf.IsCurrent = 1 AND la.IsActive = 1
		AND ea.AssetStatus = 'Leased' AND lf.BookingStatus IN ('Commenced','InsuranceFollowup')
	) t ON t.AssetId = ea.AssetId
WHERE 
	ea.AssetStatus = 'Leased' AND t.AssetId IS NULL
	AND ea.IsSystemCreated = 0;

IF @IsSku = 1
BEGIN
UPDATE ea
	SET ea.IsSKU = 1
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	Assets a ON ea.AssetId = a.Id AND a.IsSKU = 1
END;

END

GO
