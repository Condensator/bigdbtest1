SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_RenewalAmortizeInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @AddCharge BIT = 0;
DECLARE @IsSku BIT = 0;
DECLARE @Sql nvarchar(max) ='';

CREATE TABLE ##Asset_RenewalAmortizeInfo
(AssetId                                BIGINT NOT NULL,
RenewalAmortizedAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
RenewalAmortizedAmount_FinanceComponent DECIMAL (16, 2) NOT NULL
)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
SET @AddCharge = 1;
END;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.RenewalAmortizedAmount_LeaseComponent) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(t.RenewalAmortizedAmount_FinanceComponent) [RenewalAmortizedAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN la.NBV_Amount ELSE 0.00 END [RenewalAmortizedAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN la.NBV_Amount ELSE 0.00 END [RenewalAmortizedAmount_FinanceComponent]
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
WHERE
	ea.IsSKU = 0 
	AND ((lfd.LeaseContractType != ''Operating'' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0) OR la.IsLeaseAsset = 0)
UNION
SELECT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN (la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount 
	- la.CapitalizedInterimInterest_Amount - la.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END [RenewalAmortizedAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 
	THEN (la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount 
	- la.CapitalizedInterimInterest_Amount - la.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END [RenewalAmortizedAmount_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
WHERE
	ea.IsSKU = 0 AND la.IsActive = 1
	AND ((lfd.LeaseContractType != ''Operating'' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0) OR la.IsLeaseAsset = 0)) AS t GROUP BY t.AssetId'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','- la.CapitalizedAdditionalCharge_Amount');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO ##Asset_RenewalAmortizeInfo
EXEC (@Sql)
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.RenewalAmortizedAmount_LeaseComponent) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(t.RenewalAmortizedAmount_FinanceComponent) [RenewalAmortizedAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,SUM(CASE WHEN lfd.LeaseContractType != ''Operating'' AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 THEN las.NBV_Amount ELSE 0.00 END) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1 THEN las.NBV_Amount ELSE 0.00 END)  [RenewalAmortizedAmount_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
WHERE
	ea.IsSKU = 1
GROUP BY
	ea.AssetId
UNION
SELECT
	ea.AssetId
	,SUM(CASE WHEN lfd.LeaseContractType != ''Operating'' AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN (las.NBV_Amount - las.CapitalizedSalesTax_Amount - las.CapitalizedInterimRent_Amount 
	- las.CapitalizedInterimInterest_Amount	- las.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1 
	THEN (las.NBV_Amount - las.CapitalizedSalesTax_Amount - las.CapitalizedInterimRent_Amount 
	- las.CapitalizedInterimInterest_Amount - las.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END) [RenewalAmortizedAmount_FinanceComponent]
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
WHERE 
	ea.IsSKU = 1 AND la.IsActive = 1
GROUP BY
	ea.AssetId) AS t GROUP BY t.AssetId'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','- las.CapitalizedAdditionalCharge_Amount');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO ##Asset_RenewalAmortizeInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_RenewalAmortizeInfo_AssetId ON ##Asset_RenewalAmortizeInfo(AssetId);

END

GO
