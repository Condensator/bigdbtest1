SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_SyndicationAmountInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 ea.AssetId
	,SUM(CASE 
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -((((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS [SyndicationValueAmount_LeaseComponent]
	,SUM(CASE 
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -((((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS [SyndicationValueAmount_FinanceComponent]
	,SUM(CASE 
		WHEN la.IsActive = 0 AND la.TerminationDate >= rft.EffectiveDate AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN la.IsActive = 0 AND la.TerminationDate >= rft.EffectiveDate AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS SyndicationBeforePayoff    INTO ##Asset_SyndicationAmountInfo
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN
	##Asset_ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
LEFT JOIN
	ChargeOffs co ON lf.ContractId = co.ContractId
LEFT JOIN
	ChargeOffAssetDetails coa ON coa.ChargeOffId = co.Id AND coa.AssetId = ea.AssetId
LEFT JOIN
	##Asset_BlendedItemInfo bi ON bi.AssetId = la.AssetId
WHERE
	lfd.LeaseContractType != 'Operating'
	AND lf.IsCurrent = 1 AND ea.IsSKU = 0
	AND (la.TerminationDate IS NULL OR (la.TerminationDate IS NOT NULL AND la.TerminationDate >= rft.EffectiveDate))
GROUP BY
	ea.AssetId;

CREATE NONCLUSTERED INDEX IX_SyndicationAmountInfo_AssetId ON ##Asset_SyndicationAmountInfo(AssetId);

END

GO
