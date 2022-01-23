SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AcquisitionCostInfo]
AS
BEGIN

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SELECT 
	pin.AssetId
	,CASE
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_LeaseComponent]
	,CASE
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_FinanceComponent]   INTO ##Asset_AcquisitionCostInfo
FROM 
	##Asset_PayableInvoiceInfo pin
INNER JOIN
	Payables p ON p.SourceId = pin.PayableInvoiceAssetId
	AND p.EntityId = pin.Id AND p.EntityType = 'PI'
WHERE
	p.SourceTable = 'PayableInvoiceAsset'
	AND p.IsGLPosted = 1 AND pin.IsSKU = 0 AND p.Status != 'Inactive'
	AND pin.AssetStatus NOT IN ('Leased','InvestorLeased')
END;

BEGIN
INSERT INTO ##Asset_AcquisitionCostInfo
SELECT 
	pin.AssetId
	,CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_LeaseComponent]
	,CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_FinanceComponent]
FROM 
	##Asset_PayableInvoiceInfo pin
INNER JOIN
	Payables p ON p.SourceId = pin.PayableInvoiceAssetId
	AND p.EntityId = pin.Id AND p.EntityType = 'PI'
INNER JOIN
	LeaseAssets la ON pin.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE
	p.SourceTable = 'PayableInvoiceAsset' AND lf.IsCurrent = 1 
	AND la.IsActive = 1 AND pin.IsSKU = 0 AND p.IsGLPosted = 1 AND p.Status != 'Inactive'
	AND pin.AssetStatus IN ('Leased','InvestorLeased')
END;

IF @IsSku = 1
BEGIN
INSERT INTO ##Asset_AcquisitionCostInfo
SELECT 
	asku.AssetId
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount 
		ELSE 0.00 END) [AcquisitionCost_LeaseComponent]
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_FinanceComponent]
FROM 
	##Asset_PayableInvoiceInfo pin
INNER JOIN
	AssetSKUs asku ON pin.AssetId = asku.AssetId
INNER JOIN
	PayableInvoiceAssetSKUs pias ON pias.AssetSKUId = asku.Id 
	AND pias.PayableInvoiceAssetId = pin.PayableInvoiceAssetId
INNER JOIN
	Payables p ON p.SourceId = pin.PayableInvoiceAssetId AND p.EntityId = pin.Id
WHERE
	p.SourceTable = 'PayableInvoiceAsset' AND p.EntityType = 'PI'
	AND p.IsGLPosted = 1 AND pias.IsActive = 1 AND pin.IsSKU = 1 AND p.Status != 'Inactive'
	AND pin.AssetStatus NOT IN ('Leased')
GROUP BY
	asku.AssetId
END;

IF @IsSKU = 1
BEGIN
INSERT INTO ##Asset_AcquisitionCostInfo
SELECT pin.AssetId
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_LeaseComponent]
	,SUM(CASE 
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_FinanceComponent]
FROM
	##Asset_PayableInvoiceInfo pin
INNER JOIN
	AssetSKUs asku ON pin.AssetId = asku.AssetId
INNER JOIN
	PayableInvoiceAssetSKUs pias ON pias.AssetSKUId = asku.Id 
	AND pias.PayableInvoiceAssetId = pin.PayableInvoiceAssetId
INNER JOIN
	Payables p ON p.SourceId = pin.PayableInvoiceAssetId AND p.EntityId = pin.Id
INNER JOIN
	LeaseAssetSKUs las ON las.AssetSKUId = asku.Id
INNER JOIN
	LeaseAssets la ON las.LeaseAssetId = la.Id
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE
	p.SourceTable = 'PayableInvoiceAsset' AND p.EntityType = 'PI'
	AND p.IsGLPosted = 1 AND p.Status != 'Inactive' AND lf.IsCurrent = 1 AND la.IsActive = 1 AND pias.IsActive = 1
	AND pin.IsSKU = 1 AND pin.AssetStatus IN ('Leased') AND las.IsActive = 1
GROUP BY
	pin.AssetId
END;

CREATE NONCLUSTERED INDEX IX_AcquisitionCostInfo_AssetId ON ##Asset_AcquisitionCostInfo(AssetId);

END

GO
