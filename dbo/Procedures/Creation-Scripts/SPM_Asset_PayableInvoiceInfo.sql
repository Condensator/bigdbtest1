SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_PayableInvoiceInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	 pin.InvoiceNumber
	,p.PartyName [VendorName]
	,pia.AssetId
	,pia.Id [PayableInvoiceAssetId]
	,pia.AcquisitionCost_Amount
	,pia.OtherCost_Amount
	,pin.Id
	,pin.IsForeignCurrency
	,pin.InitialExchangeRate
	,pin.OriginalExchangeRate
	,ea.IsSKU
	,ea.AssetStatus
	,ea.IsLeaseComponent   INTO ##Asset_PayableInvoiceInfo
FROM
	PayableInvoices pin
INNER JOIN
	PayableInvoiceAssets pia ON pia.PayableInvoiceId = pin.Id
	AND pin.Status = 'Completed' AND pia.IsActive = 1
INNER JOIN
	##Asset_EligibleAssets ea ON pia.AssetId = ea.AssetId
INNER JOIN
	Parties p ON pin.VendorId = p.Id
LEFT JOIN
	LeaseFundings lfu ON lfu.FundingId = pin.Id
LEFT JOIN
	LeaseFinances lf ON lfu.LeaseFinanceId = lf.Id
WHERE
	(lfu.FundingId IS NULL OR (lfu.FundingId IS NOT NULL AND lf.IsCurrent = 1 AND lfu.IsActive = 1))


CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_PayableInvoiceInfo(AssetId);

END

GO
