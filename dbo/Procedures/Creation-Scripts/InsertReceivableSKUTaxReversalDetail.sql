SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[InsertReceivableSKUTaxReversalDetail]
(
	@ReceivableSKUTaxReversalDetails ReceivableSKUTaxReversalDetailDatas Readonly,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;

INSERT INTO ReceivableSKUTaxReversalDetails([Amount_Amount],[Amount_Currency],[AmountBilledToDate_Amount],[AmountBilledToDate_Currency],[AssetSKUId],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[FairMarketValue_Amount],[FairMarketValue_Currency],[IsActive],[IsExemptAtAssetSKU],[ReceivableSKUId],[ReceivableTaxDetailId],[Revenue_Amount],[Revenue_Currency])
SELECT Amount,Currency,AmountBilledToDate,Currency,AssetSKUId,Cost,Currency,@CreatedById, @CreatedTime,FairMarketValue,Currency, 1,
	   IsExemptAtAssetSKU,ReceivableSKUId, ReceivableTaxDetailId, Revenue, RevenueCurrency
FROM @ReceivableSKUTaxReversalDetails

GO
