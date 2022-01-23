SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAssetsWithPendingPayablesForPayoff]
(
	@PayoffAssetIds AssetIdCollection READONLY,
	@PayableSourcePayableInvoiceOtherCost NVARCHAR(30),
	@PayableSourcePayableInvoiceAsset NVARCHAR(30),
	@PayableInvoiceStatusCompleted NVARCHAR(10),
	@PayableStatusPending NVARCHAR(20),
	@PayableStatusPartiallyApproved NVARCHAR(20)
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT * INTO #PayoffAssetIds
	FROM @PayoffAssetIds

	SELECT PayableInvoiceOtherCosts.AssetId
	FROM PayableInvoiceOtherCosts JOIN #PayoffAssetIds ON #PayoffAssetIds.AssetId = PayableInvoiceOtherCosts.AssetId
	JOIN Payables on PayableInvoiceOtherCosts.Id = Payables.SourceId AND Payables.SourceTable = @PayableSourcePayableInvoiceOtherCost
	JOIN PayableInvoices on PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id
	WHERE PayableInvoices.Status = @PayableInvoiceStatusCompleted
	AND Payables.Status IN (@PayableStatusPending, @PayableStatusPartiallyApproved)
	AND PayableInvoices.ParentPayableInvoiceId IS NULL
	AND PayableInvoiceOtherCosts.IsActive = 1
	AND Payables.Amount_Amount != 0
	
	UNION
		
	SELECT PayableInvoiceAssets.AssetId 
	FROM PayableInvoiceAssets JOIN #PayoffAssetIds ON #PayoffAssetIds.AssetId = PayableInvoiceAssets.AssetId
	JOIN Payables on Payables.SourceId = PayableInvoiceAssets.Id AND Payables.SourceTable = @PayableSourcePayableInvoiceAsset
	JOIN PayableInvoices on PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
	WHERE PayableInvoices.Status = @PayableInvoiceStatusCompleted
	AND Payables.Status IN (@PayableStatusPending, @PayableStatusPartiallyApproved)
	AND PayableInvoices.ParentPayableInvoiceId IS NULL
	AND Payables.Amount_Amount != 0

END

GO
