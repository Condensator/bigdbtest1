SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_CurrentNBVInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SELECT
	t.AssetId
	,SUM(CASE WHEN t.IsLeaseAsset = 1 AND t.IsFailedSaleLeaseback = 0 THEN EndNetBookValue_Amount ELSE 0.00 END) [CurrentNBVAmount_LeaseComponent]
	,SUM(CASE WHEN t.IsLeaseAsset = 0 OR t.IsFailedSaleLeaseback = 1 THEN EndNetBookValue_Amount ELSE 0.00 END) [CurrentNBVAmount_FinanceComponent]
		INTO ##Asset_CurrentNBVInfo
FROM
(SELECT
	 ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
	,ais.EndNetBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId,la.IsLeaseAsset,la.IsFailedSaleLeaseback ORDER BY lis.IncomeDate DESC) AS rn
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
	AND ea.IsSKU = 0 AND ea.AssetStatus IN ('Leased','InvestorLeased') 
INNER JOIN 
	LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
	AND lis.IsGLPosted = 1 AND lis.IsAccounting = 1 AND lis.AdjustmentEntry = 0
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN 
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id AND lf.IsCurrent = 1
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = lf.Id
	AND ((lfd.LeaseContractType != 'Operating' AND la.IsLeaseAsset = 1) OR la.IsLeaseAsset = 0)
INNER JOIN
	Contracts c ON lf.ContractId = c.Id
	AND c.SyndicationType != 'FullSale'
) AS t
WHERE t.rn = 1
GROUP BY t.AssetId
END;

IF @IsSku = 1
BEGIN
INSERT INTO ##Asset_CurrentNBVInfo
SELECT
	t.AssetId
	,SUM(t.LeaseEndNetBookValue_Amount) [CurrentNBVAmount_LeaseComponent]
	,SUM(t.FinanceEndNetBookValue_Amount) [CurrentNBVAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,ais.LeaseEndNetBookValue_Amount
	,ais.FinanceEndNetBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId ORDER BY lis.IncomeDate DESC) AS rn
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
	AND ea.IsSKU = 1 AND ea.AssetStatus IN ('Leased','InvestorLeased') 
INNER JOIN
	LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
	AND lis.IsGLPosted = 1 AND lis.IsAccounting = 1 AND lis.AdjustmentEntry = 0
) AS t
WHERE t.rn = 1
GROUP BY t.AssetId
END

CREATE NONCLUSTERED INDEX IX_CurrentNBVInfo_AssetId ON ##Asset_CurrentNBVInfo(AssetId);

END

GO
